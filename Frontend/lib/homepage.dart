import 'package:flutter/material.dart';
import 'api_service.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'track_page.dart';
import 'trends_page.dart';
import 'settings_page.dart';
import 'util/responsive_size_util.dart';

class CyclePhase {
  final String name;
  final int duration;
  final Color color;
  final Color progressColor;

  CyclePhase({
    required this.name,
    required this.duration,
    required this.color,
    required this.progressColor,
  });
}

class CyclePainter extends CustomPainter {
  final List<CyclePhase> phases;
  final String currentPhase;
  final int currentDay;

  CyclePainter({
    required this.phases,
    required this.currentPhase,
    required this.currentDay,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final height = size.height;
    final width = size.width;
    final totalDays = phases.fold(0, (sum, phase) => sum + phase.duration);
    
    // Calculate progress
    final progressWidth = (width * currentDay) / totalDays;
    
    // Background track
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, width, height),
        Radius.circular(height / 2),
      ),
      trackPaint,
    );

    // Phase segments
    double startX = 0;
    for (var phase in phases) {
      final segmentWidth = (phase.duration * width) / totalDays;
      
      // Draw phase segment
      final segmentPaint = Paint()
        ..color = phase.color
        ..style = PaintingStyle.fill;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(startX, 0, segmentWidth, height),
          Radius.circular(height / 2),
        ),
        segmentPaint,
      );
      
      startX += segmentWidth;
    }

    // Progress overlay
    if (progressWidth > 0) {
      final progressPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, progressWidth, height),
          Radius.circular(height / 2),
        ),
        progressPaint,
      );
    }

    // Current day indicator
    final dayX = (width * currentDay) / totalDays;
    final indicatorPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(dayX, height / 2),
      height * 0.8,
      indicatorPaint,
    );

    // Draw day number directly
    final textSpan = TextSpan(
      text: currentDay.toString(),
      style: TextStyle(
        color: Colors.black.withOpacity(0.75),
        fontSize: height * 0.5,
        fontFamily: 'Afacad',
        fontWeight: FontWeight.w600,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        dayX - textPainter.width / 2,
        height / 2 - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CyclePainter oldDelegate) {
    return oldDelegate.currentPhase != currentPhase ||
        oldDelegate.currentDay != currentDay;
  }
}

class HomePage extends StatefulWidget {
  final String userName;
  final String currentPhase;
  final int cycleDay;
  final int daysLeft;
  final String userId;

  const HomePage({
    super.key,
    required this.userName,
    this.currentPhase = "Menstrual",
    this.cycleDay = 1,
    this.daysLeft = 5,
    required this.userId,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedFlowLevel = -1;
  final List<bool> _selectedSymptoms = List.generate(5, (_) => false);
  int _cycleDay = 1;
  String _currentPhase = "Menstrual";
  int _daysLeft = 5;
  
  @override
  void initState() {
    super.initState();
    _loadCycleInfo();
  }

  Future<void> _loadCycleInfo() async {
    try {
      final response = await ApiService.getCurrentCycleInfo(widget.userId);
      
      if (!response.containsKey('error') && mounted) {
        setState(() {
          _cycleDay = response['cycle_day'] ?? widget.cycleDay;
          _currentPhase = response['cycle_phase'] ?? widget.currentPhase;
          _daysLeft = response['days_until_next_period'] ?? widget.daysLeft;
        });
      }
    } catch (e) {
      print('Error loading cycle info: $e');
    }
  }

  String _getSelectedFlowLevel() {
    switch (_selectedFlowLevel) {
      case 0: return "spotting";
      case 1: return "light";
      case 2: return "medium";
      case 3: return "heavy";
      case 4: return "very heavy";
      default: return "";
    }
  }

  List<String> _getSelectedSymptoms() {
    final symptomNames = ["back pain", "cramps", "tender breasts", "headache", "nausea"];
    List<String> symptoms = [];
    for (int i = 0; i < _selectedSymptoms.length; i++) {
      if (_selectedSymptoms[i]) {
        symptoms.add(symptomNames[i]);
      }
    }
    return symptoms;
  }

  Future<void> _saveTracking() async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final flowLevel = _getSelectedFlowLevel();
      final symptoms = _getSelectedSymptoms();

      if (flowLevel.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a flow level')),
        );
        return;
      }

      final periodResponse = await ApiService.logPeriod(
        userId: widget.userId,
        startDate: today,
        flowLevel: flowLevel,
        symptoms: symptoms,
      );

      if (periodResponse.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(periodResponse['error'])),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully saved your tracking data!')),
        );
        
