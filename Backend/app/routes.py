# This file contains the routes for handling API functionality eg. user registration, login, etc. 
from flask import Blueprint, request, jsonify
from app import mongo
import firebase_admin
import firebase_admin.auth as auth
from firebase_admin import auth, credentials
from datetime import datetime, timedelta
from bson import ObjectId
import requests
from bson.errors import InvalidId
import smtplib

main = Blueprint('main', __name__)

@main.route('/')
def home():
    return "Its workingggg"

######### User routes ########## 

@main.route('/add_user', methods=['POST'])
# This route is used to add a new user to the database
def add_user():
    data = request.get_json()
    
    print(f"Received registration data: {data}")

    if not data or 'email' not in data or 'password' not in data:
        return jsonify({"error": "Missing 'email' or 'password'"}), 400

    email = data['email']
    password = data['password']
    name = data.get('name')
    dob = data.get('dob')  # Expected format: DD-MM-YYYY
    profession = data.get('profession')
    last_period = data.get('last_period')  # Expected format: YYYY-MM-DD

    print(f"Processing registration for: {email}")

    # Convert 'dob' from DD-MM-YYYY to ISODate (YYYY-MM-DD)
    try:
        dob_iso = datetime.strptime(dob, "%d-%m-%Y")
        print(f"DOB parsed successfully: {dob_iso}")
    except ValueError as e:
        print(f"DOB parsing error: {e}")
        return jsonify({"error": "'dob' format should be DD-MM-YYYY"}), 400

    # Convert 'last_period' from YYYY-MM-DD to ISODate
    try:
        last_period_iso = datetime.strptime(last_period, "%Y-%m-%d") if last_period else None
        print(f"Last period parsed successfully: {last_period_iso}")
    except ValueError as e:
        print(f"Last period parsing error: {e}")
        return jsonify({"error": "'last_period' format should be YYYY-MM-DD"}), 400

    try:
        # Check if user already exists in either Firebase or MongoDB 
        
        # Check if user exists in MongoDB
        existing_mongo_user = mongo.db.users.find_one({"email": email})
        if existing_mongo_user:
            print(f"User with email {email} already exists in MongoDB")
            return jsonify({"error": "Email already exists"}), 400
            
        # Check if user exists in Firebase
        try:
            firebase_user = auth.get_user_by_email(email)
            print(f"User with email {email} already exists in Firebase")
            return jsonify({"error": "Email already exists"}), 400
        except auth.UserNotFoundError:
            # User doesn't exist in Firebase, proceed with creation
            print(f"Email {email} is available in Firebase, proceeding with user creation")
            
        # Create the user in Firebase Auth
        user = auth.create_user(email=email, password=password)
        print(f"Firebase user created with UID: {user.uid}")

        # Create the user in MongoDB
        mongo_result = mongo.db.users.insert_one({
            "email": email,
            "name": name,
            "dob": dob_iso,
            "profession": profession,
            "last_period": last_period_iso,
            "firebase_uid": user.uid
        })
        print(f"MongoDB user created with ID: {mongo_result.inserted_id}")

        # Create initial cycle entry if last_period is provided
        if last_period_iso:
            cycle_result = mongo.db.cycles.insert_one({
                "user_id": user.uid,
                "start_date": last_period_iso,
                "end_date": None,
                "current_phase": "Menstrual"
            })
            print(f"Initial cycle created with ID: {cycle_result.inserted_id}")

        # Return a proper success message with status code 201
        return jsonify({
            "message": "Account created successfully! You can now log in with your email and password.",
            "user_id": user.uid
        }), 201

    except firebase_admin._auth_utils.EmailAlreadyExistsError as e:
        print(f"Firebase error: Email already exists - {str(e)}")
        return jsonify({"error": "Email already exists"}), 400
    except Exception as e:
        # If Firebase user was created but MongoDB failed, try to delete the Firebase user
        error_message = str(e)
        print(f"Error during user creation: {error_message}")
        
        # Return detailed error message
        return jsonify({"error": f"Error creating user: {error_message}"}), 400

@main.route('/login', methods=['POST'])
def login():
    try:
        # Get the login data (email and password)
        data = request.get_json()
        email = data.get('email')
        password = data.get('password')

        # Check if email and password are provided
        if not email or not password:
            return jsonify({'message': 'Email and password are required!'}), 400
        
        try:
            # Authenticate with Firebase using the REST API 
            # Import the Firebase API key from config
            from config.config import firebase_config
            api_key = firebase_config['apiKey']
            
            # Call Firebase Auth REST API to verify credentials
            firebase_auth_url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={api_key}"
            auth_data = {
                "email": email,
                "password": password,
                "returnSecureToken": True
            }
            
            response = requests.post(firebase_auth_url, json=auth_data)
            if response.status_code != 200:
                error_data = response.json()
                error_message = error_data.get('error', {}).get('message', 'Invalid email or password')
                print(f"Firebase authentication failed: {error_message}")
                return jsonify({'message': 'Invalid email or password'}), 401
       
            auth_result = response.json()
            firebase_uid = auth_result['localId']
            
            # Get user from Firebase to confirm UID
            user = auth.get_user(firebase_uid)
            
            # Get user data from MongoDB
            user_data = mongo.db.users.find_one({"email": email})
            
            if user and user_data:
                # Get cycle information using the dedicated function
                cycle_info = {}
                try:
                    # Call the internal function directly instead of making an HTTP request
                    current_cycle = mongo.db.cycles.find_one(
                        {"user_id": user.uid, "end_date": None},
                        sort=[("start_date", -1)]
                    )
                    
                    # Get accurate cycle information
                    if current_cycle:
                        # We'll use the dedicated function's logic to get cycle information
                        cycle_response = get_current_cycle_info_internal(user.uid)
                        cycle_info = {
                            'currentPhase': cycle_response.get('cycle_phase', 'Menstrual'),
                            'cycleDay': cycle_response.get('cycle_day', 1),
                            'daysLeft': cycle_response.get('days_until_next_period', 28)
                        }
                    else:
                        cycle_info = {
                            'currentPhase': 'Menstrual',
                            'cycleDay': 1,
                            'daysLeft': 28
                        }
                except Exception as e:
                    print(f"Error getting cycle info: {str(e)}")
                    cycle_info = {
                        'currentPhase': 'Menstrual',
                        'cycleDay': 1,
                        'daysLeft': 28
                    }
                
                return jsonify({
                    'message': 'Login successful!',
                    'user': {
                        'name': user_data.get('name', 'User'),
                        'email': user.email,
                        'userId': user.uid,
                        **cycle_info  # Include cycle information in the response
                    }
                }), 200
            else:
                return jsonify({'message': 'Invalid email or password'}), 401
                
        except auth.UserNotFoundError:
            # User doesn't exist, return invalid credentials message
            print(f"Login failed: User with email {email} not found")
            return jsonify({'message': 'Invalid email or password'}), 401
            
    except Exception as e:
        print(f"Unexpected error during login: {str(e)}")
        return jsonify({'message': 'Error authenticating user', 'error': str(e)}), 500

