# Female Health App - Backend

This is the Flask backend I built for my women's health tracking app, focusing on ML-based insights and secure data management.

## My Approach

I wanted to create a backend that did more than just store data - it actually learns from user input to provide increasingly personalized insights. The ML components were challenging but ended up being the most rewarding part of this project.

## Features I Implemented

- **User Authentication**: Secure login using Firebase
- **Cycle Tracking**: Accurate cycle predictions based on user history
- **Mood Analysis**: My favorite part - a custom ML model that finds patterns between moods and cycle phases
- **NLP Analysis**: Text processing for journal entries
- **Custom Recommendations**: Phase-specific health suggestions

## Tech Stack

I chose these technologies for my backend:
- **Flask**: Light but powerful framework that I was already comfortable with
- **MongoDB**: For flexible data storage (perfect for this project where data schemas evolve)
- **Firebase Auth**: Handles the security so I could focus on the app's core features
- **scikit-learn**: For building the ML models
- **Transformers**: For NLP capabilities

## API Endpoints

### Authentication
- `POST /login`: User login with email/password
- `POST /reset-password`: Password reset functionality
- `POST /confirm-password-reset`: Complete reset with token

### Cycle Data
- `POST /log_period`: Record period data
- `GET /get_cycles/{user_id}`: Get cycle history
- `GET /get_current_cycle_info/{user_id}`: Get current phase info

### Mood & Insights
- `POST /log_mood`: Save mood entries
- `GET /get_moods/{user_id}`: Retrieve mood history
- `GET /ml/predict_mood/{user_id}`: Use ML to predict mood based on cycle pattern
- `POST /ml/analyze_notes`: Process journal entries

### Trend Analysis
- `GET /get_energy_levels_by_phase/{user_id}`: Energy level trends
- `GET /get_feelings_by_phase/{user_id}`: Emotional patterns
- `GET /get_sentiment_by_phase/{user_id}`: Sentiment analysis results

## ML Components

### Mood Predictor
I'm particularly proud of this component - it identifies correlations between cycle phases and mood patterns. As the user logs more data, the predictions get increasingly accurate.

Key algorithms:
- Pattern recognition across multiple cycles
- Confidence scoring based on available data points
- Phase-specific trend analysis

### NLP Analyzer
This component extracts insights from journal entries, identifying:
- Sentiment (positive/negative/neutral)
- Common symptoms mentioned
- Recurring themes

## Database Structure

I designed my MongoDB collections to balance flexibility and performance:

- **users**: Authentication and profile data
- **cycles**: Menstrual cycle history and metadata
- **moods**: Daily mood and energy tracking
- **suggestions**: Personalized recommendations

## Setup & Installation

### Prerequisites
- Python 3.9+
- MongoDB
- Firebase project with Admin SDK

### Installation Steps

1. Clone repository
```bash
git clone https://github.com/AishaKram/Nur..git
cd Backend
```

2. Set up the environment
```bash
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```

3. Configure Firebase
Place your Firebase Admin SDK JSON in `config/` and update the path in `config/config.py`.

4. Initialize the database
```bash
python setup_database.py
```

5. Start the server
```bash
python app.py
```

## Challenges I Overcame

- **ML Model Training**: Balancing accuracy with limited initial data
- **Firebase Integration**: Learning the ins and outs of Firebase Auth
- **API Design**: Creating intuitive endpoints for the Flutter frontend
- **Performance Optimization**: Ensuring fast response times for ML predictions

## Testing

I created tests to verify the backend functionality:
```bash
python -m unittest discover -s app/tests
```

The performance tests in `app/tests/performance_test.py` test ML components.