        // Reset selections for new entry
        setState(() {
          _selectedFlowLevel = -1;
          for (int i = 0; i < _selectedSymptoms.length; i++) {
            _selectedSymptoms[i] = false;
          }
        });
        
        // Refresh the main screen with updated cycle information
        if (periodResponse.containsKey('cycle_day') && periodResponse.containsKey('cycle_phase')) {
     
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(
                userName: widget.userName,
                userId: widget.userId,
                cycleDay: periodResponse['cycle_day'],
                currentPhase: periodResponse['cycle_phase'],
                daysLeft: periodResponse.containsKey('days_until_next_period') 
                    ? periodResponse['days_until_next_period'] 
                    : widget.daysLeft,
              ),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              userName: widget.userName,
              userId: widget.userId,
              cycleDay: widget.cycleDay,
              currentPhase: widget.currentPhase,
              daysLeft: widget.daysLeft,
            ),
          ),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TrackPage(userId: widget.userId),
          ),
        );
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
  Widget build(BuildContext context) {
    // Initialize responsive sizing utilities
    ResponsiveSizeUtil.init(context);

    // Define cycle phases
    final cyclePhases = [
      CyclePhase(
        name: "Menstrual",
        duration: 5,
        color: const Color(0xFFE7968F),
        progressColor: const Color(0xFFFF7676),
      ),
      CyclePhase(
        name: "Follicular",
        duration: 7,
        color: const Color(0xFFD48F88),
        progressColor: const Color(0xFFF4A7A7),
      ),
      CyclePhase(
        name: "Ovulation",
        duration: 2,
        color: const Color(0xFFAA8987),
        progressColor: const Color(0xFFD0BBBB),
      ),
      CyclePhase(
        name: "Luteal",
        duration: 14,
        color: const Color(0xFFBBA19F),
        progressColor: const Color(0xFFE3D3D3),
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Background 
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/background.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Top motif image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              "assets/images/cropmot.png",
              fit: BoxFit.fitWidth,
            ),
          ),
          // Main content
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period cycle visualization moved to the top
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: ResponsiveSizeUtil.wp(7)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with user greeting above the cycle
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Hello, ',
                                style: TextStyle(
                                  color: const Color(0xCFDB9595),
                                  fontSize: ResponsiveSizeUtil.getAdaptiveFontSize(28),
                                  fontFamily: 'Afacad',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                text: widget.userName,
                                style: TextStyle(
                                  color: const Color(0xCFDB9595),
                                  fontSize: ResponsiveSizeUtil.getAdaptiveFontSize(28),
                                  fontFamily: 'Afacad',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: ResponsiveSizeUtil.hp(1)),
                      
                        Row(
                          children: [
                            Text(
                              'Day $_cycleDay of your cycle',
                              style: TextStyle(
                                color: const Color(0xFFAA8987),
                                fontSize: ResponsiveSizeUtil.getAdaptiveFontSize(16),
                                fontFamily: 'Afacad',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              '($_daysLeft days until next period)',
                              style: TextStyle(
                                color: const Color(0xFFAA8987),
                                fontSize: ResponsiveSizeUtil.getAdaptiveFontSize(16),
                                fontFamily: 'Afacad',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: ResponsiveSizeUtil.hp(1.5)),
                        SizedBox(
                          width: ResponsiveSizeUtil.wp(86),
                          height: 32,
                          child: CustomPaint(
                            painter: CyclePainter(
                              phases: cyclePhases,
                              currentPhase: _currentPhase,
                              currentDay: _cycleDay,
                            ),
                          ),
                        ),
                        SizedBox(height: ResponsiveSizeUtil.hp(1)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildPhaseLabel('Menstrual', const Color(0xFFE7968F)),
                              _buildPhaseLabel('Follicular', const Color(0xFFD48F88)),
                              _buildPhaseLabel('Ovulation', const Color(0xFFAA8987)),
                              _buildPhaseLabel('Luteal', const Color(0xFFBBA19F)),
                            ],
                          ),
                        ),
                        SizedBox(height: ResponsiveSizeUtil.hp(2)),
                        Container(
                          width: ResponsiveSizeUtil.wp(86),
                          padding: EdgeInsets.all(16),
                          decoration: ShapeDecoration(
                            color: Colors.white.withOpacity(0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Currently in $_currentPhase phase',
                                style: TextStyle(
                                  color: const Color(0x990D0808),
                                  fontSize: ResponsiveSizeUtil.getAdaptiveFontSize(16),
                                  fontFamily: 'Afacad',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                _getPhaseDescription(_currentPhase),
                                style: TextStyle(
                                  color: const Color(0x990D0808),
                                  fontSize: ResponsiveSizeUtil.getAdaptiveFontSize(14),
                                  fontFamily: 'Afacad',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: ResponsiveSizeUtil.hp(3)),
                  // Flow level label
                  Padding(
                    padding: EdgeInsets.only(left: ResponsiveSizeUtil.wp(7)),
                    child: Text(
                      'flow level:',
                      style: TextStyle(
                        color: const Color(0xFFAA8987),
                        fontSize: ResponsiveSizeUtil.getAdaptiveFontSize(20),
                        fontFamily: 'Afacad',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  SizedBox(height: ResponsiveSizeUtil.hp(1)),
                  // Flow level selection
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: ResponsiveSizeUtil.wp(7)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildFlowOption(0, 'spotting', const Color(0x77D48F88)),
                        _buildFlowOption(1, 'light', const Color(0xFCFFC7C3)),
                        _buildFlowOption(2, 'medium', const Color(0x91E7968F)),
                        _buildFlowOption(3, 'heavy', const Color(0xD3DA9494)),
                        _buildFlowOption(4, 'very heavy', const Color(0x999C3A3A)),
                      ],
                    ),
                  ),
                  SizedBox(height: ResponsiveSizeUtil.hp(3)),
                  // Physical symptoms label
                  Padding(
                    padding: EdgeInsets.only(left: ResponsiveSizeUtil.wp(7)),
                    child: Text(
                      'physical symptoms:',
                      style: TextStyle(
                        color: const Color(0xFFAA8987),
                        fontSize: ResponsiveSizeUtil.getAdaptiveFontSize(20),
                        fontFamily: 'Afacad',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  SizedBox(height: ResponsiveSizeUtil.hp(1)),
                  // Physical symptoms selection
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: ResponsiveSizeUtil.wp(7)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSymptomOption(0, 'back pain'),
                        _buildSymptomOption(1, 'cramps'),
                        _buildSymptomOption(2, 'tender breasts'),
                        _buildSymptomOption(3, 'headache'),
                        _buildSymptomOption(4, 'nausea'),
                      ],
                    ),
                  ),
                  SizedBox(height: ResponsiveSizeUtil.hp(4)),
                  // Save button
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
                 
                  SizedBox(height: ResponsiveSizeUtil.hp(15)),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 317,
              height: 64,
              decoration: ShapeDecoration(
                color: Colors.white.withOpacity(0.7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
                shadows: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.home,
                      color: const Color(0xFFAA8987), // Selected color
                    ),
                    onPressed: () => _onItemTapped(0),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.track_changes,
                      color: Colors.black54, // Unselected color
                    ),
                    onPressed: () => _onItemTapped(1),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.trending_up,
                      color: Colors.black54, // Unselected color
                    ),
                    onPressed: () => _onItemTapped(2),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.settings,
                      color: Colors.black54, // Unselected color
                    ),
                    onPressed: () => _onItemTapped(3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowOption(int index, String label, Color backgroundColor) {
    final isSelected = _selectedFlowLevel == index;
    
    Color displayColor = backgroundColor;
    
    
    if (isSelected) {
      if (index == 1) { // Light flow
        displayColor = const Color(0xFFFFB4AC); 
      } else if (index == 3) { // Heavy flow
        displayColor = const Color(0xFF9C6B6B); 
      } else {
        displayColor = backgroundColor.withOpacity(1.0); 
      }
      
      // Add a selection border
      return GestureDetector(
        onTap: () => setState(() => _selectedFlowLevel = index),
        child: Column(
          children: [
            Container(
              width: ResponsiveSizeUtil.wp(11), 
              height: ResponsiveSizeUtil.wp(11), 
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.8),
                  width: 2.0,
                ),
              ),
              child: Center(
                child: SizedBox(
                  width: ResponsiveSizeUtil.wp(10), 
                  height: ResponsiveSizeUtil.wp(10),
                  child: CustomPaint(
                    painter: CircleFlowPainter(color: displayColor),
                  ),
                ),
              ),
            ),
            SizedBox(height: 4),
            SizedBox(
              width: ResponsiveSizeUtil.wp(12),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0x990D0808),
                  fontSize: ResponsiveSizeUtil.getAdaptiveFontSize(12),
                  fontFamily: 'Afacad',
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // Unselected state
    return GestureDetector(
      onTap: () => setState(() => _selectedFlowLevel = index),
      child: Column(
        children: [
          SizedBox(
            width: ResponsiveSizeUtil.wp(11), 
            height: ResponsiveSizeUtil.wp(11), 
            child: CustomPaint(
              painter: CircleFlowPainter(color: backgroundColor),
            ),
          ),
          SizedBox(height: 4),
          SizedBox(
            width: ResponsiveSizeUtil.wp(12),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0x990D0808),
                fontSize: ResponsiveSizeUtil.getAdaptiveFontSize(12),
                fontFamily: 'Afacad',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomOption(int index, String label) {
    final isSelected = _selectedSymptoms[index];
    
    // Fixed container size for all symptoms
    return GestureDetector(
      onTap: () => setState(() => _selectedSymptoms[index] = !isSelected),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: ResponsiveSizeUtil.wp(11),
            height: ResponsiveSizeUtil.wp(11),
            decoration: ShapeDecoration(
              color: isSelected ? const Color(0x77D48F88) : Colors.white.withOpacity(0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            alignment: Alignment.center,
          ),
          const SizedBox(height: 4),
          
          Container(
            height: ResponsiveSizeUtil.hp(5.5), 
            width: ResponsiveSizeUtil.wp(16), 
            alignment: Alignment.topCenter,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.visible, 
              style: TextStyle(
                color: const Color(0x990D0808),
                fontSize: ResponsiveSizeUtil.getAdaptiveFontSize(11),
                fontFamily: 'Afacad',
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseLabel(String label, Color color) {
    return Column(
      children: [
        Container(
          width: ResponsiveSizeUtil.wp(3.5),
          height: ResponsiveSizeUtil.wp(3.5),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: const Color(0x990D0808),
            fontSize: ResponsiveSizeUtil.getAdaptiveFontSize(12),
            fontFamily: 'Afacad',
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  String _getPhaseDescription(String phase) {
    switch (phase) {
      case 'Menstrual':
        return 'During this phase, your body sheds the uterine lining. You may experience cramps, mood changes, and fatigue.';
      case 'Follicular':
        return 'Your body is preparing for ovulation. Energy levels start to rise, and you may feel more creative and positive.';
      case 'Ovulation':
        return 'This is when an egg is released. You may notice increased energy, improved mood, and peak fertility.';
      case 'Luteal':
        return 'After ovulation, your body prepares either for pregnancy or menstruation. You may experience PMS symptoms during this phase.';
      default:
        return 'Tracking your cycle helps you understand your body better.';
    }
  }
}

// Custom painter for flow level selection
class CircleFlowPainter extends CustomPainter {
  final Color color;

  CircleFlowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;


    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      paint,
    );
  }

  @override
  bool shouldRepaint(CircleFlowPainter oldDelegate) => color != oldDelegate.color;
}