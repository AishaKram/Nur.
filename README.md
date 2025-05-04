# Female Health Tracker App (Nur)

A comprehensive menstrual cycle tracking application with machine learning insights for holistic women's health management, developed as my final year project.

## Project Overview

I created this app to help women understand their unique cycle patterns. After talking with friends who were frustrated with existing period trackers, I wanted to build something that did more than just track dates - it actually learns from your data to provide personalized insights. The app combines a Flutter mobile frontend with a Flask backend API and MongoDB database.

The ML components analyze patterns in cycle data, moods, and symptoms to generate personalized insights.

## Key Features

- **Period & Symptom Tracking**: Log cycle data with an intuitive UI
- **Cycle Visualization**: See where you are in your cycle with color-coded phase display
- **Mood Analysis**: ML algorithms detect patterns between your cycle and mood changes
- **Personalized Recommendations**: Get tailored health tips based on your cycle phase
- **Trend Analysis**: Interactive charts show your patterns over time

## Tech Stack

### Frontend
- Flutter for cross-platform UI
- HTTP for API communication
- FL Chart for interactive data visualization 
- Shared Preferences for local storage
- Custom UI components for a unique user experience

### Backend
- Flask for REST API endpoints
- MongoDB for flexible data storage
- Firebase Admin SDK for secure authentication
- scikit-learn & pandas for ML analysis
- NLP using transformers for journal entry analysis

## Development Team

This project was developed by Aisha Akram as a final year project for her Computer Science degree.

## Getting Started

Check out the setup instructions in the Frontend and Backend READMEs:
- [Frontend Documentation](Frontend/README.md)
- [Backend Documentation](Backend/README.md)

## Project Journey

This project evolved from a vague idea in my mind to a fully functioning app over a year. 
Some challenges I overcame included:
- Building an intuitive cycle phase visualization
- Implementing the machine learning model for mood prediction
- Creating responsive designs that work across different devices
- Connecting the Flutter frontend with Flask backend securely


## Acknowledgements

Special thanks to my project supervisor for guidance, my personal mentor who motivated me when I couldn't motivate myself- and to the women who provided feedback on my survey.

This project uses open source libraries including Flutter, Firebase, scikit-learn, and Flask.
