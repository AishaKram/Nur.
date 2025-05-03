# Test file to update testuser@example.com data for testing trends page
import sys
from bson.objectid import ObjectId
from datetime import datetime, timedelta, date
from app import create_app, mongo
from app.models import get_user_by_email

# Initialize the Flask app to access the database
app = create_app()
app_context = app.app_context()
app_context.push()


TEST_USER_EMAIL = "testuser@example.com"
TODAY = datetime.combine(datetime.now().date(), datetime.min.time())  

def get_test_user():
# Get the test user from the database
    user = get_user_by_email(TEST_USER_EMAIL)
    if not user:
        print(f"Test user {TEST_USER_EMAIL} not found. Please run setup_database.py first.")
        sys.exit(1)
    return user

def create_period_log(user_id, cycle_id, start_date, flow_level, symptoms=None):
# Create a period log entry
    if symptoms is None:
        symptoms = []
    
    # Making sure start_date is a datetime object
    if isinstance(start_date, date) and not isinstance(start_date, datetime):
        start_date = datetime.combine(start_date, datetime.min.time())
        
    period_log = {
        "user_id": user_id,
        "cycle_id": cycle_id,
        "start_date": start_date,
        "flow_level": flow_level,
        "symptoms": symptoms
    }
    
    result = mongo.db.period_logs.insert_one(period_log)
    print(f"Added period log: {start_date.strftime('%Y-%m-%d')} with flow level {flow_level}")
    return result.inserted_id

def create_complete_cycle(user_id, start_date, length, period_length=5, phase="Menstrual", symptoms=None):
# Create a complete cycle with a proper start and end date 
    if symptoms is None:
        symptoms = []
    
    # Convert string dates to datetime if needed
    if isinstance(start_date, str):
        start_date = datetime.strptime(start_date, "%Y-%m-%d")
    # Convert date to datetime if needed
    elif isinstance(start_date, date) and not isinstance(start_date, datetime):
        start_date = datetime.combine(start_date, datetime.min.time())
    
    # Calculate the end date 
    end_date = start_date + timedelta(days=length-1)
    
    # Insert cycle
    cycle_data = {
        "user_id": user_id,  
        "start_date": start_date,
        "end_date": end_date,
        "current_phase": phase,
        "length": length  
    }
    
    cycle_result = mongo.db.cycles.insert_one(cycle_data)
    cycle_id = cycle_result.inserted_id
    print(f"Added cycle: {start_date.strftime('%Y-%m-%d')} to {end_date.strftime('%Y-%m-%d')} ({length} days) in {phase} phase")
    
    # Add period logs for period_length days
    flow_levels = ["heavy", "heavy", "medium", "light", "spotting"]
    for i in range(min(period_length, 5)):
        day_date = start_date + timedelta(days=i)
        flow_level = flow_levels[i] if i < len(flow_levels) else "light"
        create_period_log(
            user_id=user_id,
            cycle_id=cycle_id,
            start_date=day_date,
            flow_level=flow_level,
            symptoms=symptoms
        )
    
    return cycle_id

def create_current_cycle(user_id, start_date, phase="Menstrual", symptoms=None):
    """Create an active cycle with no end date to represent the current cycle"""
    if symptoms is None:
        symptoms = []
    
    # Convert string dates to datetime if necessary
    if isinstance(start_date, str):
        start_date = datetime.strptime(start_date, "%Y-%m-%d")
    # Convert date to datetime if necessary
    elif isinstance(start_date, date) and not isinstance(start_date, datetime):
        start_date = datetime.combine(start_date, datetime.min.time())
    
    # Insert cycle without an end date (current cycle)
    cycle_data = {
        "user_id": user_id,  # This should be Firebase UID
        "start_date": start_date,
        "end_date": None,  # Current cycle has no end date
        "current_phase": phase,
        "length": 28  # Use average length for current cycle
    }
    
    cycle_result = mongo.db.cycles.insert_one(cycle_data)
    cycle_id = cycle_result.inserted_id
    print(f"Added current cycle starting: {start_date.strftime('%Y-%m-%d')} (ongoing) in {phase} phase")
    
    # Add period logs for the first 5 days
    flow_levels = ["heavy", "heavy", "medium", "light", "spotting"]
    for i in range(5):
        day_date = start_date + timedelta(days=i)
        # Don't add period logs beyond today
        if day_date > datetime.now():
            break
        flow_level = flow_levels[i] if i < len(flow_levels) else "light"
        create_period_log(
            user_id=user_id,
            cycle_id=cycle_id,
            start_date=day_date,
            flow_level=flow_level,
            symptoms=symptoms
        )
    
    return cycle_id

