import 'package:flutter/material.dart';
import 'api_service.dart';
import 'trends_page.dart';
import 'settings_page.dart';
import 'homepage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'util/responsive_size_util.dart';
import 'util/responsive_nav_bar.dart';

// Extension to capitalize first letter of string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class TrackPage extends StatefulWidget {
  final String userId;

  const TrackPage({
    super.key,
    required this.userId,
  });

  @override
  State<TrackPage> createState() => _TrackPageState();
}

class _TrackPageState extends State<TrackPage> {
  final TextEditingController _notesController = TextEditingController();

  double _energyLevel = 5.0;
  final List<String> _selectedMoods = [];
  Map<String, dynamic> _suggestions = {
    'phase': '',
    'diet': [],
    'lifestyle': [],
  };

  TimeOfDay _energyTrackingTime = TimeOfDay.now();
  final List<String> _selectedFoodItems = [];
  final List<String> _selectedLifestyleItems = [];

  Map<String, dynamic> _predictedMood = {};
  Map<String, dynamic> _noteAnalysis = {};
  bool _isAnalyzing = false;

  Timer? _analysisDebouncer;

  final List<String> _moodOptions = [
    'Happy', 'Calm', 'Anxious',
    'Irritable', 'Emotional', 'Motivated',
    'Indifferent', 'Demotivated'
  ];

