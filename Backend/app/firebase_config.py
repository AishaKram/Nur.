# This file handles the firebase initialisation. 
from firebase_admin import credentials, initialize_app
from config.config import Config  # Import from config.py

cred = credentials.Certificate(Config.FIREBASE_CREDENTIALS)
firebase_app = initialize_app(cred)
