# Performs natural language processing (NLP) on text data to extract emotions, symptoms and sentiment 
# (used for notes and journal entries)
from textblob import TextBlob
import re
import nltk
import os
import torch
from transformers import AutoTokenizer, AutoModelForSequenceClassification
import numpy as np
from collections import defaultdict
import time

class NLPAnalyzer:
    def __init__(self):
        # Initialize all required components
        self._init_nltk()
        self._init_emotion_model()
        self._init_dictionaries()
    
    def _init_nltk(self):
        # Download and ensure NLTK resources are available
        try:
            required_data = ['punkt', 'wordnet', 'averaged_perceptron_tagger', 'brown']
            for item in required_data:
                try:
                    nltk.data.find(f'corpora/{item}')
                except LookupError:
                    print(f"Downloading {item}...")
                    nltk.download(item)
        except Exception as e:
            print(f"Warning: Could not automatically download NLTK data: {str(e)}")
    
    def _init_emotion_model(self):
        # Load and initialize the emotion detection model
        try:
            model_name = "j-hartmann/emotion-english-distilroberta-base"
            
            print(f"Loading emotion detection model: {model_name}")
            start_time = time.time()
            
            # Load model components
            self.emotion_tokenizer = AutoTokenizer.from_pretrained(model_name)
            self.emotion_model = AutoModelForSequenceClassification.from_pretrained(model_name)
            
            # Setup device (GPU if available)
            self.device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
            self.emotion_model.to(self.device)
            self.emotion_model.eval()  # Set to evaluation mode
            
            # Get label mappings
            self.emotion_labels = self.emotion_model.config.id2label
            
            print(f"Model loaded in {time.time() - start_time:.2f} seconds. Running on: {self.device}")
            self.use_ml_emotion = True
        except Exception as e:
            print(f"Error loading emotion model: {str(e)}")
            print("Falling back to keyword-based emotion detection")
            self.use_ml_emotion = False
    
    def _init_dictionaries(self):
        # Initialize emotion and symptom category dictionaries
        
        # Emotion categories with keywords
        self.emotion_categories = {
            'joy': ['happy', 'excited', 'delighted', 'pleased', 'cheerful', 'glad', 'thrilled', 'content', 'satisfied', 'elated', 'ecstatic'],
            'sadness': ['sad', 'unhappy', 'depressed', 'miserable', 'down', 'gloomy', 'disappointed', 'upset', 'tearful', 'heartbroken', 'hopeless'],
            'anger': ['angry', 'mad', 'furious', 'irritated', 'annoyed', 'outraged', 'frustrated', 'enraged', 'indignant', 'resentful', 'hostile'],
            'fear': ['afraid', 'scared', 'frightened', 'terrified', 'anxious', 'worried', 'nervous', 'alarmed', 'panicked', 'tense', 'uneasy'],
            'love': ['loving', 'affectionate', 'caring', 'adoring', 'fond', 'passionate', 'tender', 'romantic', 'attached', 'devoted'],
            'surprise': ['surprised', 'shocked', 'astonished', 'amazed', 'startled', 'stunned', 'bewildered', 'dumbfounded', 'speechless','wow'],
            'optimism': ['optimistic', 'hopeful', 'confident', 'positive', 'motivated', 'inspired', 'determined', 'eager', 'enthusiastic', 'ambitious'],
            'exhaustion': ['exhausted', 'tired', 'fatigued', 'drained', 'weary', 'sleepy', 'lethargic', 'spent', 'worn out', 'burned out','lazy']
        }
        
        # Symptom categories with keywords
        self.symptom_categories = {
            'pain': ['cramp', 'ache', 'pain', 'sore', 'tender', 'sharp', 'stabbing', 'throbbing', 'burning', 'stinging'],
            'physical': ['bloat', 'fatigue', 'tired', 'nausea', 'headache', 'breast', 'acne', 'swelling', 'dizziness', 'weakness'],
            'digestive': ['bloating', 'nausea', 'appetite', 'craving', 'stomach', 'indigestion', 'constipation', 'diarrhea', 'gas'],
            'sleep': ['insomnia', 'restless', 'exhausted', 'sleepy', 'tired', 'drowsy', 'oversleeping', 'undersleeping', 'nightmares']
        }
        
        # Negation words for context-aware analysis
        self.negation_words = [
            'no', 'not', "don't", 'dont', 'doesn\'t', 'doesnt', 'didn\'t', 
            'didnt', 'wasn\'t', 'wasnt', 'aren\'t', 'arent', 'haven\'t', 'havent'
        ]
    
    def analyze_text(self, text):
        # Main method to analyze input text and extract insights
        
        # Handle empty or very short input
        if not text or len(text.strip()) < 3:
            return self._get_empty_result()
            
        try:
            # Basic text analysis with TextBlob
            blob = TextBlob(text.lower())
            sentiment_polarity = blob.sentiment.polarity
            sentiment = self._classify_sentiment(sentiment_polarity)
            
            # Get emotions using the ML model if available
            emotions_detected = self._detect_emotions_ml(text) if self.use_ml_emotion else {}
            
            # Find symptoms in the text
            found_symptoms = self._identify_symptoms(text.lower())
            
            # Add emotions to symptoms dictionary
            found_symptoms = self._add_emotions_to_symptoms(emotions_detected, found_symptoms)
            
            # Calculate emotional intensity
            emotional_intensity = self._calculate_intensity(text, sentiment_polarity, emotions_detected)
            
            # Extract important nouns and adjectives
            key_terms = self._extract_key_terms(blob)
            
            # Get additional emotions using keyword matching
            additional_emotions = self._identify_emotion_keywords(text.lower())
            
            # Add keyword-based emotions to symptoms
            if additional_emotions:
                if 'emotional' not in found_symptoms:
                    found_symptoms['emotional'] = []
                    
                for emotion in additional_emotions:
                    if emotion not in found_symptoms['emotional']:
                        found_symptoms['emotional'].append(emotion)
            
            # Clean up emotion list to remove duplicates
            if 'emotional' in found_symptoms:
                found_symptoms['emotional'] = list(set(found_symptoms['emotional']))
            
            # Return complete analysis
            return {
                'sentiment': sentiment,
                'sentiment_score': sentiment_polarity,
                'identified_symptoms': found_symptoms,
                'detected_emotions': emotions_detected,
                'emotional_intensity': emotional_intensity,
                'key_terms': list(set(key_terms))
            }
        except Exception as e:
            # Graceful fallback if analysis fails
            print(f"Error in text analysis: {str(e)}")
            return self._fallback_analysis(text, e)
    
    def _get_empty_result(self):
        # Return default values for empty text
        return {
            "sentiment": "NEUTRAL",
            "sentiment_score": 0.0,
            "identified_symptoms": {},
            "emotional_intensity": 0.0,
            "key_terms": []
        }
    
    def _classify_sentiment(self, polarity):
        # Convert sentiment score to category
        if polarity > 0:
            return 'POSITIVE'
        elif polarity < 0:
            return 'NEGATIVE'
        else:
            return 'NEUTRAL'
    
    def _detect_emotions_ml(self, text):
        # Use transformer model to detect emotions in text
        if not self.use_ml_emotion:
            return {}
            
        try:
            # Truncate text to avoid exceeding token limits
            truncated_text = ' '.join(text.split()[:100])
            
            # Run text through model without gradient calculation
            with torch.no_grad():
                # Tokenize and prepare inputs
                inputs = self.emotion_tokenizer(truncated_text, return_tensors="pt", truncation=True, padding=True)
                inputs = {k: v.to(self.device) for k, v in inputs.items()}
                
                # Get model predictions
                outputs = self.emotion_model(**inputs)
                scores = torch.nn.functional.softmax(outputs.logits, dim=1).squeeze().cpu().numpy()
                
                # Map scores to emotion labels
                emotion_dict = {}
                for i, score in enumerate(scores):
                    emotion = self.emotion_labels[i]
                    emotion_dict[emotion] = float(score)
                
                return emotion_dict
        except Exception as e:
            print(f"Error in ML emotion detection: {str(e)}")
            return {}
    
    def _identify_symptoms(self, text):
        # Find symptoms mentioned in text with context awareness
        found_symptoms = {}
        words = text.split()
        
        for category, keywords in self.symptom_categories.items():
            category_symptoms = []
            
            for keyword in keywords:
                # Check if keyword exists in text
                if keyword in text:
                    # Check for negation (e.g., "no pain")
                    is_negated = False
                    
                    for i, word in enumerate(words):
                        if keyword in word:
                            # Check previous 3 words for negation
                            for j in range(max(0, i-3), i):
                                if j < len(words) and words[j] in self.negation_words:
                                    is_negated = True
                                    break
                    
                    # Add symptom if not negated
                    if not is_negated:
                        category_symptoms.append(keyword)
            
            # Add symptom category if symptoms found
            if category_symptoms:
                found_symptoms[category] = category_symptoms
                
        return found_symptoms
    
    def _add_emotions_to_symptoms(self, emotions, symptoms):
        # Add detected emotions to the symptoms dictionary
        if not emotions:
            return symptoms
            
        # Initialize emotions category if needed
        if 'emotional' not in symptoms:
            symptoms['emotional'] = []
            
        # Add emotions that exceed confidence threshold
        for emotion, score in emotions.items():
            if score > 0.15:  # Confidence threshold
                symptoms['emotional'].append(emotion)
        
        return symptoms
    
    def _identify_emotion_keywords(self, text):
        # Find emotions using keyword matching
        found_emotions = []
        words = text.split()
        
        for emotion, keywords in self.emotion_categories.items():
            for keyword in keywords:
                if keyword in text:
                    # Check for negation (e.g., "not happy")
                    is_negated = False
                    
                    for i, word in enumerate(words):
                        if keyword in word:
                            # Check previous 3 words for negation
                            for j in range(max(0, i-3), i):
                                if j < len(words) and words[j] in self.negation_words:
                                    is_negated = True
                                    break
                    
                    # Add emotion if not negated
                    if not is_negated and emotion not in found_emotions:
                        found_emotions.append(emotion)
                        break  # One match per emotion is enough
        
        return found_emotions
    
    def _extract_key_terms(self, blob):
        # Extract important nouns and adjectives from text
        return [word for (word, tag) in blob.tags 
                if tag.startswith(('JJ', 'NN')) and len(word) > 2]
    
    def _calculate_intensity(self, text, sentiment_score, emotions):
        # Calculate emotional intensity from multiple signals
        base_intensity = self._calculate_emotional_intensity(text, sentiment_score)
        ml_intensity = max(emotions.values()) if emotions else 0
        
        # Return the higher of the two intensity measures
        return max(base_intensity, ml_intensity)
    
    def _calculate_emotional_intensity(self, text, sentiment_score):
        # Calculate emotional intensity based on text features
        
        # Count exclamation marks
        exclamation_count = text.count('!')
        
        # Count emotional intensifiers
        intensifiers = ['very', 'really', 'extremely', 'so', 'too', 'quite', 
                       'absolutely', 'incredibly', 'totally', 'completely']
        intensifier_count = sum(1 for word in text.lower().split() if word in intensifiers)
        
        # Count ALL CAPS words (indicates shouting/strong emotion)
        words = text.split()
        caps_count = sum(1 for word in words if word.isupper() and len(word) > 2)
        
        # Calculate composite intensity score
        intensity = (abs(sentiment_score) + 
                    (exclamation_count * 0.15) + 
                    (intensifier_count * 0.2) + 
                    (caps_count * 0.25))
        
        # Cap at 1.0 for normalization
        return min(1.0, intensity)
    
    def _fallback_analysis(self, text, error):
        # Provide basic analysis when main analysis fails
        fallback_emotions = self._identify_emotion_keywords(text.lower())
        fallback_symptoms = self._identify_symptoms(text.lower())
        
        # Add emotions to symptoms dictionary
        if fallback_emotions:
            if 'emotional' not in fallback_symptoms:
                fallback_symptoms['emotional'] = []
            fallback_symptoms['emotional'].extend(fallback_emotions)
        
        # Return simplified analysis with error information
        return {
            "error": str(error),
            "sentiment": "UNKNOWN",
            "sentiment_score": 0.0,
            "identified_symptoms": fallback_symptoms,
            "key_terms": []
        }
        
    def get_symptom_summary(self, symptoms_dict):
        # Generate summary of symptoms
        summary = []
        for category, symptoms in symptoms_dict.items():
            if symptoms:
                summary.append(f"{category.title()}: {', '.join(symptoms)}")
        return summary