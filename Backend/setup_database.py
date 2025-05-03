from app.models import create_user, create_cycle, create_mood_entry, create_suggestion, get_users_collection
from datetime import datetime

def setup_database():
    #Initializes the database with sample data if it's empty

    users_collection = get_users_collection()

    # Check if there is already a user in the database
    if users_collection.count_documents({}) == 0:
        print("No users found. Inserting sample user...")

        user_id = create_user(
            email="testuser@example.com",
            name="Test User",
            dob="2003-03-25",
            occupation="Software Engineer",
            last_period="2025-02-15",
            firebase_uid="test_firebase_uid"
        )
        print(f"User created with ID: {user_id}")

        #  Insert a sample menstrual cycle
        print("Inserting sample cycle...")
        create_cycle(
            user_id=user_id,
            start_date="2025-02-15",
            end_date="2025-02-21",
            current_phase="Luteal"
        )
        print("Cycle data added.")

        #  Insert a sample mood entry
        print("Inserting sample mood...")
        create_mood_entry(
            user_id=user_id,
            date=str(datetime.today().date()),
            mood="Happy",
            energy_level=8
        )
        print("Mood data added.")

        #  Insert sample suggestions
        print("Inserting sample suggestions...")
        create_suggestion("Follicular", "Eat protein-rich foods for energy")
        create_suggestion("Luteal", "Avoid caffeine and focus on self-care")
        create_suggestion("Menstrual", "Drink herbal teas to reduce cramps")
        print("Suggestions added.")

        print(" Database setup complete!")
    else:
        print(" Database already contains data. No changes made.")

if __name__ == "__main__":
    setup_database()
