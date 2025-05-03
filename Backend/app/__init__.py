# This file initialises the flask app, MongoDB, firebase and other configureations.
from flask import Flask
from flask_pymongo import PyMongo
from flask_cors import CORS
import firebase_admin
from firebase_admin import credentials
from config.config import Config


mongo = PyMongo()
firebase_app = None  

def create_app():
    global firebase_app

    app = Flask(__name__)
    app.config.from_object(Config)

    # Initialize MongoDB using pyMongo
    mongo.init_app(app)

    # Initialize Firebase & prevent multiple initializations
    if not firebase_admin._apps:  
        cred = credentials.Certificate(Config.FIREBASE_CREDENTIALS)
        firebase_app = firebase_admin.initialize_app(cred)

    # Enable CORS
    CORS(app)

    # Initialize performance middleware
    from app.middleware import init_performance_middleware
    performance_middleware = init_performance_middleware(app)

    # Register Blueprints (Routes)
    from app.routes import main
    from app.ml.routes import ml_routes
    
    app.register_blueprint(main)
    app.register_blueprint(ml_routes, url_prefix='/ml')

    return app
