import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'track_page.dart';
import 'settings_page.dart';
import 'homepage.dart';

class TrendsPage extends StatefulWidget {
  final String userId;
  
  const TrendsPage({
    super.key,
    required this.userId,
  });

  @override
  State<TrendsPage> createState() => _TrendsPageState();
}

class _TrendsPageState extends State<TrendsPage> with SingleTickerProviderStateMixin {
  // Tab controller
  late TabController _tabController;
  
  // State variables
  bool _isLoading = true;
  int _selectedIndex = 2;
  String _userName = 'User';
  
  // Data variables
  List<Map<String, dynamic>> _cycleData = [];
  String _selectedTimeRange = '3 months';
  final List<String> _timeRanges = ['1 month', '3 months', '6 months', '1 year'];

  // Phase data (will be populated from API)
  Map<String, double> _averageEnergyByPhase = {};
  Map<String, List<String>> _commonCravingsByPhase = {};
  Map<String, List<String>> _commonFeelingsbyPhase = {};
  Map<String, Map<String, int>> _sentimentByPhase = {};
  Map<String, List<String>> _notesSummaryByPhase = {};
  
  // A variable to store the predicted mood from ML model
  String? _predictedMood;
  double _moodConfidence = 0.0;
  bool _hasEnoughMoodData = false;

  @override
  void initState() {
    super.initState();
    _initializeTabController();
    _loadUserInfo();
    _fetchAllData();
    _fetchPredictedMood();
  }
  