def add_mood_entry(user_id, date_value, mood, energy_level, notes=""):
    #Add a mood entry
    if isinstance(date_value, str):
        date_value = datetime.strptime(date_value, "%Y-%m-%d")
    # Convert date to datetime if necessary
    elif isinstance(date_value, date) and not isinstance(date_value, datetime):
        date_value = datetime.combine(date_value, datetime.min.time())
    
    # Get current cycle phase
    current_cycle = mongo.db.cycles.find_one(
        {"user_id": user_id, "start_date": {"$lte": date_value}},
        sort=[("start_date", -1)]
    )
    
    # Determine the phase based on day in cycle
    phase = "Menstrual"
    if current_cycle:
        start_date = current_cycle.get("start_date")
        days_since_start = (date_value - start_date).days
        
        if days_since_start <= 5:
            phase = "Menstrual"
        elif days_since_start <= 13:
            phase = "Follicular" 
        elif days_since_start <= 17:
            phase = "Ovulation"
        else:
            phase = "Luteal"
    
    mood_entry = {
        "user_id": user_id,
        "date": date_value,
        "mood": mood,
        "energy_level": energy_level,
        "notes": notes,
        "cycle_phase": phase
    }
    
    result = mongo.db.moods.insert_one(mood_entry)
    print(f"Added mood entry on {date_value.strftime('%Y-%m-%d')}: {mood}, energy level {energy_level} in {phase} phase")
    return result.inserted_id

def generate_historical_cycles(user_id, cycles_count=5):
    """Generate multiple historical cycles with realistic lengths"""
    
    # Sample data to make the trends interesting
    cycle_lengths = [28, 30, 26, 29, 31, 27]
    period_lengths = [5, 6, 4, 5, 7, 5]
    symptoms_options = [
        ["cramps", "back pain"],
        ["headache", "tender breasts"],
        ["cramps", "nausea"],
        ["back pain", "headache"],
        ["tender breasts", "cramps"],
        ["nausea", "back pain"]
    ]
    
    # Start date for the first cycle (work backward from today)
    total_days_for_complete_cycles = sum(cycle_lengths[:cycles_count-1])  # All but current cycle
    start_date = TODAY - timedelta(days=total_days_for_complete_cycles + 17)  # Current cycle started 17 days ago
    
    # Create completed cycles
    cycle_ids = []
    current_date = start_date
    
    for i in range(cycles_count - 1):  # All but the last cycle
        cycle_length = cycle_lengths[i % len(cycle_lengths)]
        period_length = period_lengths[i % len(period_lengths)]
        symptoms = symptoms_options[i % len(symptoms_options)]
        
        # Create complete cycle
        cycle_id = create_complete_cycle(
            user_id=user_id,
            start_date=current_date,
            length=cycle_length,
            period_length=period_length,
            phase="Menstrual",  # All completed cycles start in menstrual phase
            symptoms=symptoms
        )
        cycle_ids.append(cycle_id)
        
        # Add mood entries throughout the cycle
        for day in range(cycle_length):

                day_date = current_date + timedelta(days=day)
                
                # Different moods and energy levels based on cycle phase
                if day < period_length:
                    # Menstrual phase
                    mood = "Tired, Emotional"
                    energy = 3
                    notes = "Feeling very tired during my period. Taking it easy today."
                elif day < cycle_length // 3:
                    # Follicular phase
                    mood = "Energetic, Happy"
                    energy = 8
                    notes = "Feeling great today! Lots of energy and motivation."
                elif day < cycle_length * 2 // 3:
                    # Ovulation phase
                    mood = "Confident, Motivated"
                    energy = 9
                    notes = "Very productive day. Feeling focused and positive."
                else:
                    # Luteal phase
                    mood = "Anxious, Irritable"
                    energy = 5
                    notes = "Feeling a bit more irritable today. Some cravings for chocolate."
                
                add_mood_entry(
                    user_id=user_id,
                    date_value=day_date,
                    mood=mood,
                    energy_level=energy,
                    notes=notes
                )
        
        # Move to next cycle start date
        current_date = current_date + timedelta(days=cycle_length)
    
    # Create the final current cycle
    current_cycle_id = create_current_cycle(
        user_id=user_id,
        start_date=current_date,
        phase="Luteal",  # Current cycle is in luteal phase (day 17)
        symptoms=symptoms_options[-1]
    )
    cycle_ids.append(current_cycle_id)
    
    # Add mood entries for the current cycle (which is 17 days in)
    for day in range(17):  # 17 days have passed in the current cycle
            day_date = current_date + timedelta(days=day)
            
            # Different moods based on cycle phase
            if day < 5:
                # Menstrual phase
                mood = "Tired, Emotional"
                energy = 3
                notes = "Feeling very tired during my period. Taking it easy today."
            elif day < 13:
                # Follicular phase
                mood = "Energetic, Happy" 
                energy = 8
                notes = "Feeling great today! Lots of energy and motivation."
            elif day < 17:
                # Ovulation
                mood = "Hopeful, Calm"
                energy = 7
                notes = "Feeling relatively calm and balanced today."
            else:
                #  Luteal phase
                mood = "Anxious, Irritable"
                energy = 5
                notes = "Feeling a bit more irritable today. Some cravings for chocolate."
            
            add_mood_entry(
                user_id=user_id,
                date_value=day_date,
                mood=mood,
                energy_level=energy,
                notes=notes
            )
    
    return cycle_ids

