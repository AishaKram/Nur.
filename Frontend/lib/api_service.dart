import 'dart:convert';
import 'package:http/http.dart' as http;
import 'userPreferences.dart';

class ApiService {
  static const String baseUrl = "http://127.0.0.1:5000";  
  static Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {
      var response = await http.post(
        Uri.parse('http://127.0.0.1:5000/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      var data = jsonDecode(response.body);
      if (data['token'] != null) {
        await UserPreferences.saveToken(data['token']);
      }
      return data;
    } catch (e) {
      return {"error": "Connection error"};
    }
  }

  static Future<Map<String, dynamic>> resetPassword(String email) async {
    final url = Uri.parse("$baseUrl/reset-password");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    return jsonDecode(response.body);
  }

  // Reset password confirmation - verifies the oob code and sets the new password
  static Future<Map<String, dynamic>> confirmPasswordReset(String oobCode, String newPassword) async {
    try {
      var response = await http.post(
        Uri.parse('$baseUrl/confirm-password-reset'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "oob_code": oobCode,
          "new_password": newPassword
        }),
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      print("Error confirming password reset: ${e.toString()}");
      return {"error": "Failed to reset password", "success": false};
    }
  }

  static Future<Map<String, dynamic>> logPeriod({
    required String userId,
    required String startDate,
    required String flowLevel,
    required List<String> symptoms,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/log_period");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "start_date": startDate,
          "flow_level": flowLevel,
          "symptoms": symptoms,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {"error": "Connection error: ${e.toString()}"};
    }
  }

  static Future<List<Map<String, dynamic>>> getCycles(String userId) async {
    try {
      var response = await http.get(
        Uri.parse('$baseUrl/get_cycles/$userId'),
        headers: {"Content-Type": "application/json"},
      );
      var data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['cycles']);
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getMoodEntries(String userId) async {
    try {
      var response = await http.get(
        Uri.parse('$baseUrl/get_moods/$userId'),
        headers: {"Content-Type": "application/json"},
      );
      var data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['moods']);
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> logMoodEntry(
    String userId,
    String mood,
    int energyLevel,
    String notes,
  ) async {
    try {
      var response = await http.post(
        Uri.parse('$baseUrl/log_mood'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "mood": mood,
          "energy_level": energyLevel,
          "notes": notes,
          "date": DateTime.now().toIso8601String(),
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"error": "Failed to log mood entry"};
    }
  }

  static Future<List<Map<String, dynamic>>> getSuggestionsByPhase(String phase) async {
    try {
      var response = await http.get(
        Uri.parse('$baseUrl/get_suggestions/$phase'),
        headers: {"Content-Type": "application/json"},
      );
      var data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['suggestions']);
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getSuggestionsByDate(String userId) async {
    try {
      var response = await http.get(
        Uri.parse('$baseUrl/get_suggestions_by_date/$userId'),
        headers: {"Content-Type": "application/json"},
      );
      
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        print('Suggestions API response: $data'); // Debug log
        
        // Handle different response structures to ensure always get the recommendations
        if (data['suggestions'] != null && data['phase'] != null) {
          return {
            'phase': data['phase'],
            'diet': data['suggestions']['diet'] ?? [],
            'lifestyle': data['suggestions']['lifestyle'] ?? [],
          };
        } else if (data['error'] != null) {
          return {
            'phase': 'Unknown',
            'diet': [],
            'lifestyle': [],
            'error': data['error']
          };
        } else {
          // Fallback to ensure we always have some structure
          return {
            'phase': data['phase'] ?? 'Unknown',
            'diet': data['diet'] ?? [],
            'lifestyle': data['lifestyle'] ?? [],
          };
        }
      } else {
        print('API error: ${response.statusCode} - ${response.body}');
        return {
          'phase': 'Unknown',
          'diet': [],
          'lifestyle': [],
          'error': 'Failed to load suggestions'
        };
      }
    } catch (e) {
      print('Exception in getSuggestionsByDate: $e');
      return {
        'phase': 'Unknown',
        'diet': [],
        'lifestyle': [],
        'error': e.toString()
      };
    }
  }

  // ML-related endpoints
  static Future<Map<String, dynamic>> predictMood(String userId) async {
    try {
      var response = await http.get(
        Uri.parse('$baseUrl/ml/predict_mood/$userId'),
        headers: {"Content-Type": "application/json"},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {
        "error": "Failed to predict mood",
        "predicted_mood": "Unknown",
        "confidence": 0.0
      };
    }
  }

  static Future<Map<String, dynamic>> analyzeNotes(String text) async {
    try {
      var response = await http.post(
        Uri.parse('$baseUrl/ml/analyze_notes'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"text": text}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {
        "error": "Failed to analyze notes",
        "sentiment": "UNKNOWN",
        "sentiment_score": 0.0,
        "identified_symptoms": {}
      };
    }
  }

  static Future<Map<String, dynamic>> trainMoodModel() async {
    try {
      var response = await http.post(
        Uri.parse('$baseUrl/ml/train_mood_model'),
        headers: {"Content-Type": "application/json"},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {
        "error": "Failed to train model",
        "accuracy": 0.0,
        "samples": 0
      };
    }
  }


  static Future<Map<String, dynamic>> getCurrentCycleInfo(String userId) async {
    try {
      var response = await http.get(
        Uri.parse('$baseUrl/get_current_cycle_info/$userId'),
        headers: {"Content-Type": "application/json"},
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      return {
        "error": "Failed to get cycle information",
        "cycle_day": 1,
        "cycle_phase": "Menstrual",
        "days_until_next_period": 28
      };
    }
  }
  
  // New methods for trends page phase-based data
  
  static Future<Map<String, double>> getEnergyLevelsByPhase(String userId, {String timeRange = "3 months"}) async {
    try {
      var response = await http.get(
        Uri.parse('$baseUrl/get_energy_levels_by_phase/$userId?time_range=$timeRange'),
        headers: {"Content-Type": "application/json"},
      );
      
      var data = jsonDecode(response.body);
      var energyLevels = Map<String, double>.from(data['energy_levels']);
      return energyLevels;
    } catch (e) {
      // Return default values in case of error
      return {
        "Menstrual": 4.2,
        "Follicular": 7.6,
        "Ovulation": 8.3,
        "Luteal": 5.8
      };
    }
  }
  
  static Future<Map<String, List<String>>> getCravingsByPhase(String userId, {String timeRange = "3 months"}) async {
    try {
      var response = await http.get(
        Uri.parse('$baseUrl/get_cravings_by_phase/$userId?time_range=$timeRange'),
        headers: {"Content-Type": "application/json"},
      );
      
      var data = jsonDecode(response.body);
      Map<String, dynamic> rawData = data['cravings'];
      Map<String, List<String>> result = {};
      
      rawData.forEach((phase, cravingsList) {
        result[phase] = List<String>.from(cravingsList);
      });
      
      return result;
    } catch (e) {
      // Return default values in case of error
      return {
        "Menstrual": ["Chocolate", "Salt", "Carbs"],
        "Follicular": ["Fresh fruits", "Vegetables", "Protein"],
        "Ovulation": ["Light meals", "Fresh foods", "Proteins"],
        "Luteal": ["Sweets", "Carbohydrates", "Comfort food"]
      };
    }
  }
  
  static Future<Map<String, List<String>>> getCommonFeelingsByPhase(String userId, {String timeRange = "3 months"}) async {
    try {
      var response = await http.get(
        Uri.parse('$baseUrl/get_feelings_by_phase/$userId?time_range=$timeRange'),
        headers: {"Content-Type": "application/json"},
      );
      
      var data = jsonDecode(response.body);
      Map<String, dynamic> rawData = data['feelings'];
      Map<String, List<String>> result = {};
      
      rawData.forEach((phase, feelingsList) {
        result[phase] = List<String>.from(feelingsList);
      });
      
      return result;
    } catch (e) {
      // Return default values in case of error
      return {
        "Menstrual": ["Tired", "Reflective", "Intuitive"],
        "Follicular": ["Energetic", "Social", "Creative"],
        "Ovulation": ["Confident", "Outgoing", "Communicative"],
        "Luteal": ["Focused", "Nesting", "Anxious"]
      };
    }
  }
  
  static Future<Map<String, List<String>>> getNotesSummaryByPhase(String userId, {String timeRange = "3 months"}) async {
    try {
      var response = await http.get(
        Uri.parse('$baseUrl/get_notes_summary_by_phase/$userId?time_range=$timeRange'),
        headers: {"Content-Type": "application/json"},
      );
      
      var data = jsonDecode(response.body);
      Map<String, dynamic> rawData = data['notes_summary'];
      Map<String, List<String>> result = {};
      
      rawData.forEach((phase, summaryList) {
        result[phase] = List<String>.from(summaryList);
      });
      
      return result;
    } catch (e) {
      // Return default values in case of error
      return {
        "Menstrual": ["Rest needed", "Craving comfort", "Self-care important"],
        "Follicular": ["More social", "Productive days", "Starting new projects"],
        "Ovulation": ["High energy", "Socially active", "Feeling attractive"],
        "Luteal": ["Mood swings", "Nesting instinct", "Need for quiet time"]
      };
    }
  }
  
  static Future<Map<String, Map<String, int>>> getSentimentByPhase(String userId, {String timeRange = "3 months"}) async {
    try {
      var response = await http.get(
        Uri.parse('$baseUrl/get_sentiment_by_phase/$userId?time_range=$timeRange'),
        headers: {"Content-Type": "application/json"},
      );
      
      var data = jsonDecode(response.body);
      Map<String, dynamic> rawData = data['sentiment'];
      Map<String, Map<String, int>> result = {};
      
      rawData.forEach((phase, sentimentData) {
        result[phase] = Map<String, int>.from(sentimentData);
      });
      
      return result;
    } catch (e) {
      // Return default values in case of error
      return {
        "Menstrual": {"Positive": 30, "Neutral": 50, "Negative": 20},
        "Follicular": {"Positive": 70, "Neutral": 20, "Negative": 10},
        "Ovulation": {"Positive": 80, "Neutral": 15, "Negative": 5},
        "Luteal": {"Positive": 40, "Neutral": 30, "Negative": 30}
      };
    }
  }

  // User settings related methods
  static Future<Map<String, dynamic>> updateUserName(String userId, String newName) async {
    try {
      var response = await http.put(
        Uri.parse('$baseUrl/update_user_name/$userId'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"name": newName}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"error": "Failed to update user name", "success": false};
    }
  }

  static Future<Map<String, dynamic>> changePassword(String userId, String currentPassword, String newPassword) async {
    try {
      var response = await http.post(
        Uri.parse('$baseUrl/change_password'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "current_password": currentPassword,
          "new_password": newPassword,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"error": "Failed to change password", "success": false};
    }
  }

  static Future<Map<String, dynamic>> updateCycleSettings(
    String userId, 
    int averageCycleLength, 
    int averagePeriodLength
  ) async {
    try {
      var response = await http.put(
        Uri.parse('$baseUrl/update_cycle_settings/$userId'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "average_cycle_length": averageCycleLength,
          "average_period_length": averagePeriodLength,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"error": "Failed to update cycle settings", "success": false};
    }
  }

  static Future<Map<String, dynamic>> getUserSettings(String userId) async {
    try {
      var response = await http.get(
        Uri.parse('$baseUrl/user_settings/$userId'),
        headers: {"Content-Type": "application/json"},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {
        "error": "Failed to get user settings",
        "name": "User",
        "email": "",
        "average_cycle_length": 28, 
        "average_period_length": 5
      };
    }
  }
}