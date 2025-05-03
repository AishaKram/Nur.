from flask import Blueprint, jsonify, request
from datetime import datetime
from app import mongo
from app.ml.mood_predictor import MoodPredictor
from app.ml.nlp_analyzer import NLPAnalyzer
from bson import ObjectId
import os
## Defines API endpoints for nlp_analyser and mood_predictor
ml_routes = Blueprint('ml_routes', __name__)
mood_predictor = MoodPredictor()
nlp_analyzer = NLPAnalyzer()

@ml_routes.route('/train_mood_model', methods=['POST'])
def train_mood_model():
# Train the mood prediction model using historical data 
    try:
        # Get all mood entries with their cycle information
        mood_entries = []
        all_moods = mongo.db.moods.find()
        
        for mood in all_moods:
            # Get cycle information for this mood entry
            # First try to find a completed cycle containing this mood entry
            cycle = mongo.db.cycles.find_one({
                "user_id": mood["user_id"],
                "start_date": {"$lte": mood["date"]},
                "end_date": {"$gt": mood["date"]}
            })
            
            # If no completed cycle contains this mood, check if it belongs to the current active cycle
            if not cycle:
                cycle = mongo.db.cycles.find_one({
                    "user_id": mood["user_id"],
                    "start_date": {"$lte": mood["date"]},
                    "end_date": None
                })
            
            if cycle:
                entry = {
                    'cycle_start': cycle['start_date'].strftime('%Y-%m-%d'),
                    'date': mood['date'].strftime('%Y-%m-%d'),
                    'mood': mood['mood'],
                    'energy_level': mood['energy_level'],
                    'cycle_phase': cycle['current_phase']
                }
                mood_entries.append(entry)
        
        if not mood_entries:
            return jsonify({"error": "No mood data available for training"}), 400
            
        # Train the model
        accuracy = mood_predictor.train(mood_entries)
        
        return jsonify({
            "message": "Model trained successfully",
            "accuracy": accuracy,
            "samples": len(mood_entries)
        }), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@ml_routes.route('/predict_mood/<user_id>', methods=['GET'])
def predict_mood(user_id):
# Predict user's mood based on current cycle day and phase
    try:
        # Get current cycle
        current_cycle = mongo.db.cycles.find_one(
            {"user_id": user_id, "end_date": None},
            sort=[("start_date", -1)]
        )
        
        if not current_cycle:
            print(f"No active cycle found for user {user_id}")
            return jsonify({
                "error": "No active cycle found",
                "predicted_mood": "No cycle data",
                "has_sufficient_data": False,
                "cycles_tracked": 0
            }), 200
            
        # Calculate current cycle day
        start_date = current_cycle['start_date']
        current_date = datetime.now()
        cycle_day = (current_date - start_date).days + 1
        
        # Get latest energy level
        latest_mood = mongo.db.moods.find_one(
            {"user_id": user_id},
            sort=[("date", -1)]
        )
        energy_level = latest_mood['energy_level'] if latest_mood else 5
        
        # Count how many cycles the user has
        cycle_count = mongo.db.cycles.count_documents({"user_id": user_id})
        
        # Check if model file exists
        model_path = os.path.join(os.path.dirname(__file__), 'mood_patterns.joblib')
        model_exists = os.path.exists(model_path)
        
        print(f"User {user_id} has {cycle_count} cycles, current phase: {current_cycle['current_phase']}")
        print(f"Model file exists: {model_exists}")
        
        # Make prediction
        prediction = mood_predictor.predict_mood(
            cycle_day,
            energy_level,
            current_cycle['current_phase']
        )
        
        # Add additional information (debugging)
        prediction["cycles_tracked"] = cycle_count
        prediction["current_phase"] = current_cycle['current_phase']
        prediction["current_cycle_day"] = cycle_day
        prediction["model_file_exists"] = model_exists
        
        print(f"Prediction for user {user_id}: {prediction}")
        return jsonify(prediction), 200
        
    except Exception as e:
        print(f"Error in predict_mood: {str(e)}")
        return jsonify({
            "error": str(e),
            "predicted_mood": "Error",
            "has_sufficient_data": False
        }), 500

@ml_routes.route('/analyze_notes', methods=['POST'])
def analyze_notes():
# Analyze mood and symptom descriptions using advanced NLP with ML
    try:
        data = request.get_json()
        if 'text' not in data or not data['text'] or len(data['text'].strip()) < 3:
            return jsonify({
                "sentiment": "NEUTRAL",
                "sentiment_score": 0.0,
                "identified_symptoms": {},
                "key_terms": []
            }), 200
            
        # For debugging
        print(f"Analyzing text: {data['text'][:50]}...")
        
        # Perform NLP analysis with the enhanced ML capabilities
        try:
            analysis = nlp_analyzer.analyze_text(data['text'])
            
            # Generate symptom summary if symptoms were found
            if analysis['identified_symptoms']:
                analysis['symptom_summary'] = nlp_analyzer.get_symptom_summary(
                    analysis['identified_symptoms']
                )
                
            # Format the emotion data for the frontend
            if 'emotional' in analysis['identified_symptoms']:
                # Capitalize emotion names 
                analysis['identified_symptoms']['emotional'] = [
                    emotion.replace('_', ' ').capitalize() 
                    for emotion in analysis['identified_symptoms']['emotional']
                ]
            
            # Remove raw emotion scores from the response to keep it clean
            if 'detected_emotions' in analysis:
                del analysis['detected_emotions']
                
            return jsonify(analysis), 200
            
        except Exception as e:
            print(f"ML analysis failed: {str(e)}, using simple fallback")
            
            # Simple fallback analysis for emotional keywords
            text = data['text'].lower()
            simple_emotions = {
                'joy': ['happy', 'joy', 'glad', 'excited', 'pleased', 'motivated', 'cheerful', 'productive'],
                'sadness': ['sad', 'unhappy', 'depressed', 'miserable', 'down', 'blue'],
                'anger': ['angry', 'mad', 'furious', 'irritated', 'annoyed', 'frustrated'],
                'fear': ['afraid', 'scared', 'anxious', 'worried', 'nervous', 'terrified'],
                'exhaustion': ['tired', 'exhausted', 'sleepy', 'fatigue', 'drained', 'weary', 'lazy', 'overwhelmed'],
            }
            
            # Build a more robust fallback
            found_emotions = []
            for emotion, keywords in simple_emotions.items():
                if any(keyword in text for keyword in keywords):
                    found_emotions.append(emotion.capitalize())
            
            sentiment = "POSITIVE" if any(e.lower() == 'joy' for e in found_emotions) else \
                       "NEGATIVE" if any(e.lower() in ['sadness', 'anger', 'fear'] for e in found_emotions) else \
                       "NEUTRAL"
            
            # Create fallback response
            fallback_response = {
                "sentiment": sentiment,
                "sentiment_score": 0.7 if sentiment == "POSITIVE" else -0.7 if sentiment == "NEGATIVE" else 0.0,
                "identified_symptoms": {"emotional": found_emotions} if found_emotions else {},
                "key_terms": []
            }
            
            if found_emotions:
                fallback_response['symptom_summary'] = [
                    f"Emotional: {', '.join(found_emotions)}"
                ]
            
            return jsonify(fallback_response), 200
        
    except Exception as e:
        print(f"Error in analyze_notes: {str(e)}")
        return jsonify({
            "error": str(e),
            "sentiment": "UNKNOWN"
        }), 500