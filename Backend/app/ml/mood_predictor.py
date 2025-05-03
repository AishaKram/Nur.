## Statistical predictor that learns patters between cycle phases and moods.
# analyses historical data.
import pandas as pd
from datetime import datetime
import joblib
import os
import numpy as np

class MoodPredictor:
    def __init__(self):
        self.model_path = os.path.join(os.path.dirname(__file__), 'mood_patterns.joblib')
        self.mood_patterns = {}
        self.min_cycles_for_prediction = 1
        
    def train(self, data):
    #Learn mood patterns from historical data across multiple cycles
        print(f"Training model with {len(data)} mood entries")
        df = pd.DataFrame(data)
        
        # Add cycle identifier based on cycle_start
        df['cycle_id'] = df['cycle_start']
        
        # Count the number of unique cycles
        unique_cycles = df['cycle_id'].nunique()
        print(f"Found {unique_cycles} unique cycles in the data")
        
        # Group moods by cycle phase and get probabilities
        phase_moods = {}
        for phase in df['cycle_phase'].unique():
            phase_data = df[df['cycle_phase'] == phase]
            mood_counts = phase_data['mood'].value_counts()
            total = len(phase_data)
            phase_moods[phase] = {
                'probabilities': {mood: count/total for mood, count in mood_counts.items()},
                'samples': total,
                'cycles': len(phase_data['cycle_id'].unique())
            }
            print(f"Phase {phase}: {total} samples across {len(phase_data['cycle_id'].unique())} cycles")
        
        # Store information about the training
        model_data = {
            'mood_patterns': phase_moods,
            'total_cycles': unique_cycles,
            'last_trained': datetime.now().isoformat(),
            'total_samples': len(df)
        }
        
        self.mood_patterns = model_data
        joblib.dump(model_data, self.model_path)
        print(f"Model saved to {self.model_path}")
        
        # Calculate simple accuracy based on most common mood per phase
        correct = 0
        total = len(df)
        for phase in phase_moods:
            probs = phase_moods[phase]['probabilities']
            if probs:  # Check if probabilities exist
                most_common = max(probs.items(), key=lambda x: x[1])[0]
                correct += len(df[(df['cycle_phase'] == phase) & (df['mood'] == most_common)])
            
        return correct / total if total > 0 else 0
    
    def predict_mood(self, cycle_day, energy_level, cycle_phase):
        """Predict mood based on cycle phase and patterns from multiple cycles"""
        if not os.path.exists(self.model_path):
            return {
                'predicted_mood': 'Not enough data',
                'confidence': 0.0,
                'has_sufficient_data': False,
                'cycles_tracked': 0,
                'min_cycles_needed': self.min_cycles_for_prediction
            }
            
        # Load patterns if not loaded
        if not self.mood_patterns:
            try:
                self.mood_patterns = joblib.load(self.model_path)
            except:
                return {
                    'predicted_mood': 'Model error',
                    'prediction confidence': 0.0,
                    'has_sufficient_data': False,
                    'cycles_tracked': 0,
                    'min_cycles_needed': self.min_cycles_for_prediction
                }
            
        # Check if there are patterns for this phase and enough cycles
        total_cycles = self.mood_patterns.get('total_cycles', 0)
        
        if cycle_phase not in self.mood_patterns.get('mood_patterns', {}):
            return {
                'predicted_mood': 'Unknown phase',
                'confidence': 0.0,
                'has_sufficient_data': False,
                'cycles_tracked': total_cycles,
                'min_cycles_needed': self.min_cycles_for_prediction
            }
            
        phase_data = self.mood_patterns['mood_patterns'][cycle_phase]
        
        # Check if there are enough cycles for this phase
        cycles_for_phase = phase_data.get('cycles', 0)
        has_sufficient_data = cycles_for_phase >= self.min_cycles_for_prediction

        
        if not has_sufficient_data:
            return {
                'predicted_mood': 'Need more cycle data',
                'confidence': 0.0,
                'has_sufficient_data': False,
                'cycles_tracked': cycles_for_phase,
                'min_cycles_needed': self.min_cycles_for_prediction
            }
        
        # Get probabilities for this phase
        probs = phase_data['probabilities']
        if not probs:
            return {
                'predicted_mood': 'No mood data for this phase',
                'confidence': 0.0,
                'has_sufficient_data': False,
                'cycles_tracked': total_cycles,
                'min_cycles_needed': self.min_cycles_for_prediction
            }
            
        # Get most likely mood for this phase
        predicted_mood = max(probs.items(), key=lambda x: x[1])
        
        # Adjust confidence based on number of cycles tracked
        confidence_multiplier = min(1.0, cycles_for_phase / 3)  # Full confidence after 3 cycles
        
        return {
            'predicted_mood': predicted_mood[0],
            'confidence': predicted_mood[1] * confidence_multiplier,
            'has_sufficient_data': True,
            'cycles_tracked': total_cycles,
            'min_cycles_needed': self.min_cycles_for_prediction
        }