# This file contains helper methods to interact with the DB
# A hybrid approach has been used with both object-oriented classes and functional interfaces.
# The BaseCollection class and its subclasses provide an organized, encapsulated interface to the database.
# The standalone functions at the bottom maintain compatibility with existing code.


from bson.objectid import ObjectId  
from app import mongo
from datetime import datetime

class BaseCollection:
    # Base class for MongoDB collection operations
    
    def __init__(self, collection_name):
        self.collection = mongo.db[collection_name]
    
    def find_one(self, query):
        # Find a single document matching the query
        return self.collection.find_one(query)
    
    def find(self, query, **kwargs):
        # Find all documents matching the query
        return self.collection.find(query, **kwargs)
    
    def insert_one(self, document):
        # Insert a single document
        return self.collection.insert_one(document)
    
    def update_one(self, query, update):
        # Update a single document
        return self.collection.update_one(query, update)
    
    def delete_one(self, query):
        # Delete a single document
        return self.collection.delete_one(query)


class UserModel(BaseCollection):
    # User collection operations
    
    def __init__(self):
        super().__init__('users')
    
    def create_user(self, email, name, dob, occupation, last_period, firebase_uid):
        # Inserts a new user into the database
        user_data = {
            "_id": ObjectId(),
            "email": email,
            "name": name,
            "dob": dob,
            "occupation": occupation,
            "last_period": last_period,
            "firebase_uid": firebase_uid,
            "created_at": datetime.now()
        }
        self.insert_one(user_data)
        return user_data["_id"]
    
    def get_by_email(self, email):
        # Finds a user by their email
        return self.find_one({"email": email})
    
    def get_by_firebase_uid(self, firebase_uid):
        # Finds a user by their Firebase UID
        return self.find_one({"firebase_uid": firebase_uid})
    
    def update_last_period(self, email, last_period):
        # Updates the user's last period date
        return self.update_one(
            {"email": email},
            {"$set": {"last_period": last_period}}
        )
    
    def update_profile(self, firebase_uid, update_data):
        # Updates user profile information
        # Remove sensitive fields from update data
        if 'email' in update_data: 
            del update_data['email']
        if 'firebase_uid' in update_data: 
            del update_data['firebase_uid']
            
        update_data['updated_at'] = datetime.now()
        return self.update_one(
            {"firebase_uid": firebase_uid},
            {"$set": update_data}
        )


class CycleModel(BaseCollection):
    # Cycle collection operations
    
    def __init__(self):
        super().__init__('cycles')
    
    def create_cycle(self, user_id, start_date, end_date=None, current_phase="Menstrual"):
        # Adds a new menstrual cycle entry using Firebase UID
        cycle_data = {
            "user_id": user_id,
            "start_date": start_date,
            "end_date": end_date,
            "current_phase": current_phase,
            "created_at": datetime.now()
        }
        return self.insert_one(cycle_data)
    
    def get_latest_cycle(self, user_id):
        # Finds the most recent cycle for a user using Firebase UID
        return self.find_one(
            {"user_id": user_id},
            sort=[("start_date", -1)]
        )
    
    def get_all_cycles(self, user_id):
        # Gets all cycles for a user
        return list(self.find({"user_id": user_id}, sort=[("start_date", -1)]))
    
    def update_cycle_phase(self, cycle_id, new_phase):
        # Updates the phase of a specific cycle
        return self.update_one(
            {"_id": cycle_id},
            {"$set": {"current_phase": new_phase, "updated_at": datetime.now()}}
        )
    
    def end_current_cycle(self, user_id, end_date):
        # End the current  cycle
        current_cycle = self.find_one(
            {"user_id": user_id, "end_date": None},
            sort=[("start_date", -1)]
        )
        
        if current_cycle:
            return self.update_one(
                {"_id": current_cycle["_id"]},
                {"$set": {"end_date": end_date, "updated_at": datetime.now()}}
            )
        return None


class MoodModel(BaseCollection):
    # Mood collection operations
    
    def __init__(self):
        super().__init__('moods')
    
    def create_mood_entry(self, user_id, date, mood, energy_level, notes=None, cycle_phase=None):
        # Logs user's mood and energy levels using Firebase UID
        mood_data = {
            "user_id": user_id,
            "date": date,
            "mood": mood,
            "energy_level": energy_level,
            "created_at": datetime.now()
        }
        
        if notes:
            mood_data["notes"] = notes
            
        if cycle_phase:
            mood_data["cycle_phase"] = cycle_phase
            
        return self.insert_one(mood_data)
    
    def get_mood_entries(self, user_id, start_date=None, end_date=None):
        # Gets all mood entries for a user in a specific time range using Firebase UID
        query = {"user_id": user_id}
        
        if start_date or end_date:
            date_query = {}
            if start_date:
                date_query["$gte"] = start_date
            if end_date:
                date_query["$lte"] = end_date
            query["date"] = date_query
            
        return list(self.find(query, sort=[("date", -1)]))
    
    def get_moods_by_phase(self, user_id, phase):
        # Gets mood entries for a specific cycle phase
        return list(self.find(
            {"user_id": user_id, "cycle_phase": phase},
            sort=[("date", -1)]
        ))