  void _initializeTabController() {
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {}); // Refresh UI when tab changes
      }
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
 

  Future<void> _loadUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userName = prefs.getString('userName') ?? 'User';
      });
    } catch (e) {
      // Silently handle error and use default name
      debugPrint('Error loading user info: $e');
    }
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch all data in parallel for better performance
      await Future.wait([
        _fetchCycleData(),
        _fetchEnergyData(),
        _fetchCravingsData(),
        _fetchFeelingsData(),
        _fetchSentimentData(),
        _fetchNotesSummaryData(),
      ]);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading data: $e');
    }
  }

  Future<void> _fetchCycleData() async {
    try {
      final cycles = await ApiService.getCycles(widget.userId);
      

      
      // Filter data based on selected time range
      final DateTime now = DateTime.now();
      final DateTime cutoffDate = _getDateFromTimeRange(now);
      
      final filteredCycles = cycles.where((cycle) {
        try {
          final cycleDate = DateTime.parse(cycle['start_date']);
          return cycleDate.isAfter(cutoffDate);
        } catch (e) {
          // Debug: Print parsing errors
          print('Error parsing date ${cycle['start_date']}: $e');
          return false;
        }
      }).toList();

      setState(() {
        _cycleData = filteredCycles;
      });
    } catch (e) {
      debugPrint('Error fetching cycle data: $e');
    }
  }
  
  Future<void> _fetchEnergyData() async {
    try {
      final energyData = await ApiService.getEnergyLevelsByPhase(
        widget.userId, 
        timeRange: _selectedTimeRange
      );
      
      setState(() {
        _averageEnergyByPhase = energyData;
      });
    } catch (e) {
      debugPrint('Error fetching energy data: $e');
    }
  }
  
  Future<void> _fetchCravingsData() async {
    try {
      final cravingsData = await ApiService.getCravingsByPhase(
        widget.userId, 
        timeRange: _selectedTimeRange
      );
      
      setState(() {
        _commonCravingsByPhase = cravingsData;
      });
    } catch (e) {
      debugPrint('Error fetching cravings data: $e');
    }
  }
  
  Future<void> _fetchFeelingsData() async {
    try {
      final feelingsData = await ApiService.getCommonFeelingsByPhase(
        widget.userId, 
        timeRange: _selectedTimeRange
      );
      
      setState(() {
        _commonFeelingsbyPhase = feelingsData;
      });
    } catch (e) {
      debugPrint('Error fetching feelings data: $e');
    }
  }
  
  Future<void> _fetchSentimentData() async {
    try {
      final sentimentData = await ApiService.getSentimentByPhase(
        widget.userId, 
        timeRange: _selectedTimeRange
      );
      
      setState(() {
        _sentimentByPhase = sentimentData;
      });
    } catch (e) {
      debugPrint('Error fetching sentiment data: $e');
    }
  }
  
  Future<void> _fetchNotesSummaryData() async {
    try {
      final notesSummaryData = await ApiService.getNotesSummaryByPhase(
        widget.userId, 
        timeRange: _selectedTimeRange
      );
      
      setState(() {
        _notesSummaryByPhase = notesSummaryData;
      });
    } catch (e) {
      debugPrint('Error fetching notes summary data: $e');
    }
  }
  
  Future<void> _fetchPredictedMood() async {
    try {
      final moodPrediction = await ApiService.predictMood(widget.userId);
      
      setState(() {
        if (moodPrediction.containsKey('error')) {
          _predictedMood = 'Unavailable';
        } else {
          _predictedMood = moodPrediction['predicted_mood'];
          _moodConfidence = moodPrediction['confidence'] ?? 0.0;
          _hasEnoughMoodData = moodPrediction['has_sufficient_data'] ?? false;
          
          // If we don't have enough data yet
          if (!_hasEnoughMoodData) {
            _predictedMood = 'Need more data';
          }
        }
      });
    } catch (e) {
      debugPrint('Error fetching mood prediction: $e');
      setState(() {
        _predictedMood = 'Unavailable';
      });
    }
  }
  
  DateTime _getDateFromTimeRange(DateTime now) {
    switch (_selectedTimeRange) {
      case '1 month':
        return now.subtract(const Duration(days: 30));
      case '3 months':
        return now.subtract(const Duration(days: 90));
      case '6 months':
        return now.subtract(const Duration(days: 180));
      case '1 year':
        return now.subtract(const Duration(days: 365));
      default:
        return now.subtract(const Duration(days: 90));
    }
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message))
    );
  }

  String _calculateAverageCycleLength() {
    if (_cycleData.isEmpty) return 'N/A';
    
    // Calculate average cycle length from actual data
    double totalDays = 0;
    int validCycles = 0;
    
    for (var cycle in _cycleData) {
      if (cycle['length'] != null) {
        totalDays += cycle['length'] is int ? cycle['length'].toDouble() : cycle['length'];
        validCycles++;
      }
    }
    
    if (validCycles == 0) return 'N/A';
    
    // Round to 1 decimal place
    return (totalDays / validCycles).toStringAsFixed(1);
  }

  String _getMostCommonMood() {
    if (_cycleData.isEmpty) return 'N/A';
    
    // Use the cached prediction if available
    if (_predictedMood != null && _predictedMood!.isNotEmpty) {
      return _predictedMood!;
    }
    
    // Return a placeholder while waiting for the prediction
    return 'Loading...';
  }

  String _getNextPeriodPrediction() {
    if (_cycleData.isEmpty) return 'N/A';
    
    try {
      final lastCycle = _cycleData.last;
      final lastStartDate = DateTime.parse(lastCycle['start_date']);
      final avgLength = _calculateAverageCycleLength();
      
      if (avgLength == 'N/A') return 'Insufficient data';
      
      final nextPeriod = lastStartDate.add(Duration(days: double.parse(avgLength).round()));
      
      // If the predicted date is in the past, add another cycle
      final now = DateTime.now();
      if (nextPeriod.isBefore(now)) {
        return DateFormat('MMM dd, yyyy').format(
          nextPeriod.add(Duration(days: double.parse(avgLength).round()))
        );
      }
      
      return DateFormat('MMM dd, yyyy').format(nextPeriod);
    } catch (e) {
      debugPrint('Error predicting next period: $e');
      return 'Calculating...';
    }
  }
  
  Color _getPhaseColor(String phase) {
    switch (phase) {
      case 'Menstrual': return const Color(0xFFE7968F);
      case 'Follicular': return const Color(0xFFD48F88);
      case 'Ovulation': return const Color(0xFFAA8987);
      case 'Luteal': return const Color(0xFFBBA19F);
      default: return const Color(0xFFBBA19F);
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    
    setState(() {
      _selectedIndex = index;
    });

    try {
      switch (index) {
        case 0:
          _navigateToPage(HomePage(userId: widget.userId, userName: _userName));
          break;
        case 1:
          _navigateToPage(TrackPage(userId: widget.userId));
          break;
        case 2:
          // Already on trends page
          break;
        case 3:
          _navigateToPage(SettingsPage(userId: widget.userId));
          break;
      }
    } catch (e) {
      _showErrorSnackBar('Navigation error: $e');
    }
  }
  
  void _navigateToPage(Widget page) {
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (context) => page)
    );
  }

  
  // -------------------- CYCLE TAB --------------------
  Widget _buildCycleLengthGraph() {
    final Color labelColor = Color(0xFFD4B9A9);
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Cycle Length Trends',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontFamily: 'Afacad',
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 20),
            _buildCycleGraphCard(labelColor),
            SizedBox(height: 20),
            // Moved cycle summary card below the graph
            _buildCycleSummaryCard(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCycleSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x63F1FFFB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Cycle Summary',
            style: TextStyle(
              color: const Color.fromARGB(214, 169, 112, 112),
              fontSize: 18,
              fontFamily: 'Afacad',
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12),
          _buildSummaryRow('Average Cycle Length:', '${_calculateAverageCycleLength()} days'),
          SizedBox(height: 8),
          _buildSummaryRow('Most Common Mood:', _getMostCommonMood()),
          SizedBox(height: 8),
          _buildSummaryRow('Next Period Expected:', _getNextPeriodPrediction()),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value) {
    // Special case for mood prediction to show confidence when available
    if (title == 'Most Common Mood:' && _predictedMood != null && _predictedMood != 'Need more data' 
        && _predictedMood != 'Unavailable' && _predictedMood != 'Loading...' && _moodConfidence > 0) {
      // Show confidence indicator for mood predictions
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: const Color.fromARGB(179, 171, 111, 111),
                  fontSize: 14,
                  fontFamily: 'Afacad',
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: const Color.fromARGB(179, 171, 111, 111),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Afacad',
                ),
              ),
            ],
          ),
          // Add confidence indicator
          SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: _moodConfidence,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _moodConfidence > 0.7 
                        ? Colors.green.withOpacity(0.7)
                        : _moodConfidence > 0.4
                            ? Colors.amber.withOpacity(0.7)
                            : Colors.red.withOpacity(0.7),
                  ),
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 8),
              Text(
                '${(_moodConfidence * 100).toInt()}%',
                style: TextStyle(
                  color: const Color.fromARGB(179, 171, 111, 111),
                  fontSize: 12,
                  fontFamily: 'Afacad',
                ),
              ),
            ],
          ),
        ],
      );
    }
    
    // Standard row for other data
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: const Color.fromARGB(179, 171, 111, 111),
            fontSize: 14,
            fontFamily: 'Afacad',
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: const Color.fromARGB(179, 171, 111, 111),
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'Afacad',
          ),
        ),
      ],
    );
  }
  
  Widget _buildCycleGraphCard(Color labelColor) {
    return Container(
      height: 300,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x63F1FFFB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: _cycleData.isEmpty 
        ? _buildEmptyCycleMessage()
        : _buildCycleLineChart(labelColor),
    );
  }
  
  Widget _buildEmptyCycleMessage() {
    return Center(
      child: Text(
        'No cycle data available for this time range',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }
  
  Widget _buildCycleLineChart(Color labelColor) {
    // Get the min and max values for better scaling
    double minCycleLength = 20.0;
    double maxCycleLength = 40.0;
    
    if (_cycleData.isNotEmpty) {
      minCycleLength = _cycleData.map<double>((cycle) {
        final length = cycle['length'] is num ? (cycle['length'] as num).toDouble() : 28.0;
        return length;
      }).reduce((a, b) => a < b ? a : b);
      
      maxCycleLength = _cycleData.map<double>((cycle) {
        final length = cycle['length'] is num ? (cycle['length'] as num).toDouble() : 28.0;
        return length;
      }).reduce((a, b) => a > b ? a : b);
      
      // Add some padding to the min/max for better visualization
      minCycleLength = (minCycleLength - 2).clamp(20.0, 40.0);
      maxCycleLength = (maxCycleLength + 2).clamp(20.0, 40.0);
    }
    
    return LineChart(
      LineChartData(
        gridData: _buildCycleGridData(),
        titlesData: _buildCycleTitlesData(labelColor),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: _cycleData.isEmpty ? 5 : (_cycleData.length - 1).toDouble(),
        minY: minCycleLength,
        maxY: maxCycleLength,
        lineTouchData: _buildCycleTooltipData(),
        lineBarsData: [_buildCycleLineBarData()],
      ),
    );
  }
  
  FlGridData _buildCycleGridData() {
    return FlGridData(
      show: true,
      drawVerticalLine: true,
      drawHorizontalLine: true,
      horizontalInterval: 5,
      verticalInterval: 1,
      getDrawingHorizontalLine: (value) => FlLine(
        color: Colors.white.withOpacity(0.3),
        strokeWidth: 1,
      ),
      getDrawingVerticalLine: (value) => FlLine(
        color: Colors.white.withOpacity(0.3),
        strokeWidth: 1,
      ),
    );
  }
  
  FlTitlesData _buildCycleTitlesData(Color labelColor) {
    return FlTitlesData(
      show: true,
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            if (value % 1 != 0) return Text('');
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                value.toInt().toString(),
                style: TextStyle(
                  color: labelColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: 5,
          getTitlesWidget: (value, meta) {
            if (value % 5 != 0) return Text('');
            return Text(
              value.toInt().toString(),
              style: TextStyle(color: labelColor, fontSize: 12, fontWeight: FontWeight.w500),
            );
          },
        ),
      ),
    );
  }
  
  LineTouchData _buildCycleTooltipData() {
    return LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        tooltipBgColor: const Color(0xFFBA3E4D).withOpacity(0.8),
        tooltipRoundedRadius: 8,
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map((touchedSpot) {
            return LineTooltipItem(
              '${touchedSpot.y.toInt()} days',
              TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            );
          }).toList();
        },
      ),
    );
  }
  
  LineChartBarData _buildCycleLineBarData() {
    return LineChartBarData(
      spots: _cycleData.isEmpty 
          ? [
              // Sample data
              FlSpot(0, 28),
              FlSpot(1, 29),
              FlSpot(2, 27),
              FlSpot(3, 28),
              FlSpot(4, 30),
              FlSpot(5, 27),
            ]
          : _cycleData.map((cycle) {
              final index = _cycleData.indexOf(cycle);
              final length = cycle['length'] is num ? (cycle['length'] as num).toDouble() : 28.0;
              return FlSpot(index.toDouble(), length);
            }).toList(),
      isCurved: true,
      color: const Color(0xFFBA3E4D),
      barWidth: 4,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: 5,
          color: const Color(0xFFBA3E4D),
          strokeWidth: 2,
          strokeColor: Colors.white,
        ),
      ),
      belowBarData: BarAreaData(show: false),
    );
  }

  // -------------------- PHASE TAB --------------------
  Widget _buildPhaseTrendsSection() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Energy levels by phase
            _buildSectionTitle('Energy Levels by Phase'),
            _buildEnergyLevelChart(),
            SizedBox(height: 20),
            
            // Common cravings by phase
            _buildSectionTitle('Common Cravings'),
            ..._commonCravingsByPhase.entries.map((entry) => 
              _buildPhaseInfoCard(
                entry.key, 
                entry.value,
                _getPhaseColor(entry.key)
              ),
            ),
            SizedBox(height: 20),
            
            // Common feelings by phase
            _buildSectionTitle('How You Feel'),
            ..._commonFeelingsbyPhase.entries.map((entry) => 
              _buildPhaseInfoCard(
                entry.key, 
                entry.value,
                _getPhaseColor(entry.key)
              ),
            ),
            SizedBox(height: 20),

            // Notes summary by phase
            _buildSectionTitle('Your Notes by Phase'),
            ..._notesSummaryByPhase.entries.map((entry) => 
              _buildPhaseInfoCard(
                entry.key, 
                entry.value,
                _getPhaseColor(entry.key)
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: const Color.fromARGB(255, 98, 67, 67).withOpacity(0.9),
          fontSize: 18,
          fontFamily: 'Afacad',
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
  
  Widget _buildPhaseInfoCard(String phase, List<String> items, Color cardColor) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      color: const Color(0x63F1FFFB),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cardColor,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  phase,
                  style: TextStyle(
                    color: cardColor,
                    fontSize: 16,
                    fontFamily: 'Afacad',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: items.map((item) => Chip(
                backgroundColor: cardColor.withOpacity(0.8),
                side: BorderSide.none,
                shadowColor: Colors.transparent,
                label: Text(
                  item,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Afacad',
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEnergyLevelChart() {
    final Color labelColor = Color(0xFFD4B9A9);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 250,
          padding: EdgeInsets.all(16),
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0x63F1FFFB),
            borderRadius: BorderRadius.circular(20),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.center,
              maxY: 10,
              minY: 0,
              groupsSpace: 12,
              barTouchData: BarTouchData(enabled: true),
              titlesData: _buildEnergyChartTitles(labelColor),
              gridData: FlGridData(
                show: true,
                horizontalInterval: 2,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.white.withOpacity(0.1),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                _createEnergyBarGroup(0, _averageEnergyByPhase['Menstrual'] ?? 0, const Color(0xFFE7968F)),
                _createEnergyBarGroup(1, _averageEnergyByPhase['Follicular'] ?? 0, const Color(0xFFD48F88)),
                _createEnergyBarGroup(2, _averageEnergyByPhase['Ovulation'] ?? 0, const Color(0xFFAA8987)),
                _createEnergyBarGroup(3, _averageEnergyByPhase['Luteal'] ?? 0, const Color(0xFFBBA19F)),
              ],
            ),
          ),
        ),
        
        // Add color key for phases below the chart
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPhaseColorKey('M - Menstrual', const Color(0xFFE7968F)),
              SizedBox(width: 12),
              _buildPhaseColorKey('F - Follicular', const Color(0xFFD48F88)),
              SizedBox(width: 12),
              _buildPhaseColorKey('O - Ovulation', const Color(0xFFAA8987)),
              SizedBox(width: 12),
              _buildPhaseColorKey('L - Luteal', const Color(0xFFBBA19F)),
            ],
          ),
        ),
      ],
    );
  }
  
  FlTitlesData _buildEnergyChartTitles(Color labelColor) {
    return FlTitlesData(
      show: true,
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            const phases = ['M', 'F', 'O', 'L'];
            if (value < 0 || value >= phases.length) return Text('');
            
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                phases[value.toInt()],
                style: TextStyle(
                  color: labelColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            if (value % 2 != 0) return Text('');
            return Text(
              value.toInt().toString(),
              style: TextStyle(color: labelColor, fontSize: 13, fontWeight: FontWeight.w500),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildPhaseColorKey(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontFamily: 'Afacad',
          ),
        ),
      ],
    );
  }
  
  BarChartGroupData _createEnergyBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color.withOpacity(0.7),
          width: 22,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }
  
  // -------------------- SENTIMENT TAB --------------------
  Widget _buildSentimentAnalysisSection() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How your emotions trend throughout your cycle:',
              style: TextStyle(
                color: const Color.fromARGB(255, 167, 114, 114),
                fontSize: 16,
                fontFamily: 'Afacad',
              ),
            ),
            SizedBox(height: 16),
            
            // Sentiment charts for each phase
            ..._sentimentByPhase.entries.map((entry) => 
              _buildSentimentChartCard(
                entry.key, 
                entry.value,
                _getPhaseColor(entry.key)
              ),
            ),
            
            SizedBox(height: 20),
            
            // Insights card
            _buildSentimentInsightsCard(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSentimentChartCard(String phase, Map<String, int> sentiments, Color phaseColor) {
    final total = sentiments.values.reduce((a, b) => a + b);
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      color: const Color(0x63F1FFFB),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Phase title row
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: phaseColor,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  phase,
                  style: TextStyle(
                    color: phaseColor,
                    fontSize: 16,
                    fontFamily: 'Afacad',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Sentiment bar chart
            SizedBox(
              height: 30,
              child: Row(
                children: [
                  // Positive section
                  Expanded(
                    flex: sentiments['Positive'] ?? 0,
                    child: _buildSentimentSection(
                      Colors.green.withOpacity(0.7), 
                      BorderRadius.only(
                        topLeft: Radius.circular(4),
                        bottomLeft: Radius.circular(4),
                      ),
                      '${(sentiments['Positive'] ?? 0) * 100 ~/ total}%'
                    ),
                  ),
                  // Neutral section
                  Expanded(
                    flex: sentiments['Neutral'] ?? 0,
                    child: _buildSentimentSection(
                      Colors.grey.withOpacity(0.7), 
                      null,
                      '${(sentiments['Neutral'] ?? 0) * 100 ~/ total}%'
                    ),
                  ),
                  // Negative section
                  Expanded(
                    flex: sentiments['Negative'] ?? 0,
                    child: _buildSentimentSection(
                      Colors.redAccent.withOpacity(0.7), 
                      BorderRadius.only(
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                      '${(sentiments['Negative'] ?? 0) * 100 ~/ total}%'
                    ),
                  ),
                ],
              ),
            ),
            
            // Legend below chart
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _sentimentLegendItem('Positive', Colors.green.withOpacity(0.7)),
                SizedBox(width: 16),
                _sentimentLegendItem('Neutral', Colors.grey.withOpacity(0.7)),
                SizedBox(width: 16),
                _sentimentLegendItem('Negative', Colors.redAccent.withOpacity(0.7)),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSentimentSection(Color color, BorderRadius? borderRadius, String text) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  Widget _sentimentLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: const Color.fromARGB(255, 167, 114, 114),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSentimentInsightsCard() {
    return Card(
      color: const Color(0x63F1FFFB),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Understanding Your Patterns',
              style: TextStyle(
                color: const Color.fromARGB(255, 167, 114, 114),
                fontSize: 16,
                fontFamily: 'Afacad',
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Your sentiment is generally most positive during the Ovulation phase and most variable during the Luteal phase. Tracking consistently will provide more personalized insights.',
              style: TextStyle(color: const Color.fromARGB(255, 167, 114, 114)),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== MAIN UI LAYOUT ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildTabBar(),
                  _buildTabBarView(),
                ],
              ),
            ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }
  
  Widget _buildHeader() {
    return Column(
      children: [
        // Title and time range row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Page title
              Text(
                "Your Trends",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontFamily: 'Afacad',
                  fontWeight: FontWeight.w500,
                ),
              ),
              // Time range selector
              _buildTimeRangeSelector(),
            ],
          ),
        ),
        // Subtitle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Here's what's trending",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Afacad',
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 5),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildTimeRangeSelector() {
    return Row(
      children: [
        Text(
          'Time Range: ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontFamily: 'Afacad',
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: DropdownButton<String>(
            value: _selectedTimeRange,
            dropdownColor: const Color(0xFF76252F),
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Afacad',
            ),
            underline: Container(),
            items: _timeRanges.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null && newValue != _selectedTimeRange) {
                setState(() {
                  _selectedTimeRange = newValue;
                  _isLoading = true; 
                });
                // Fetch all data with the new time range
                _fetchAllData();
              }
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      isScrollable: false,
      labelPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      indicatorWeight: 3.0,
      indicatorColor: const Color(0xFFD4B9A9),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.white,
      tabs: const [
        Tab(text: 'Cycles'),
        Tab(text: 'By Phase'),
        Tab(text: 'Sentiment'),
      ],
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white60,
      labelStyle: TextStyle(
        fontFamily: 'Afacad',
        fontWeight: FontWeight.w500,
        fontSize: 15,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'Afacad',
        fontWeight: FontWeight.w400,
        fontSize: 15,
      ),
    );
  }
  
  Widget _buildTabBarView() {
    return Expanded(
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildCycleLengthGraph(),
          _buildPhaseTrendsSection(),
          _buildSentimentAnalysisSection(),
        ],
      ),
    );
  }
  
  Widget _buildBottomNavBar() {
    return Padding(
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
                _buildNavBarIcon(Icons.home, 0),
                _buildNavBarIcon(Icons.track_changes, 1),
                _buildNavBarIcon(Icons.trending_up, 2),
                _buildNavBarIcon(Icons.settings, 3),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNavBarIcon(IconData icon, int index) {
    final bool isSelected = index == _selectedIndex;
    
    return IconButton(
      icon: Icon(
        icon,
        color: isSelected 
          ? const Color(0xFFAA8987)  // Selected color
          : Colors.black54,          // Unselected color
      ),
      onPressed: () => _onItemTapped(index),
    );
  }
}