def clear_user_data(user_id):
    """Clear existing user data before generating new data"""
    # Remove existing cycles
    cycles_deleted = mongo.db.cycles.delete_many({"user_id": user_id})
    
    # Remove existing mood entries
    moods_deleted = mongo.db.moods.delete_many({"user_id": user_id})
    
    # Remove existing period logs
    period_logs_deleted = mongo.db.period_logs.delete_many({"user_id": user_id})
    
    print(f"Cleared user data: {cycles_deleted.deleted_count} cycles, {moods_deleted.deleted_count} mood entries, {period_logs_deleted.deleted_count} period logs")

def main():
    print("Updating test data for user:", TEST_USER_EMAIL)
    user = get_test_user()
    
    # Get Firebase UID from MongoDB user
    firebase_uid = user.get("firebase_uid", None)
    if not firebase_uid:
        print("Error: No Firebase UID found for user. Please ensure the test user has a firebase_uid field.")
        sys.exit(1)
        
    print(f"Found user with Firebase UID: {firebase_uid}")
    
    # Ask user if they want to clear existing data
    clear = input("Do you want to clear existing user data? [y/N]: ").lower()
    if clear == 'y':
        clear_user_data(firebase_uid)
    
    # Generate some test data
    print("\nGenerating test data...")
    
    # Get user input for number of cycles to generate
    try:
        cycles_count = int(input("How many cycles do you want to generate? [5]: ") or "5")
    except ValueError:
        cycles_count = 5
    
    # Generate historical cycles with varying lengths using Firebase UID
    cycle_ids = generate_historical_cycles(firebase_uid, cycles_count)
    
    # Print summary
    print("\nGenerated Data Summary:")
    print(f"- Created {len(cycle_ids)} cycles with realistic lengths")
    print(f"- {len(cycle_ids)-1} completed cycles + 1 current cycle in the Luteal phase")
    print(f"- Added period logs with different symptoms and flow levels")
    print(f"- Added mood entries throughout the cycles")
    print("\nYou can now use the trends page to view visualizations of this data.")
    print(f"IMPORTANT: Use '{firebase_uid}' as the user ID when testing the app.")

if __name__ == "__main__":
    main()