@main.route('/reset-password', methods=['POST'])
def reset_password():
    data = request.get_json()
    email = data.get("email")

    if not email:
        return jsonify({"error": "Email is required"}), 400

    try:
        # Check if email exists in our database
        user = mongo.db.users.find_one({"email": email})
        if not user:
            # Don't reveal if email exists or not for security reasons
            return jsonify({"message": "If your email exists in our system, a password reset link will be sent."}), 200

        # For development: Get the plain link to show in console
        print("Generating standard reset link...")
        plain_reset_link = auth.generate_password_reset_link(email)
        print("=====================================================")
        print(f"PASSWORD RESET LINK :\n{plain_reset_link}")
        print("=====================================================")
        
        # generate custom link
        try:
            print("Attempting to generate custom reset link...")
            
            action_code_settings = {
                "url": "http://127.0.0.1:5000",
                 # Changed to false to prevent Firebase from requiring a valid domain
                "handle_code_in_app": False,  
            }
            
            # Generate the custom password reset link for app integration (NOT USED)
            custom_reset_link = auth.generate_password_reset_link(email, action_code_settings)
            print("=====================================================")
            print(f"CUSTOM RESET LINK :\n{custom_reset_link}")
            print("=====================================================")
        except Exception as custom_error:
            print("Error generating custom reset link:")
            print(f"Error type: {type(custom_error).__name__}")
            print(f"Error message: {str(custom_error)}")
            print("This is expected in development without proper Firebase Dynamic Links setup.")
            print("You can use the standard link for testing or the test button in the app.")
        
        # Return success message to user
        return jsonify({"message": "Password reset instructions sent to your email address"}), 200
        
    except auth.UserNotFoundError:
        # Don't reveal if email exists or not (security best practice)
        return jsonify({"message": "If your email exists in our system, a password reset link will be sent."}), 200
    except Exception as e:
        print(f"Error in password reset: {str(e)}")
        return jsonify({"error": "An error occurred processing your request. Please try again."}), 500

@main.route('/confirm-password-reset', methods=['POST'])
def confirm_password_reset():
    #Process a password reset request using the Firebase oob code (out-of-band code
    try:
        data = request.get_json()
        oob_code = data.get("oob_code")
        new_password = data.get("new_password")
        
        if not oob_code or not new_password:
            return jsonify({"error": "Missing required parameters"}), 400
            
        # Validate the password reset code and update the password in Firebase
        try:
            # Check password strength
            if len(new_password) < 8:
                return jsonify({"error": "Password must be at least 8 characters long"}), 400
                
            # Verify the reset code and get email
            email = auth.verify_password_reset_code(oob_code)
            
            # Set the new password
            auth.confirm_password_reset(oob_code, new_password)
            
            # Return success message
            return jsonify({
                "success": True,
                "message": "Password has been reset successfully. You can now login with your new password."
            }), 200
            
        except auth.ExpiredIdTokenError:
            return jsonify({"error": "Password reset link has expired. Please request a new link."}), 400
        except auth.InvalidIdTokenError:
            return jsonify({"error": "Invalid password reset link. Please request a new link."}), 400
        except Exception as e:
            return jsonify({"error": f"Error validating reset code: {str(e)}"}), 400
            
    except Exception as e:
        return jsonify({"error": f"An unexpected error occurred: {str(e)}"}), 500

######### Cycle & Period routes ##########

@main.route('/get_cycles/<user_id>', methods=['GET'])
def get_cycles(user_id):
    """Get all cycles for a user, including length calculations"""
    try:
        # Get all cycles for this user by Firebase UID
        cycles = list(mongo.db.cycles.find({"user_id": user_id}))
        
        # Process cycles for frontend consumption
        for cycle in cycles:
            # Convert ObjectId to string for JSON 
            cycle["_id"] = str(cycle["_id"])
            
            # Convert datetime objects to ISO format strings
            if "start_date" in cycle and cycle["start_date"]:
                cycle["start_date"] = cycle["start_date"].isoformat()
            if "end_date" in cycle and cycle["end_date"]:
                cycle["end_date"] = cycle["end_date"].isoformat()
                
            # Calculate cycle length if not already done
            if "length" not in cycle and "start_date" in cycle and "end_date" in cycle:
                try:
                    start = datetime.fromisoformat(cycle["start_date"])
                    end = datetime.fromisoformat(cycle["end_date"])
                    cycle["length"] = (end - start).days + 1
                except Exception as e:
                    print(f"Error calculating cycle length: {e}")
                    # Default length
                    cycle["length"] = 28
            
        return jsonify({"cycles": cycles})
    except Exception as e:
        print(f"Error in get_cycles: {e}")
        return jsonify({"error": str(e), "cycles": []})

