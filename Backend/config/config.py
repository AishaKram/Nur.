# This file stores the configuration settings for MongoDB, Firebase and CORS
import os

class Config:
    MONGO_URI = "mongodb://localhost:27017/mydatabase"
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))  # Gets path of the config folder
    FIREBASE_CREDENTIALS = 'config/female-health-app-firebase-adminsdk-fbsvc-74ba6fb650.json'

# Firebase web configuration for client-side authentication
firebase_config = {
    "apiKey": "AIzaSyAi5or9T5ExuuMnxZujpnpEEGrWF-1wDdU",
    "authDomain": "female-health-app.firebaseapp.com",
    "projectId": "female-health-app",
    "storageBucket": "female-health-app.appspot.com",
    "messagingSenderId": "927793418572",
    "appId": "1:927793418572:web:2b392b7c865d9d2f094988"
}