  int _selectedIndex = 1;
  String _userName = 'User';

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(userId: widget.userId, userName: _userName),
          ),
        );
        break;
      case 1:
        // Already on track page
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TrendsPage(userId: widget.userId),
          ),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SettingsPage(userId: widget.userId),
          ),
        );
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
    _loadMoodPrediction();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _analysisDebouncer?.cancel();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    try {
      final response = await ApiService.getSuggestionsByDate(widget.userId);
      
    
      
      setState(() {
        _suggestions = response;
      });
    } catch (e) {
      print('Error loading suggestions: $e');
    }
  }

  Future<void> _loadMoodPrediction() async {
    try {
      final prediction = await ApiService.predictMood(widget.userId);
      setState(() {
        _predictedMood = prediction;
      });
    } catch (e) {
      print('Error loading mood prediction: $e');
    }
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'User';
    });
  }

  Future<void> _analyzeNotes() async {
    if (_notesController.text.isEmpty || _notesController.text.length < 3) return;

    setState(() => _isAnalyzing = true);
    try {
      // send exactly what the user typed
      final analysis = await ApiService.analyzeNotes(_notesController.text);
      
      // Debug the response
      print('Analysis response: $analysis');
      
      // update with the analysis results
      setState(() {
        _noteAnalysis = analysis;
        _isAnalyzing = false;
      });
      
      // Verify expected fields
      if (analysis.containsKey('sentiment')) {
        print('Sentiment found: ${analysis['sentiment']}');
      } else {
        print('No sentiment found in response');
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      print('Error analyzing notes: $e');
      
      // Show error (debugging)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error analyzing notes: $e')),
      );
    }
  }

  void _debouncedAnalysis() {
    // Cancel previous timer if it exists
    if (_analysisDebouncer?.isActive ?? false) {
      _analysisDebouncer!.cancel();
    }
    
    // Set new timer
    _analysisDebouncer = Timer(const Duration(milliseconds: 800), () {
      if (_notesController.text.length >= 3) {
        _analyzeNotes();
      }
    });
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _energyTrackingTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xCFDB9595), 
              onPrimary: Colors.white, 
              surface: Colors.white,
              onSurface: const Color(0xFFAA8987), 
            ),
            buttonTheme: ButtonThemeData(
              colorScheme: ColorScheme.light(
                primary: const Color(0xCFDB9595),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFAA8987),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _energyTrackingTime = picked;
      });
    }
  }

  Future<void> _saveTracking() async {
    try {
      // Log mood and tracking data
      final moodResponse = await ApiService.logMoodEntry(
        widget.userId,
        _selectedMoods.join(", "),
        _energyLevel.round(),
        '${_notesController.text}\n\nSelected Foods: ${_selectedFoodItems.join(", ")}\nSelected Lifestyle Activities: ${_selectedLifestyleItems.join(", ")}',
      );

      if (moodResponse.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(moodResponse['error'])),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully saved your tracking data!')),
        );
        
        // Reset the form fields
        setState(() {
          _selectedMoods.clear();
          _energyLevel = 5.0;
          _notesController.clear();
          _selectedFoodItems.clear();
          _selectedLifestyleItems.clear();
          _noteAnalysis = {};
        });
        
        // Refresh data
        _loadMoodPrediction();
        _loadSuggestions();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Widget _buildMoodSelection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      padding: EdgeInsets.all(10),
      child: Column(
        children: [
          // First row - first 4 cards
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (index) {
              final mood = _moodOptions[index];
              final isSelected = _selectedMoods.contains(mood);
              return _buildMoodCard(mood, isSelected);
            }),
          ),
          SizedBox(height: 10),
          // Second row - last 4 cards
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (index) {
              final mood = _moodOptions[index + 4]; 
              final isSelected = _selectedMoods.contains(mood);
              return _buildMoodCard(mood, isSelected);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodCard(String mood, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() {
        if (isSelected) {
          _selectedMoods.remove(mood);
        } else {
          _selectedMoods.add(mood);
        }
      }),
      child: Container(
        width: 82, 
        height: 45, 
        decoration: BoxDecoration(
          color: isSelected 
            ? const Color.fromARGB(162, 255, 255, 255) 
            : const Color.fromARGB(138, 173, 80, 91),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2), 
            child: Text(
              mood,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? const Color.fromARGB(138, 173, 80, 91) : const Color.fromARGB(255, 255, 254, 254),
                fontSize: 13,
                fontFamily: 'Afacad',
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnergyTracker() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.35), 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white30, 
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Energy Level',
                style: TextStyle(
                  color: const Color(0xFFAA8987),
                  fontSize: 16,
                  fontFamily: 'Afacad',
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextButton(
                onPressed: _selectTime,
                child: Text(
                  'Time: ${_energyTrackingTime.format(context)}',
                  style: TextStyle(
                    color: const Color(0xFFAA8987),
                    fontSize: 14,
                    fontFamily: 'Afacad',
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xCFDB9595),
              inactiveTrackColor: Colors.white.withOpacity(0.4),
              thumbColor: const Color(0xFFAA8987), 
              overlayColor: const Color(0x29DB9595), 
              trackHeight: 4.0,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.0),
            ),
            child: Slider(
              value: _energyLevel,
              min: 1,
              max: 10,
              divisions: 9,
              label: _energyLevel.round().toString(),
              onChanged: (value) {
                setState(() {
                  _energyLevel = value;
                });
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Low',
                style: TextStyle(
                  color: const Color.fromARGB(255, 122, 101, 101), 
                  fontSize: 12,
                  fontFamily: 'Afacad',
                ),
              ),
              Text(
                'High',
                style: TextStyle(
                  color: const Color.fromARGB(255, 122, 101, 101), 
                  fontSize: 12,
                  fontFamily: 'Afacad',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFoodTracking() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Food & Diet Tracking',
          style: TextStyle(
            color: const Color(0xFFAA8987),
            fontSize: 20,
            fontFamily: 'Afacad',
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recommended Foods for ${_suggestions['phase']} Phase:',
                style: TextStyle(
                  color: const Color.fromARGB(223, 136, 111, 109),
                  fontSize: 16,
                  fontFamily: 'Afacad',
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              if (_suggestions['diet'] != null)
                ..._suggestions['diet'].map((food) => Theme(
                  data: Theme.of(context).copyWith(
                    checkboxTheme: CheckboxThemeData(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: BorderSide(
                        color: const Color.fromARGB(104, 153, 132, 104),
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: CheckboxListTile(
                    title: Text(
                      food,
                      style: TextStyle(
                        color: Color.fromARGB(222, 132, 104, 104),
                        fontSize: 14,
                        fontFamily: 'Afacad',
                      ),
                    ),
                    value: _selectedFoodItems.contains(food),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value ?? false) {
                          _selectedFoodItems.add(food);
                        } else {
                          _selectedFoodItems.remove(food);
                        }
                      });
                    },
                    activeColor: const Color.fromARGB(104, 153, 132, 104),
                    checkColor: Colors.white,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.symmetric(horizontal: 0.0),
                  ),
                )).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestions() {
    if (_suggestions['error'] != null) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lifestyle Choices',
          style: TextStyle(
            color: const Color(0xFFAA8987),
            fontSize: 20,
            fontFamily: 'Afacad',
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recommended for ${_suggestions['phase']} Phase:',
                style: TextStyle(
                  color: const Color.fromARGB(223, 136, 111, 109),
                  fontSize: 16,
                  fontFamily: 'Afacad',
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              if (_suggestions['lifestyle'] != null && _suggestions['lifestyle'].isNotEmpty)
                ..._suggestions['lifestyle'].map((activity) => Theme(
                  data: Theme.of(context).copyWith(
                    checkboxTheme: CheckboxThemeData(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: BorderSide(
                        color: const Color.fromARGB(104, 153, 132, 104),
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: CheckboxListTile(
                    title: Text(
                      activity,
                      style: TextStyle(
                        color: Color.fromARGB(222, 132, 104, 104),
                        fontSize: 14,
                        fontFamily: 'Afacad',
                      ),
                    ),
                    value: _selectedLifestyleItems.contains(activity),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value ?? false) {
                          _selectedLifestyleItems.add(activity);
                        } else {
                          _selectedLifestyleItems.remove(activity);
                        }
                      });
                    },
                    activeColor: const Color.fromARGB(104, 153, 132, 104),
                    checkColor: Colors.white,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.symmetric(horizontal: 0.0),
                  ),
                )).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMoodPrediction() {
    if (_predictedMood.isEmpty) return Container();
    
    bool hasSufficientData = _predictedMood['has_sufficient_data'] ?? false;
    int cyclesTracked = _predictedMood['cycles_tracked'] ?? 0;
    int minCyclesNeeded = _predictedMood['min_cycles_needed'] ?? 1;
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI Mood Prediction',
                style: TextStyle(
                  color: const Color(0xFFAA8987),
                  fontSize: 16,
                  fontFamily: 'Afacad',
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (!hasSufficientData && cyclesTracked > 0)
                TextButton(
                  onPressed: () async {
                    // Show loading dialog
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return Dialog(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFAA8987)),
                                ),
                                SizedBox(width: 20),
                                Text("Training model..."),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                    
                    // Train the model
                    try {
                      await ApiService.trainMoodModel();
                      // Reload predictions
                      await _loadMoodPrediction();
                    } catch (e) {
                      print("Error training model: $e");
                    }
                    
                    // Close the loading dialog
                    Navigator.of(context).pop();
                    
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Model training completed!')),
                    );
                  },
                  child: Text(
                    'Train Model',
                    style: TextStyle(
                      color: const Color(0xFFAA8987),
                      fontSize: 14,
                      fontFamily: 'Afacad',
                    ),
                  ),
                ),
            ],
          ),
          
          if (!hasSufficientData) ...[
            SizedBox(height: 8),
            Text(
              _predictedMood['predicted_mood'] == 'Not enough data'
                  ? 'Your personalized AI mood predictions will appear here after you track at least one complete menstrual cycle.'
                  : 'The AI needs more data to make accurate predictions.',
              style: TextStyle(
                color: Color(0x990D0808),
                fontSize: 14,
                fontFamily: 'Afacad',
              ),
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Color(0xFFAA8987),
                  size: 14,
                ),
                SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'The AI learns your unique patterns across cycles for more accurate predictions.',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Color(0x990D0808),
                      fontSize: 12,
                      fontFamily: 'Afacad',
                    ),
                  ),
                ),
              ],
            ),
            if (cyclesTracked > 0) ...[
              SizedBox(height: 8),
              Text(
                'Progress: $cyclesTracked/$minCyclesNeeded cycle${minCyclesNeeded > 1 ? "s" : ""} tracked',
                style: TextStyle(
                  color: Color(0xFFAA8987),
                  fontSize: 14,
                  fontFamily: 'Afacad',
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_predictedMood['error'] != null) ...[
                SizedBox(height: 4),
                Text(
                  'Error: ${_predictedMood['error']}',
                  style: TextStyle(
                    color: Colors.red[300],
                    fontSize: 12,
                    fontFamily: 'Afacad',
                  ),
                ),
              ],
            ],
          ] else ...[
            SizedBox(height: 8),
            Text(
              'Based on your cycle phase and patterns, you might be feeling:',
              style: TextStyle(
                color: Color(0x990D0808),
                fontSize: 14,
                fontFamily: 'Afacad',
              ),
            ),
            SizedBox(height: 4),
            Text(
              _predictedMood['predicted_mood'] ?? 'Unknown',
              style: TextStyle(
                color: const Color(0xFFAA8987),
                fontSize: 18,
                fontFamily: 'Afacad',
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_predictedMood['confidence'] != null) ...[
              Text(
                'Confidence: ${(_predictedMood['confidence'] * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: Color(0x990D0808),
                  fontSize: 12,
                  fontFamily: 'Afacad',
                ),
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.cyclone,
                    color: Color(0xFFAA8987),
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Based on data from $cyclesTracked menstrual cycle${cyclesTracked > 1 ? "s" : ""}',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Color(0x990D0808),
                      fontSize: 12,
                      fontFamily: 'Afacad',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildNoteAnalysis() {
    if (_noteAnalysis.isEmpty) return Container();

    return Container(
      width: double.infinity, 
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Note Analysis',
            style: TextStyle(
              color: const Color(0xFFAA8987),
              fontSize: 16,
              fontFamily: 'Afacad',
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_noteAnalysis['identified_symptoms'] != null &&
              _noteAnalysis['identified_symptoms'].isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              'Detected Emotions & Symptoms:',
              style: TextStyle(
                color: const Color(0xFFAA8987),
                fontSize: 14,
                fontFamily: 'Afacad',
                fontWeight: FontWeight.w500,
              ),
            ),
            ..._noteAnalysis['identified_symptoms'].entries.map<Widget>((entry) => 
              Padding(
                padding: EdgeInsets.only(left: 16, top: 4),
                child: Text(
                  "${entry.key.toString().capitalize()}: ${entry.value.join(', ')}",
                  style: TextStyle(
                    color: Color(0x990D0808),
                    fontSize: 14,
                    fontFamily: 'Afacad',
                  ),
                ),
              )
            ).toList(),
          ],
          if (_noteAnalysis['key_terms'] != null &&
              (_noteAnalysis['key_terms'] as List).isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              'Key Terms:',
              style: TextStyle(
                color: const Color(0xFFAA8987),
                fontSize: 14,
                fontFamily: 'Afacad',
                fontWeight: FontWeight.w500,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 16, top: 4),
              child: Text(
                (_noteAnalysis['key_terms'] as List).join(', '),
                style: TextStyle(
                  color: Color(0x990D0808),
                  fontSize: 14,
                  fontFamily: 'Afacad',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Initialize the responsive sizing utility
    ResponsiveSizeUtil.init(context);
    
    // Create a responsive navigation bar
    final responsiveNavBar = ResponsiveNavBar(
      selectedIndex: _selectedIndex,
      onItemTapped: _onItemTapped,
    );
    
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/background.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Motif image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              "assets/images/trackMo.png",
              fit: BoxFit.fitWidth,
            ),
          ),
          // Main content
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(ResponsiveSizeUtil.wp(4)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Track Your Day',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ResponsiveSizeUtil.getAdaptiveFontSize(28),
                          fontFamily: 'Afacad',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: ResponsiveSizeUtil.hp(3)),
                    _buildMoodPrediction(),
                    SizedBox(height: ResponsiveSizeUtil.hp(3)),
                    Text(
                      'How are you feeling?',
                      style: TextStyle(
                        color: Color(0xFFAA8987),
                        fontSize: ResponsiveSizeUtil.getAdaptiveFontSize(20),
                        fontFamily: 'Afacad',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: ResponsiveSizeUtil.hp(1)),
                    _buildMoodSelection(),
                    SizedBox(height: ResponsiveSizeUtil.hp(3)),
                    _buildEnergyTracker(),
                    SizedBox(height: ResponsiveSizeUtil.hp(3)),
                    _buildFoodTracking(),
                    SizedBox(height: ResponsiveSizeUtil.hp(3)),
                    _buildSuggestions(),
                    SizedBox(height: ResponsiveSizeUtil.hp(3)),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Add any other notes about your day...',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.35),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Color(0xFFAA8987), width: 1.5),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        suffixIcon: Container(
                          margin: EdgeInsets.all(8),
                          child: _isAnalyzing 
                            ? SizedBox(
                                width: 20, 
                                height: 20, 
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFAA8987)),
                                )
                              )
                            : Icon(Icons.psychology_outlined, color: Color(0xFFAA8987)),
                        ),
                        hintStyle: TextStyle(
                          color: Colors.black54,
                          fontFamily: 'Afacad',
                          fontSize: ResponsiveSizeUtil.getAdaptiveFontSize(16),
                        ),
                      ),
                      style: TextStyle(
                        color: Colors.black87,
                        fontFamily: 'Afacad',
                        fontSize: ResponsiveSizeUtil.getAdaptiveFontSize(16),
                      ),
                      onChanged: (_) => _debouncedAnalysis(),
                    ),
                    SizedBox(height: ResponsiveSizeUtil.hp(2)),
                    _buildNoteAnalysis(),
                    SizedBox(height: ResponsiveSizeUtil.hp(3)),
                    Center(
                      child: Container(
                        width: ResponsiveSizeUtil.wp(36),
                        height: ResponsiveSizeUtil.hp(5),
                        decoration: ShapeDecoration(
                          color: const Color(0xCFDB9595),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: _saveTracking,
                          child: Text(
                            'save',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: ResponsiveSizeUtil.getAdaptiveFontSize(22),
                              fontFamily: 'Afacad',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: ResponsiveSizeUtil.hp(10)), 
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: responsiveNavBar,
    );
  }
}