@main.route('/log_period', methods=['POST'])
def log_period():
    try:
        data = request.json
        if not data:
            return jsonify({"error": "No data provided"}), 400
            
        required_fields = ["user_id", "start_date", "flow_level"]
        for field in required_fields:
            if field not in data:
                return jsonify({"error": f"Missing required field: {field}"}), 400
        
        # Convert string date to datetime
        try:
            start_date = datetime.strptime(data["start_date"], "%Y-%m-%d")
        except ValueError:
            return jsonify({"error": "Invalid date format. Please use YYYY-MM-DD"}), 400

        # Check if this period start date is after the last logged period
        latest_period = mongo.db.period_logs.find_one(
            {"user_id": data["user_id"]},
            sort=[("start_date", -1)]
        )
        if latest_period and start_date < latest_period["start_date"]:
            return jsonify({"error": "New period start date must be after the last logged period."}), 400

        # Prevent multiple logs for the same day
        existing_log = mongo.db.period_logs.find_one({
            "user_id": data["user_id"],
            "start_date": start_date
        })
        if existing_log:
            return jsonify({"error": "You have already logged your period for this date."}), 400

        flow_level = data.get("flow_level")
        symptoms = data.get("symptoms", [])
        
        if flow_level == "":
            return jsonify({"error": "Flow level cannot be empty"}), 400
        if isinstance(symptoms, list) and "" in symptoms:
            return jsonify({"error": "Symptoms cannot be empty"}), 400
            
        # Automatically determine the current phase
        current_phase = "Menstrual"

        # Check if a cycle exists for this user
        existing_cycle = mongo.db.cycles.find_one({"user_id": data["user_id"], "end_date": None})

        # If no existing cycle, create a new one
        if not existing_cycle:
            cycle_entry = {
                "user_id": data["user_id"],
                "start_date": start_date,
                "end_date": None,
                "current_phase": current_phase
            }
            cycle_result = mongo.db.cycles.insert_one(cycle_entry)
            cycle_id = cycle_result.inserted_id
        else:
            cycle_id = existing_cycle["_id"]
            
            # Get previous period logs to analyze pattern and make an informed decision
            previous_logs = list(mongo.db.period_logs.find(
                {"user_id": data["user_id"], "cycle_id": existing_cycle["_id"]}
            ).sort("start_date", 1))
            
            days_since_cycle_start = (start_date - existing_cycle["start_date"]).days
            is_spotting = flow_level.lower() in ["spotting", "light"]
            days_since_last_log = 0
            
            if previous_logs:
                days_since_last_log = (start_date - previous_logs[-1]["start_date"]).days
            
            # ADAPTIVE CYCLE DETECTION (ERROR FIX):
            # Three key cases to determine if this is a new cycle or continuation:
            # 1. Gap detection - If there's a significant gap since last period log
            # 2. Pattern break - If flow increases after decreasing (e.g., spotting to heavy is likely new cycle)
            # 3. Phase transition - Based on historical data and phase lengths

            # Significant gap - if more than 3 days since last period log (unless it's first log of cycle)
            significant_gap = days_since_last_log > 3 and len(previous_logs) > 0
            
            # Pattern break - if flow increases after a decrease (suggesting new cycle)
            flow_increase_after_decrease = False
            if len(previous_logs) >= 2:
                flow_levels = ["spotting", "light", "medium", "heavy"]
                prev_flow_idx = flow_levels.index(previous_logs[-1]["flow_level"].lower()) if previous_logs[-1]["flow_level"].lower() in flow_levels else -1
                current_flow_idx = flow_levels.index(flow_level.lower()) if flow_level.lower() in flow_levels else -1
                
                # If flow decreased in previous logs but now increases again, likely new cycle
                if len(previous_logs) >= 3:
                    prev_prev_flow_idx = flow_levels.index(previous_logs[-2]["flow_level"].lower()) if previous_logs[-2]["flow_level"].lower() in flow_levels else -1
                    flow_increase_after_decrease = (prev_prev_flow_idx > prev_flow_idx and current_flow_idx > prev_flow_idx)
            
            # Phase transition - if we're well into a non-menstrual phase (14+ days) and heavy/medium flow starts
            in_non_menstrual_phase = days_since_cycle_start >= 14 and not is_spotting
            
            # Determine if this is a new cycle
            new_cycle_needed = significant_gap or flow_increase_after_decrease or in_non_menstrual_phase
            
            # Special case for logging spotting/light flow late in the cycle
            cycle_spotting = (flow_level.lower() in ["spotting", "light"]) and (days_since_cycle_start >= 10)
            
            if new_cycle_needed and not cycle_spotting:
                # Close the existing cycle
                mongo.db.cycles.update_one(
                    {"_id": existing_cycle["_id"]},
                    {"$set": {"end_date": start_date}}
                )
                
                # Create a new cycle
                new_cycle_entry = {
                    "user_id": data["user_id"],
                    "start_date": start_date,
                    "end_date": None,
                    "current_phase": "Menstrual"
                }
                new_cycle_result = mongo.db.cycles.insert_one(new_cycle_entry)
                cycle_id = new_cycle_result.inserted_id

        # Log the period entry
        period_log_entry = {
            "cycle_id": cycle_id,
            "user_id": data["user_id"],
            "start_date": start_date,
            "flow_level": flow_level,
            "symptoms": symptoms,
        }

        result = mongo.db.period_logs.insert_one(period_log_entry)

        # Get the updated cycle data to return to the frontend
        updated_cycle = mongo.db.cycles.find_one({"_id": cycle_id})
        
        # Make the ObjectId serializable
        if updated_cycle and "_id" in updated_cycle:
            updated_cycle["_id"] = str(updated_cycle["_id"])
        
        # Format dates for JSON serialization
        if updated_cycle and "start_date" in updated_cycle:
            updated_cycle["start_date"] = updated_cycle["start_date"].isoformat()
        
        if updated_cycle and "end_date" in updated_cycle and updated_cycle["end_date"]:
            updated_cycle["end_date"] = updated_cycle["end_date"].isoformat()

        # Get accurate cycle information using our helper function
        cycle_info = get_current_cycle_info_internal(data["user_id"])

        return jsonify({
            "message": "Period logged successfully",
            "period_log_id": str(result.inserted_id),
            "cycle": updated_cycle,
            "cycle_day": cycle_info["cycle_day"],
            "cycle_phase": cycle_info["cycle_phase"],
            "days_until_next_period": cycle_info["days_until_next_period"]
        }), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@main.route('/update_cycle', methods=['PUT'])
def update_cycle():
    data = request.get_json()

    if "cycle_id" not in data or "end_date" not in data or "user_id" not in data:
        return jsonify({"error": "Missing required fields: 'cycle_id', 'end_date', or 'user_id'"}), 400

    try:
        # Check if user exists using Firebase UID
        user = mongo.db.users.find_one({"firebase_uid": data["user_id"]})
        if not user:
            return jsonify({"error": "User not found"}), 404

        cycle_id = ObjectId(data["cycle_id"])  # We still use ObjectId for cycle_id
        end_date = datetime.strptime(data["end_date"], "%Y-%m-%d")

        # Check if cycle exists and belongs to user
        cycle = mongo.db.cycles.find_one({
            "_id": cycle_id,
            "user_id": data["user_id"]  # Verify cycle belongs to this user
        })
        if not cycle:
            return jsonify({"error": "Cycle not found or unauthorized"}), 404

        # Ensure the end_date is after the start_date
        start_date = cycle["start_date"]
        if end_date <= start_date:
            return jsonify({"error": "End date must be after the start date"}), 400

        # Update the cycle with the end_date
        mongo.db.cycles.update_one(
            {"_id": cycle_id},
            {"$set": {"end_date": end_date}}
        )

        return jsonify({"message": "Cycle updated successfully"}), 200

    except ValueError:
        return jsonify({"error": "Invalid date format, use YYYY-MM-DD"}), 400
    except InvalidId:
        return jsonify({"error": "Invalid cycle_id format"}), 400
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@main.route('/get_current_cycle_info/<user_id>', methods=['GET'])
def get_current_cycle_info(user_id):
    """Get detailed information about the user's current cycle, including accurate cycle day calculation."""
    try:
        # Check if user exists using Firebase UID
        user = mongo.db.users.find_one({"firebase_uid": user_id})
        if not user:
            return jsonify({"error": "User not found"}), 404

        # Use the internal helper function for more accurate cycle calculations
        cycle_info = get_current_cycle_info_internal(user_id)
        
        return jsonify({
            "cycle_day": cycle_info["cycle_day"],
            "cycle_phase": cycle_info["cycle_phase"],
            "days_until_next_period": cycle_info["days_until_next_period"],
            "cycle_id": cycle_info.get("cycle_id", "")
        }), 200
        
    except Exception as e:
        return jsonify({
            "error": str(e),
            "cycle_day": 1,
            "cycle_phase": "Menstrual",
            "days_until_next_period": 28
        }), 500

######### Mood & Analytics routes ##########