class SuggestionModel(BaseCollection):
    # Suggestion collection operations
    
    def __init__(self):
        super().__init__('suggestions')
    
    def create_suggestion(self, phase, category, recommendation):
        # Adds a new lifestyle/diet suggestion
        suggestion_data = {
            "phase": phase,
            "category": category,
            "recommendation": recommendation,
            "created_at": datetime.now()
        }
        return self.insert_one(suggestion_data)
    
    def get_suggestions_by_phase(self, phase, category=None):
        # Finds suggestions based on cycle phase
        query = {"phase": phase}
        if category:
            query["category"] = category
        return list(self.find(query))


class PeriodLogModel(BaseCollection):
    # Period log collection operations
    
    def __init__(self):
        super().__init__('period_logs')
    
    def create_period_log(self, user_id, cycle_id, start_date, flow_level, symptoms=None):
        # Logs period information with symptoms
        log_data = {
            "user_id": user_id,
            "cycle_id": cycle_id,
            "start_date": start_date,
            "flow_level": flow_level,
            "created_at": datetime.now()
        }
        
        if symptoms:
            log_data["symptoms"] = symptoms
            
        return self.insert_one(log_data)
    
    def get_period_logs_by_user(self, user_id, start_date=None, end_date=None):
        # Gets all period logs for a user in a specific time range
        query = {"user_id": user_id}
        
        if start_date or end_date:
            date_query = {}
            if start_date:
                date_query["$gte"] = start_date
            if end_date:
                date_query["$lte"] = end_date
            query["start_date"] = date_query
            
        return list(self.find(query, sort=[("start_date", -1)]))
    
    def get_period_logs_by_cycle(self, cycle_id):
        # Gets all period logs associated with a specific cycle
        return list(self.find({"cycle_id": cycle_id}, sort=[("start_date", 1)]))
    
    def get_symptoms_frequency(self, user_id):
        # Analyzes symptom frequency across all logs
        symptoms_count = {}
        logs = self.get_period_logs_by_user(user_id)
        
        for log in logs:
            if "symptoms" in log:
                for symptom in log["symptoms"]:
                    symptoms_count[symptom] = symptoms_count.get(symptom, 0) + 1
                    
        return symptoms_count


# Create instances for easy import
users = UserModel()
cycles = CycleModel()
moods = MoodModel()
suggestions = SuggestionModel()
period_logs = PeriodLogModel()


# Backwards compatibility functions to maintain existing codebase

def get_users_collection():
    return mongo.db.users

def create_user(email, name, dob, occupation, last_period, firebase_uid):
    return users.create_user(email, name, dob, occupation, last_period, firebase_uid)

def get_user_by_email(email):
    return users.get_by_email(email)

def update_last_period(email, last_period):
    return users.update_last_period(email, last_period)

def get_cycles_collection():
    return mongo.db.cycles

def create_cycle(user_id, start_date, end_date, current_phase):
    return cycles.create_cycle(user_id, start_date, end_date, current_phase)

def get_latest_cycle(user_id):
    return cycles.get_latest_cycle(user_id)

def get_mood_collection():
    return mongo.db.moods

def create_mood_entry(user_id, date, mood, energy_level):
    return moods.create_mood_entry(user_id, date, mood, energy_level)

def get_mood_entries(user_id, start_date, end_date):
    return moods.get_mood_entries(user_id, start_date, end_date)

def get_suggestions_collection():
    return mongo.db.suggestions

def create_suggestion(phase, recommendation):
    return suggestions.create_suggestion(phase, "general", recommendation)

def get_suggestions_by_phase(phase):
    return suggestions.get_suggestions_by_phase(phase)

def get_period_logs_collection():
    return mongo.db.period_logs

def create_period_log(user_id, cycle_id, start_date, flow_level, symptoms=None):
    return period_logs.create_period_log(user_id, cycle_id, start_date, flow_level, symptoms)

def get_period_logs_by_user(user_id, start_date=None, end_date=None):
    return period_logs.get_period_logs_by_user(user_id, start_date, end_date)