@main.route('/get_moods/<user_id>', methods=['GET'])
def get_moods(user_id):
    try:
        # Check if user exists using Firebase UID
        user = mongo.db.users.find_one({"firebase_uid": user_id})
        if not user:
            return jsonify({"error": "User not found"}), 404

        # Get mood entries for the user using Firebase UID
        moods = list(mongo.db.moods.find({"user_id": user_id}))
        
        # Convert ObjectId to string for JSON 
        for mood in moods:
            mood["_id"] = str(mood["_id"])
            mood["date"] = mood["date"].strftime("%Y-%m-%d") if isinstance(mood["date"], datetime) else mood["date"]

        return jsonify({"moods": moods}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@main.route('/log_mood', methods=['POST'])
def log_mood():
    data = request.get_json()
    required_fields = ["user_id", "mood", "energy_level"]
    
    if not all(field in data for field in required_fields):
        return jsonify({"error": "Missing required fields"}), 400

    try:
        # Check if user exists using Firebase UID
        user = mongo.db.users.find_one({"firebase_uid": data["user_id"]})
        if not user:
            return jsonify({"error": "User not found"}), 404

        # Get current cycle phase
        current_cycle = mongo.db.cycles.find_one(
            {"user_id": data["user_id"], "end_date": None},
            sort=[("start_date", -1)]
        )
        current_phase = current_cycle["current_phase"] if current_cycle else "Unknown"

        # Create mood entry
        mood_entry = {
            "user_id": data["user_id"],
            "date": datetime.now(),
            "mood": data["mood"],
            "energy_level": data["energy_level"],
            "notes": data.get("notes", ""),
            "cycle_phase": current_phase
        }

        result = mongo.db.moods.insert_one(mood_entry)
        
        # Automatically train the mood model after adding a new entry
        try:
            # Import to avoid circular imports
            from app.ml.routes import train_mood_model
            train_mood_model()
            print("Mood model automatically trained after new mood entry")
        except Exception as train_error:
            print(f"Error training mood model: {train_error}")
            
        return jsonify({
            "message": "Mood logged successfully",
            "mood_id": str(result.inserted_id)
        }), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@main.route('/get_suggestions/<phase>', methods=['GET'])
def get_suggestions_for_phase(phase):
    try:
        suggestions = list(mongo.db.suggestions.find({"phase": phase}))
        
        # Convert ObjectIds to strings for JSON serialization
        for suggestion in suggestions:
            suggestion["_id"] = str(suggestion["_id"])

        return jsonify({"suggestions": suggestions}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@main.route('/get_analytics/<user_id>', methods=['GET'])
def get_analytics(user_id):
    try:
        # Check if user exists using Firebase UID
        user = mongo.db.users.find_one({"firebase_uid": user_id})
        if not user:
            return jsonify({"error": "User not found"}), 404

        # Get all cycles for the user using Firebase UID
        cycles = list(mongo.db.cycles.find({"user_id": user_id}))
        
        # Calculate average cycle length
        cycle_lengths = []
        for i in range(len(cycles) - 1):
            start = cycles[i]["start_date"]
            end = cycles[i + 1]["start_date"]
            length = (end - start).days
            cycle_lengths.append(length)
        
        avg_cycle_length = sum(cycle_lengths) / len(cycle_lengths) if cycle_lengths else 28
        
        # Get mood patterns using Firebase UID
        moods = list(mongo.db.moods.find({"user_id": user_id}))
        mood_patterns = {}
        for mood in moods:
            phase = mood.get("cycle_phase", "Unknown")
            if phase not in mood_patterns:
                mood_patterns[phase] = []
            mood_patterns[phase].append({
                "mood": mood["mood"],
                "energy_level": mood["energy_level"]
            })

        return jsonify({
            "average_cycle_length": avg_cycle_length,
            "mood_patterns": mood_patterns,
            "total_cycles_recorded": len(cycles),
            "prediction_confidence": min(len(cycles) * 10, 100)  
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

######### Dietary Suggestions routes ##########

@main.route('/init_suggestions', methods=['POST'])
def init_suggestions():
    # Initialize the suggestions collection with phase-specific dietary and lifestyle recommendations.
    try:
        suggestions = [
            {
                "phase": "Menstrual",
                "diet": [
                    "Iron-rich foods: leafy greens, red meat, legumes",
                    "Complex carbohydrates: whole grains, sweet potatoes",
                    "Anti-inflammatory foods: berries, fatty fish",
                    "Warm, comforting foods"
                ],
                "lifestyle": [
                    "Gentle exercise like yoga or walking",
                    "Extra rest and self-care",
                    "Warm compress for cramps",
                    "Stay hydrated"
                ]
            },
            {
                "phase": "Follicular",
                "diet": [
                    "Light, fresh foods",
                    "Fermented foods: yogurt, kimchi",
                    "Antioxidant-rich foods: fruits, vegetables",
                    "Lean proteins"
                ],
                "lifestyle": [
                    "High-intensity workouts",
                    "Start new projects",
                    "Social activities",
                    "Creative pursuits"
                ]
            },
            {
                "phase": "Ovulation",
                "diet": [
                    "Raw foods and salads",
                    "Fiber-rich foods",
                    "Foods high in zinc: seeds, nuts",
                    "Light, energizing meals"
                ],
                "lifestyle": [
                    "Peak exercise performance",
                    "Important meetings/presentations",
                    "Social events",
                    "Dating and relationships"
                ]
            },
            {
                "phase": "Luteal",
                "diet": [
                    "Magnesium-rich foods: dark chocolate, nuts",
                    "Complex carbs to manage cravings",
                    "Calcium-rich foods",
                    "Foods high in B vitamins"
                ],
                "lifestyle": [
                    "Moderate exercise",
                    "Stress management",
                    "Journaling",
                    "Meal prep and organization"
                ]
            }
        ]

        # Insert suggestions into MongoDB
        result = mongo.db.suggestions.insert_many(suggestions)
        return jsonify({
            "message": "Suggestions initialized successfully",
            "count": len(result.inserted_ids)
        }), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@main.route('/get_phase_suggestions/<phase>', methods=['GET'])
def get_phase_suggestions(phase):
    #Gets dietary and lifestyle suggestions for a specific phase
    try:
        suggestions = mongo.db.suggestions.find_one({"phase": phase})
        if not suggestions:
            return jsonify({"error": "Phase not found"}), 404

        # Convert ObjectId to string for JSON serialization
        suggestions["_id"] = str(suggestions["_id"])
        return jsonify(suggestions), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@main.route('/get_suggestions_by_date/<user_id>', methods=['GET'])
def get_suggestions_by_date(user_id):
    # Gets suggestions based on the user's current cycle phase
    try:
        # Check if user exists using Firebase UID
        user = mongo.db.users.find_one({"firebase_uid": user_id})
        if not user:
            return jsonify({"error": "User not found"}), 404

        # Find the user's current cycle using Firebase UID
        current_cycle = mongo.db.cycles.find_one(
            {"user_id": user_id, "end_date": None},
            sort=[("start_date", -1)]
        )
        
        if not current_cycle:
            return jsonify({"error": "No active cycle found"}), 404

        current_phase = current_cycle.get("current_phase", "Menstrual")
        
        # Get suggestions for the current phase
        suggestions = mongo.db.suggestions.find_one({"phase": current_phase})
        if not suggestions:
            return jsonify({"error": "No suggestions found for current phase"}), 404

        # Convert ObjectId to string
        suggestions["_id"] = str(suggestions["_id"])
        
        return jsonify({
            "phase": current_phase,
            "suggestions": suggestions
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

def get_current_cycle_info_internal(user_id):
    # Helper function to calculate accurate cycle information
    try:
        # Get the current
        current_cycle = mongo.db.cycles.find_one(
            {"user_id": user_id, "end_date": None},
            sort=[("start_date", -1)]
        )
        
        if not current_cycle:
            return {
                "cycle_day": 1,
                "cycle_phase": "Menstrual",
                "days_until_next_period": 28
            }
        
        # Get all period logs for this cycle to determine actual patterns
        period_logs = list(mongo.db.period_logs.find(
            {"user_id": user_id, "cycle_id": current_cycle["_id"]}
        ).sort("start_date", 1))
        
        # Get previous cycles to learn about this user's patterns
        previous_cycles = list(mongo.db.cycles.find(
            {"user_id": user_id, "end_date": {"$ne": None}}
        ).sort("start_date", -1).limit(3))
        
        # Calculate average cycle length based on previous cycles
        cycle_lengths = []
        for i in range(len(previous_cycles) - 1):
            start = previous_cycles[i+1]["start_date"]  # Earlier cycle
            end = previous_cycles[i]["start_date"]      # Later cycle
            length = (end - start).days
            if 15 <= length <= 40:  # Filter out obviously incorrect data
                cycle_lengths.append(length)
        
        avg_cycle_length = sum(cycle_lengths) / len(cycle_lengths) if cycle_lengths else 28
        
        # Determine average period length from previous cycles
        avg_period_length = 5  # Default
        if len(previous_cycles) > 0:
            period_lengths = []
            for cycle in previous_cycles:
                cycle_logs = list(mongo.db.period_logs.find({"cycle_id": cycle["_id"]}))
                if cycle_logs:
                    # Find continuous days with bleeding
                    logs_by_date = sorted(cycle_logs, key=lambda x: x["start_date"])
                    if logs_by_date:
                        # Count max consecutive days
                        max_consecutive = 1
                        current_consecutive = 1
                        for i in range(1, len(logs_by_date)):
                            days_diff = (logs_by_date[i]["start_date"] - logs_by_date[i-1]["start_date"]).days
                            if days_diff <= 2:  # Allow 1 day gap
                                current_consecutive += 1
                            else:
                                max_consecutive = max(max_consecutive, current_consecutive)
                                current_consecutive = 1
                        max_consecutive = max(max_consecutive, current_consecutive)
                        period_lengths.append(max_consecutive)
            
            if period_lengths:
                avg_period_length = sum(period_lengths) / len(period_lengths)
                avg_period_length = max(3, min(10, round(avg_period_length)))  # Reasonable bounds
        
        today = datetime.now()
        cycle_start_date = current_cycle.get("start_date")
        cycle_day = (today - cycle_start_date).days + 1
        
        # If we have period logs, use them to determine if still in menstrual phase
        still_in_period = False
        if period_logs:
            latest_log = period_logs[-1]
            days_since_latest_log = (today - latest_log["start_date"]).days
            
            # Consider still in period if less than 2 days since last log
            still_in_period = days_since_latest_log < 2 and cycle_day <= avg_period_length + 2
            
            # Override cycle day for continuous tracking if logging multiple days
            if len(period_logs) > 1:
                # Check if logs are consecutive
                consecutive_days = True
                for i in range(1, len(period_logs)):
                    if (period_logs[i]["start_date"] - period_logs[i-1]["start_date"]).days > 2:
                        consecutive_days = False
                        break
                
                if consecutive_days:
                    cycle_day = len(period_logs) + (today - period_logs[-1]["start_date"]).days
        
        # ADAPTIVE PHASE DETERMINATION:
        # Divide the cycle into phases based on the user's average cycle length
        # and the presence of bleeding
        follicular_start = avg_period_length + 1
        ovulation_start = max(follicular_start + 3, int(avg_cycle_length * 0.36))
        luteal_start = max(ovulation_start + 3, int(avg_cycle_length * 0.5)) 
        
        if cycle_day <= avg_period_length or still_in_period:
            current_phase = "Menstrual"
        elif cycle_day < ovulation_start:
            current_phase = "Follicular"
        elif cycle_day < luteal_start:
            current_phase = "Ovulation"
        else:
            current_phase = "Luteal"
        
        # Update the cycle with the current phase if it changed
        if current_cycle.get("current_phase") != current_phase:
            mongo.db.cycles.update_one(
                {"_id": current_cycle["_id"]},
                {"$set": {"current_phase": current_phase}}
            )
        
        # Estimate days until next period based on average cycle length
        days_until_next_period = max(0, int(avg_cycle_length) - cycle_day)
        
        return {
            "cycle_day": cycle_day,
            "cycle_phase": current_phase,
            "days_until_next_period": days_until_next_period,
            "cycle_id": str(current_cycle["_id"]),
            "avg_cycle_length": avg_cycle_length,
            "avg_period_length": avg_period_length
        }
        
    except Exception as e:
        print(f"Error in get_current_cycle_info_internal: {str(e)}")
        return {
            "cycle_day": 1,
            "cycle_phase": "Menstrual",
            "days_until_next_period": 28
        }

######### Phase-based Trends Routes ##########

@main.route('/get_energy_levels_by_phase/<user_id>', methods=['GET'])
def get_energy_levels_by_phase(user_id):
    # Gets average energy levels for each cycle phase
    try:
        # Check if user exists
        user = mongo.db.users.find_one({"firebase_uid": user_id})
        if not user:
            return jsonify({"error": "User not found"}), 404
            
        # Get time range parameter (default to 3 months)
        time_range = request.args.get('time_range', '3 months')
        cutoff_date = _get_cutoff_date_from_time_range(time_range)
        
        # Get mood entries that include energy levels, filtered by date and grouped by phase
        pipeline = [
            {"$match": {
                "user_id": user_id,
                "date": {"$gte": cutoff_date}
            }},
            {"$group": {
                "_id": "$cycle_phase",
                "average_energy": {"$avg": "$energy_level"}
            }}
        ]
        
        result = list(mongo.db.moods.aggregate(pipeline))
        
        # Format the results
        energy_levels = {}
        for item in result:
            if item["_id"] and item["_id"] in ["Menstrual", "Follicular", "Ovulation", "Luteal"]:
                energy_levels[item["_id"]] = round(item["average_energy"], 1)
                
        # Add any missing phases with default values
        for phase in ["Menstrual", "Follicular", "Ovulation", "Luteal"]:
            if phase not in energy_levels:
                # Default values based on typical patterns if no user data is available
                default_values = {
                    "Menstrual": 4.2, 
                    "Follicular": 7.6, 
                    "Ovulation": 8.3, 
                    "Luteal": 5.8
                }
                energy_levels[phase] = default_values[phase]
                
        return jsonify({"energy_levels": energy_levels}), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@main.route('/get_cravings_by_phase/<user_id>', methods=['GET'])
def get_cravings_by_phase(user_id):
    # Gets common cravings for each cycle phase from notes and tracking data
    try:
        # Check if user exists
        user = mongo.db.users.find_one({"firebase_uid": user_id})
        if not user:
            return jsonify({"error": "User not found"}), 404
            
        # Get time range parameter
        time_range = request.args.get('time_range', '3 months')
        cutoff_date = _get_cutoff_date_from_time_range(time_range)
        
        # Get mood entries with notes
        mood_entries = list(mongo.db.moods.find({
            "user_id": user_id,
            "date": {"$gte": cutoff_date},
            "notes": {"$ne": ""}
        }))
        
        # Extract cravings from notes using keywords
        craving_keywords = {
            "chocolate": ["chocolate", "cocoa", "brownie", "cake"],
            "sweets": ["sugar", "sweets", "candy", "dessert", "ice cream", "cookie"],
            "carbs": ["carbs", "bread", "pasta", "pizza", "rice", "potato"],
            "salt": ["salt", "salty", "chips", "fries", "pretzel"],
            "fresh fruits": ["fruit", "apple", "banana", "berries", "orange"],
            "vegetables": ["vegetable", "salad", "greens", "broccoli"],
            "protein": ["protein", "meat", "chicken", "fish", "eggs"],
            "dairy": ["cheese", "milk", "yogurt", "dairy"],
            "comfort food": ["comfort", "mac and cheese", "soup", "stew"]
        }
        
        # Dictionary to store cravings by phase
        cravings_by_phase = {
            "Menstrual": set(),
            "Follicular": set(),
            "Ovulation": set(),
            "Luteal": set()
        }
        
        # Analyze notes to extract cravings
        for entry in mood_entries:
            phase = entry.get("cycle_phase", "Unknown")
            if phase not in cravings_by_phase:
                continue
                
            notes = entry.get("notes", "").lower()
            
            # Check for craving-related content
            if "crave" in notes or "craving" in notes or "want" in notes or "desire" in notes:
                for craving, keywords in craving_keywords.items():
                    for keyword in keywords:
                        if keyword in notes:
                            cravings_by_phase[phase].add(craving)
        
        # If we don't have enough data, add some typical cravings for each phase
        default_cravings = {
            "Menstrual": ["Chocolate", "Salt", "Carbs"],
            "Follicular": ["Fresh fruits", "Vegetables", "Protein"],
            "Ovulation": ["Light meals", "Fresh foods", "Proteins"],
            "Luteal": ["Sweets", "Carbohydrates", "Comfort food"]
        }
        
        # Combine user data with defaults where needed
        results = {}
        for phase, cravings in cravings_by_phase.items():
            # If we have user data, use it; otherwise use defaults
            if len(cravings) >= 2:
                results[phase] = list(cravings)
            else:
                # Add at least one user craving if available
                combined = list(cravings)
                # Add defaults that aren't already in the user cravings
                for default in default_cravings.get(phase, []):
                    if default.lower() not in [c.lower() for c in combined]:
                        combined.append(default)
                        if len(combined) >= 3:
                            break
                results[phase] = combined
                
        return jsonify({"cravings": results}), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@main.route('/get_feelings_by_phase/<user_id>', methods=['GET'])
def get_feelings_by_phase(user_id):
    # Gets common feelings/emotions for each cycle phase
    try:
        # Check if user exists
        user = mongo.db.users.find_one({"firebase_uid": user_id})
        if not user:
            return jsonify({"error": "User not found"}), 404
            
        # Get time range parameter
        time_range = request.args.get('time_range', '3 months')
        cutoff_date = _get_cutoff_date_from_time_range(time_range)
        
        # Get mood entries
        mood_entries = list(mongo.db.moods.find({
            "user_id": user_id,
            "date": {"$gte": cutoff_date}
        }))
        
        # Group moods by phase
        moods_by_phase = {
            "Menstrual": [],
            "Follicular": [],
            "Ovulation": [],
            "Luteal": []
        }
        
        for entry in mood_entries:
            phase = entry.get("cycle_phase", "Unknown")
            if phase in moods_by_phase:
                moods_by_phase[phase].append(entry.get("mood", ""))
                
        # Count frequency of moods in each phase
        feelings_by_phase = {}
        for phase, moods in moods_by_phase.items():
            mood_count = {}
            for mood in moods:
                if mood:
                    mood_count[mood] = mood_count.get(mood, 0) + 1
                    
            # Get the top moods for this phase
            top_moods = sorted(mood_count.items(), key=lambda x: x[1], reverse=True)
            top_moods = [m[0] for m in top_moods[:3]]
            
            # If we don't have enough data, use default feelings for this phase
            default_feelings = {
                "Menstrual": ["Tired", "Reflective", "Intuitive"],
                "Follicular": ["Energetic", "Social", "Creative"],
                "Ovulation": ["Confident", "Outgoing", "Communicative"],
                "Luteal": ["Focused", "Nesting", "Anxious"]
            }
            
            if len(top_moods) < 3:
                for feeling in default_feelings.get(phase, []):
                    if feeling not in top_moods:
                        top_moods.append(feeling)
                        if len(top_moods) >= 3:
                            break
                    
            feelings_by_phase[phase] = top_moods
        
        return jsonify({"feelings": feelings_by_phase}), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@main.route('/get_notes_summary_by_phase/<user_id>', methods=['GET'])
def get_notes_summary_by_phase(user_id):
    # Gets summaries of notes for each cycle phase
    try:
        # Check if user exists
        user = mongo.db.users.find_one({"firebase_uid": user_id})
        if not user:
            return jsonify({"error": "User not found"}), 404
            
        # Get time range parameter
        time_range = request.args.get('time_range', '3 months')
        cutoff_date = _get_cutoff_date_from_time_range(time_range)
        
        # Get mood entries with notes
        notes_entries = list(mongo.db.moods.find({
            "user_id": user_id,
            "date": {"$gte": cutoff_date},
            "notes": {"$ne": ""}
        }))
        
        # Common topics to search for in notes
        topics = {
            "sleep": ["sleep", "tired", "insomnia", "nap", "rest", "fatigue"],
            "social": ["social", "friends", "family", "people", "party", "meet"],
            "productivity": ["productive", "work", "focus", "concentration", "efficient"],
            "exercise": ["exercise", "workout", "gym", "run", "yoga", "active"],
            "stress": ["stress", "anxiety", "worry", "overwhelm", "pressure"],
            "creativity": ["creative", "art", "ideas", "inspiration", "project"],
            "self-care": ["self-care", "pamper", "relax", "bath", "comfort"],
            "mood swings": ["mood swing", "emotional", "irritable", "sensitive"],
            "energy": ["energy", "energetic", "motivation", "drive", "lethargic"],
            "cravings": ["crave", "craving", "appetite", "hungry", "eat"],
            "pain": ["pain", "cramp", "ache", "headache", "sore", "tender"]
        }
        
        # Group notes by phase
        notes_by_phase = {
            "Menstrual": [],
            "Follicular": [],
            "Ovulation": [],
            "Luteal": []
        }
        
        # Analyze notes and group by topic for each phase
        topic_counts = {phase: {} for phase in notes_by_phase.keys()}
        
        for entry in notes_entries:
            phase = entry.get("cycle_phase", "Unknown")
            if phase not in notes_by_phase:
                continue
                
            notes = entry.get("notes", "").lower()
            notes_by_phase[phase].append(notes)
            
            # Count topic occurrences
            for topic, keywords in topics.items():
                for keyword in keywords:
                    if keyword in notes:
                        topic_counts[phase][topic] = topic_counts[phase].get(topic, 0) + 1
                        break
        
        # Generate summaries based on topic frequency
        summaries = {}
        default_summaries = {
            "Menstrual": ["Rest needed", "Craving comfort", "Self-care important"],
            "Follicular": ["More social", "Productive days", "Starting new projects"],
            "Ovulation": ["High energy", "Socially active", "Feeling attractive"],
            "Luteal": ["Mood swings", "Nesting instinct", "Need for quiet time"]
        }
        
        for phase, counts in topic_counts.items():
            # Get top topics for this phase
            top_topics = sorted(counts.items(), key=lambda x: x[1], reverse=True)
            top_topics = top_topics[:3] if top_topics else []
            
            # Generate summary phrases based on topics
            summary_phrases = []
            for topic, _ in top_topics:
                if topic == "sleep":
                    summary_phrases.append("Need more rest" if phase in ["Menstrual", "Luteal"] else "Sleep quality improved")
                elif topic == "social":
                    summary_phrases.append("Enjoying social activities" if phase in ["Follicular", "Ovulation"] else "Preferring quiet time")
                elif topic == "productivity":
                    summary_phrases.append("Productive and focused" if phase in ["Follicular", "Luteal"] else "Taking things slower")
                elif topic == "exercise":
                    summary_phrases.append("Exercise feels good" if phase in ["Follicular", "Ovulation"] else "Gentler exercise needed")
                elif topic == "stress":
                    summary_phrases.append("Managing stress well" if phase in ["Follicular", "Ovulation"] else "More sensitive to stress")
                elif topic == "creativity":
                    summary_phrases.append("Creative inspiration flowing" if phase in ["Follicular"] else "")
                elif topic == "self-care":
                    summary_phrases.append("Self-care important" if phase in ["Menstrual", "Luteal"] else "")
                elif topic == "mood swings":
                    summary_phrases.append("Emotional sensitivity" if phase in ["Luteal"] else "")
                elif topic == "energy":
                    summary_phrases.append("Energy levels high" if phase in ["Follicular", "Ovulation"] else "Energy levels lower")
                elif topic == "cravings":
                    summary_phrases.append("Food cravings present" if phase in ["Luteal", "Menstrual"] else "")
                elif topic == "pain":
                    summary_phrases.append("Managing discomfort" if phase in ["Menstrual"] else "")
                    
            # Filter out empty phrases
            summary_phrases = [p for p in summary_phrases if p]
            
            # Use default summaries if we don't have enough data
            if len(summary_phrases) < 3:
                for phrase in default_summaries.get(phase, []):
                    if phrase not in summary_phrases:
                        summary_phrases.append(phrase)
                        if len(summary_phrases) >= 3:
                            break
            
            summaries[phase] = summary_phrases[:3]  # Limit to top 3
            
        return jsonify({"notes_summary": summaries}), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500
        
@main.route('/get_sentiment_by_phase/<user_id>', methods=['GET'])
def get_sentiment_by_phase(user_id):
    # Gets sentiment analysis results grouped by cycle phase
    try:
        # Check if user exists
        user = mongo.db.users.find_one({"firebase_uid": user_id})
        if not user:
            return jsonify({"error": "User not found"}), 404
            
        # Get time range parameter
        time_range = request.args.get('time_range', '3 months')
        cutoff_date = _get_cutoff_date_from_time_range(time_range)
        
        # Get mood entries with notes for sentiment analysis
        notes_entries = list(mongo.db.moods.find({
            "user_id": user_id,
            "date": {"$gte": cutoff_date},
            "notes": {"$ne": ""}
        }))
        
        # Use the mood entry for sentiment if nlp analysis isn't available
        sentiment_by_phase = {
            "Menstrual": {"Positive": 0, "Neutral": 0, "Negative": 0},
            "Follicular": {"Positive": 0, "Neutral": 0, "Negative": 0},
            "Ovulation": {"Positive": 0, "Neutral": 0, "Negative": 0},
            "Luteal": {"Positive": 0, "Neutral": 0, "Negative": 0}
        }
        
        positive_moods = ["happy", "excited", "energetic", "calm", "peaceful", "content", "focused"]
        negative_moods = ["sad", "anxious", "angry", "irritable", "stressed", "depressed", "overwhelmed"]
        
        # Categorize entries based on mood
        for entry in notes_entries:
            phase = entry.get("cycle_phase", "Unknown")
            if phase not in sentiment_by_phase:
                continue
                
            mood = entry.get("mood", "").lower()
            energy = entry.get("energy_level", 5)
            
            if mood in positive_moods or energy >= 7:
                sentiment_by_phase[phase]["Positive"] += 1
            elif mood in negative_moods or energy <= 3:
                sentiment_by_phase[phase]["Negative"] += 1
            else:
                sentiment_by_phase[phase]["Neutral"] += 1
        
        # If we don't have enough data for any phase, use default distributions
        default_sentiment = {
            "Menstrual": {"Positive": 30, "Neutral": 50, "Negative": 20},
            "Follicular": {"Positive": 70, "Neutral": 20, "Negative": 10},
            "Ovulation": {"Positive": 80, "Neutral": 15, "Negative": 5},
            "Luteal": {"Positive": 40, "Neutral": 30, "Negative": 30}
        }
        
        # Replace phases that dont have enough data with defaults
        for phase, sentiments in sentiment_by_phase.items():
            total = sum(sentiments.values())
            if total < 5:  # If fewer than 5 data points, use defaults
                sentiment_by_phase[phase] = default_sentiment[phase]
            else:
                # Make sure percentages add up to 100
                total_percent = sum(sentiment_by_phase[phase].values())
                if total_percent == 0:
                    sentiment_by_phase[phase] = default_sentiment[phase]
        
        return jsonify({"sentiment": sentiment_by_phase}), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Helper function for time range calculations
def _get_cutoff_date_from_time_range(time_range):
    #Converts a time range string to a cutoff date
    now = datetime.now()
    
    if time_range == "1 month":
        return now - timedelta(days=30)
    elif time_range == "3 months":
        return now - timedelta(days=90)
    elif time_range == "6 months":
        return now - timedelta(days=180)
    elif time_range == "1 year":
        return now - timedelta(days=365)
    else:
        # Default to 3 months
        return now - timedelta(days=90)

@main.route('/update_cycle_length/<user_id>', methods=['PUT'])
def update_cycle_length(user_id):
    # Updates a user's average cycle length
    try:
        # Get request data
        data = request.get_json()
        if not data:
            return jsonify({"error": "No data provided", "success": False}), 400
            
        # Check if user exists using Firebase UID
        user = mongo.db.users.find_one({"firebase_uid": user_id})
        if not user:
            return jsonify({"error": "User not found", "success": False}), 404
            
        # Extract cycle length value with validation
        avg_cycle_length = data.get("average_cycle_length")
        
        if avg_cycle_length is None:
            return jsonify({"error": "Average cycle length not provided", "success": False}), 400
            
        if not isinstance(avg_cycle_length, int) or avg_cycle_length < 21 or avg_cycle_length > 45:
            return jsonify({"error": "Average cycle length must be between 21 and 45 days", "success": False}), 400
        
        # Update only the cycle length
        result = mongo.db.users.update_one(
            {"firebase_uid": user_id},
            {"$set": {"avg_cycle_length": avg_cycle_length}}
        )
        
        if result.modified_count > 0:
            return jsonify({"message": "Cycle length updated successfully", "success": True}), 200
        else:
            # If no document was modified (might be same value)
            return jsonify({"message": "No changes made to cycle length", "success": True}), 200
            
    except Exception as e:
        print(f"Error updating cycle length: {str(e)}")
        return jsonify({"error": f"An error occurred: {str(e)}", "success": False}), 500

@main.route('/update_period_length/<user_id>', methods=['PUT'])
def update_period_length(user_id):
    # Updates a user's average period length
    try:
        # Get request data
        data = request.get_json()
        if not data:
            return jsonify({"error": "No data provided", "success": False}), 400
            
        # Check if user exists using Firebase UID
        user = mongo.db.users.find_one({"firebase_uid": user_id})
        if not user:
            return jsonify({"error": "User not found", "success": False}), 404
            
        # Extract period length value with validation
        avg_period_length = data.get("average_period_length")
        
        if avg_period_length is None:
            return jsonify({"error": "Average period length not provided", "success": False}), 400
            
        if not isinstance(avg_period_length, int) or avg_period_length < 1 or avg_period_length > 10:
            return jsonify({"error": "Average period length must be between 1 and 10 days", "success": False}), 400
        
        # Update only the period length
        result = mongo.db.users.update_one(
            {"firebase_uid": user_id},
            {"$set": {"avg_period_length": avg_period_length}}
        )
        
        if result.modified_count > 0:
            return jsonify({"message": "Period length updated successfully", "success": True}), 200
        else:
            # If no document was modified (might be same value)
            return jsonify({"message": "No changes made to period length", "success": True}), 200
            
    except Exception as e:
        print(f"Error updating period length: {str(e)}")
        return jsonify({"error": f"An error occurred: {str(e)}", "success": False}), 500

@main.route('/update_cycle_settings/<user_id>', methods=['PUT'])
def update_cycle_settings(user_id):
    #Updates a user's cycle settings (both cycle length and period length)
    try:
        # Get request data
        data = request.get_json()
        if not data:
            return jsonify({"error": "No data provided", "success": False}), 400
            
        # Check if user exists using Firebase UID
        user = mongo.db.users.find_one({"firebase_uid": user_id})
        if not user:
            return jsonify({"error": "User not found", "success": False}), 404
            
        # Extract values with validation
        avg_cycle_length = data.get("average_cycle_length")
        avg_period_length = data.get("average_period_length")
        
        # Validate cycle length
        if avg_cycle_length is not None:
            if not isinstance(avg_cycle_length, int) or avg_cycle_length < 21 or avg_cycle_length > 45:
                return jsonify({"error": "Average cycle length must be between 21 and 45 days", "success": False}), 400
                
        # Validate period length
        if avg_period_length is not None:
            if not isinstance(avg_period_length, int) or avg_period_length < 1 or avg_period_length > 10:
                return jsonify({"error": "Average period length must be between 1 and 10 days", "success": False}), 400
        
        # Create update dictionary with only provided values
        update_fields = {}
        if avg_cycle_length is not None:
            update_fields["avg_cycle_length"] = avg_cycle_length
        if avg_period_length is not None:
            update_fields["avg_period_length"] = avg_period_length
            
        # If no valid fields to update, return error
        if not update_fields:
            return jsonify({"error": "No valid settings provided to update", "success": False}), 400
        
        # Update the settings
        result = mongo.db.users.update_one(
            {"firebase_uid": user_id},
            {"$set": update_fields}
        )
        
        if result.modified_count > 0:
            return jsonify({"message": "Cycle settings updated successfully", "success": True}), 200
        else:
            # If no document was modified (might be same values)
            return jsonify({"message": "No changes made to cycle settings", "success": True}), 200
            
    except Exception as e:
        print(f"Error updating cycle settings: {str(e)}")
        return jsonify({"error": f"An error occurred: {str(e)}", "success": False}), 500

@main.route('/user_settings/<user_id>', methods=['GET'])
def get_user_settings(user_id):
    # Gets a user's settings including personal details and cycle preferences
    try:
        # Check if user exists using Firebase UID
        user = mongo.db.users.find_one({"firebase_uid": user_id})
        if not user:
            return jsonify({"error": "User not found", "success": False}), 404
        
        # Extract relevant settings
        settings = {
            "name": user.get("name", "User"),
            "email": user.get("email", ""),
            "average_cycle_length": user.get("avg_cycle_length", 28),
            "average_period_length": user.get("avg_period_length", 5)
        }
        
        return jsonify(settings), 200
            
    except Exception as e:
        print(f"Error getting user settings: {str(e)}")
        return jsonify({
            "error": f"An error occurred: {str(e)}", 
            "success": False,
            "name": "User",
            "email": "",
            "average_cycle_length": 28,
            "average_period_length": 5
        }), 500

######### Testing Endpoints ##########

@main.route('/test_set_cycle_phase/<user_id>', methods=['POST'])
def test_set_cycle_phase_post(user_id):
    # Testing endpoint to manually set a user's cycle phase for testing mood predictions
    data = request.get_json()
    
    if "phase" not in data:
        return jsonify({"error": "Phase is required"}), 400
        
    # Validate phase
    valid_phases = ["Menstrual", "Follicular", "Ovulation", "Luteal"]
    phase = data["phase"]
    
    if phase not in valid_phases:
        return jsonify({
            "error": f"Invalid phase. Must be one of {', '.join(valid_phases)}"
        }), 400
    
    # Find current cycle
    current_cycle = mongo.db.cycles.find_one(
        {"user_id": user_id, "end_date": None},
        sort=[("start_date", -1)]
    )
    
    if not current_cycle:
        return jsonify({"error": "No active cycle found for user"}), 404
    
    # Update cycle phase
    mongo.db.cycles.update_one(
        {"_id": current_cycle["_id"]},
        {"$set": {"current_phase": phase}}
    )
    
    return jsonify({
        "message": f"User cycle phase set to {phase} for testing",
        "user_id": user_id,
        "previous_phase": current_cycle["current_phase"],
        "new_phase": phase
    }), 200

@main.route('/test/check_suggestions/<user_id>', methods=['GET'])
def test_check_suggestions(user_id):
    # Testing endpoint to check the current suggestions for a user
    try:
        # Find the user's current cycle
        current_cycle = mongo.db.cycles.find_one(
            {"user_id": user_id, "end_date": None},
            sort=[("start_date", -1)]
        )
        
        if not current_cycle:
            return jsonify({
                "error": "No active cycle found",
                "current_phase": None,
                "suggestions": None
            }), 404
            
        current_phase = current_cycle.get("current_phase", "Unknown")
        
        # Get suggestions for current phase
        suggestions = mongo.db.suggestions.find_one({"phase": current_phase})
        if not suggestions:
            return jsonify({
                "error": f"No suggestions found for phase '{current_phase}'",
                "current_phase": current_phase,
                "suggestions": None
            }), 404
            
        # Convert ObjectId to string
        suggestions["_id"] = str(suggestions["_id"])
        
        return jsonify({
            "current_phase": current_phase,
            "suggestions": {
                "diet": suggestions.get("diet", []),
                "lifestyle": suggestions.get("lifestyle", [])
            }
        }), 200
            
    except Exception as e:
        print(f"Error in test_check_suggestions: {str(e)}")
        return jsonify({"error": f"An error occurred: {str(e)}"}, 500)
