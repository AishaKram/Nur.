import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'track_page.dart';
import 'trends_page.dart';
import 'homepage.dart';

class SettingsPage extends StatefulWidget {
  final String? userId;
  
  const SettingsPage({super.key, this.userId});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _userId = '';
  String _userName = '';
  
  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }
  
  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = widget.userId ?? prefs.getString('userId') ?? '';
      _userName = prefs.getString('userName') ?? 'User';
    });
  }
  
  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              userId: _userId,
              userName: _userName,
            ),
          ),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TrackPage(userId: _userId),
          ),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TrendsPage(userId: _userId),
          ),
        );
        break;
      case 3:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
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
          // Motif
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              "assets/images/loginMo.png",
              fit: BoxFit.fitWidth,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                //Settings title 
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontFamily: 'Afacad',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _buildSettingsList(),
                ),
              ],
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
                    icon: const Icon(
                      Icons.home,
                      color: Colors.black54, // Unselected color
                    ),
                    onPressed: () => _onItemTapped(0),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.track_changes,
                      color: Colors.black54, // Unselected color
                    ),
                    onPressed: () => _onItemTapped(1),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.trending_up,
                      color: Colors.black54, // Unselected color
                    ),
                    onPressed: () => _onItemTapped(2),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.settings,
                      color: Color(0xFFAA8987), // Selected color
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
  
  Widget _buildSettingsList() {
    return ListView(
      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      children: [
        _buildProfileSettings(),
        SizedBox(height: 16.0),
        _buildCycleSettings(),
        SizedBox(height: 16.0),
        _buildHelpAndSupport(),
        SizedBox(height: 16.0),
        _buildSignOutButton(),
      ],
    );
  }
  
  // Section card builder
  Widget _buildSectionCard(Widget child, {required Color color}) {
    return Card(
      color: color.withOpacity(0.63), 
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontFamily: 'Afacad',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // User Profile Settings Section
  Widget _buildProfileSettings() {
    return _buildSectionCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Profile Settings'),
          
          // Username setting
          _buildSettingItem(
            icon: Icons.person,
            title: 'Change username',
            onTap: _showUsernameDialog,
          ),
          
          Divider(color: Colors.white30),
          
          // Change password
          _buildSettingItem(
            icon: Icons.lock,
            title: 'Change password',
            onTap: _showChangePasswordDialog,
          ),
        ],
      ),
      color: const Color.fromARGB(255, 150, 98, 93), // Menstrual 
    );
  }

  // Cycle Settings Section
  Widget _buildCycleSettings() {
    return _buildSectionCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Cycle Settings'),
          
          // Average cycle length
          _buildSettingItem(
            icon: Icons.calendar_month,
            title: 'Average cycle length',
            onTap: () => _showCycleLengthDialog('cycle'),
          ),
          
          Divider(color: Colors.white30),
          
          // Period length
          _buildSettingItem(
            icon: Icons.calendar_today,
            title: 'Average period length',
            onTap: () => _showCycleLengthDialog('period'),
          ),
        ],
      ),
      color: const Color(0xFFD48F88), // Follicular 
    );
  }

  // Help and Support Section
  Widget _buildHelpAndSupport() {
    return _buildSectionCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Help & Support'),
          
          // FAQs
          _buildSettingItem(
            icon: Icons.help,
            title: 'FAQs',
            onTap: _showFAQs,
          ),
          
          Divider(color: Colors.white30),
          
          // About
          _buildSettingItem(
            icon: Icons.info,
            title: 'About',
            onTap: _showAbout,
          ),
        ],
      ),
      color: const Color(0xFFAA8987), // Ovulation
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'Afacad',
          fontSize: 16,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.white70),
      onTap: onTap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildSignOutButton() {
    return TextButton(
      onPressed: _handleSignOut,
      style: TextButton.styleFrom(
        backgroundColor: Color(0xFFBA3E4D).withOpacity(0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.symmetric(vertical: 12.0),
      ),
      child: Text(
        'Sign Out',
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'Afacad',
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Dialog for username change
  Future<void> _showUsernameDialog() async {
    final TextEditingController nameController = TextEditingController(text: _userName);
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF76252F),
        title: Text(
          'Change Username',
          style: TextStyle(color: Colors.white, fontFamily: 'Afacad'),
        ),
        content: TextField(
          controller: nameController,
          style: TextStyle(color: Colors.white, fontFamily: 'Afacad'),
          decoration: InputDecoration(
            hintText: 'Enter new username',
            hintStyle: TextStyle(color: Colors.white60, fontFamily: 'Afacad'),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white70),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white70, fontFamily: 'Afacad'),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await _updateUsername(nameController.text);
                Navigator.pop(context);
              }
            },
            child: Text(
              'Save',
              style: TextStyle(color: Colors.white, fontFamily: 'Afacad'),
            ),
          ),
        ],
      ),
    );
  }

  // Dialog for password change
  Future<void> _showChangePasswordDialog() async {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    bool passwordsMatch = true;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Color(0xFF76252F),
            title: Text(
              'Change Password',
              style: TextStyle(color: Colors.white, fontFamily: 'Afacad'),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  style: TextStyle(color: Colors.white, fontFamily: 'Afacad'),
                  decoration: InputDecoration(
                    hintText: 'Current password',
                    hintStyle: TextStyle(color: Colors.white60, fontFamily: 'Afacad'),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(height: 16.0),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  style: TextStyle(color: Colors.white, fontFamily: 'Afacad'),
                  decoration: InputDecoration(
                    hintText: 'New password',
                    hintStyle: TextStyle(color: Colors.white60, fontFamily: 'Afacad'),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(height: 16.0),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  style: TextStyle(color: Colors.white, fontFamily: 'Afacad'),
                  decoration: InputDecoration(
                    hintText: 'Confirm new password',
                    hintStyle: TextStyle(color: Colors.white60, fontFamily: 'Afacad'),
                    errorText: !passwordsMatch ? 'Passwords don\'t match' : null,
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    errorBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.redAccent),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      passwordsMatch = value == newPasswordController.text;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70, fontFamily: 'Afacad'),
                ),
              ),
              TextButton(
                onPressed: () async {
                  if (newPasswordController.text == confirmPasswordController.text &&
                      currentPasswordController.text.isNotEmpty &&
                      newPasswordController.text.isNotEmpty) {
                    await _updatePassword(
                      currentPasswordController.text,
                      newPasswordController.text
                    );
                    Navigator.pop(context);
                  } else {
                    setState(() {
                      passwordsMatch = newPasswordController.text == confirmPasswordController.text;
                    });
                  }
                },
                child: Text(
                  'Save',
                  style: TextStyle(color: Colors.white, fontFamily: 'Afacad'),
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  // Dialog for cycle length settings
  Future<void> _showCycleLengthDialog(String type) async {
    final settings = await ApiService.getUserSettings(_userId);
    int value = type == 'cycle' 
        ? (settings['average_cycle_length'] as int? ?? 28) 
        : (settings['average_period_length'] as int? ?? 5);
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Color(0xFF76252F),
            title: Text(
              type == 'cycle' ? 'Average Cycle Length' : 'Average Period Length',
              style: TextStyle(color: Colors.white, fontFamily: 'Afacad'),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$value days',
                  style: TextStyle(
                    color: Colors.white, 
                    fontFamily: 'Afacad',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove_circle, color: Colors.white),
                      onPressed: () {
                        if ((type == 'cycle' && value > 21) || (type == 'period' && value > 1)) {
                          setState(() {
                            value--;
                          });
                        }
                      },
                    ),
                    SizedBox(width: 16.0),
                    IconButton(
                      icon: Icon(Icons.add_circle, color: Colors.white),
                      onPressed: () {
                        if ((type == 'cycle' && value < 45) || (type == 'period' && value < 10)) {
                          setState(() {
                            value++;
                          });
                        }
                      },
                    ),
                  ],
                ),
                Text(
                  type == 'cycle' 
                      ? 'Normal cycle length is between 21-45 days' 
                      : 'Normal period length is between 1-10 days',
                  style: TextStyle(color: Colors.white70, fontFamily: 'Afacad'),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70, fontFamily: 'Afacad'),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final cycleLength = type == 'cycle' ? value : (settings['average_cycle_length'] as int? ?? 28);
                  final periodLength = type == 'period' ? value : (settings['average_period_length'] as int? ?? 5);
                  
                  await _updateCycleSettings(cycleLength, periodLength);
                  Navigator.pop(context);
                },
                child: Text(
                  'Save',
                  style: TextStyle(color: Colors.white, fontFamily: 'Afacad'),
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  // Help & Support methods
  void _showFAQs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF76252F),
        title: Text(
          'Frequently Asked Questions',
          style: TextStyle(color: Colors.white, fontFamily: 'Afacad'),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFaqItem('How accurate is period prediction?', 
                'Period predictions get more accurate the more you track your cycles. Predictions become more accurate after tracking 3+ cycles.'),
              _buildFaqItem('How do I track symptoms?', 
                'Go to the Track tab and select the current date. You can log your period, symptoms, mood, and more there.'),
              _buildFaqItem('Can I export my data?', 
                'Currently, data export is not available but we plan to add this feature soon.'),
              _buildFaqItem('Is my data private?', 
                'Yes, your data is securely stored and not shared with any third parties without your consent.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: Colors.white, fontFamily: 'Afacad'),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFaqItem(String question, String answer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Afacad',
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4.0),
        Text(
          answer,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontFamily: 'Afacad',
          ),
        ),
        SizedBox(height: 16.0),
      ],
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF76252F),
        title: Text(
          'About',
          style: TextStyle(color: Colors.white, fontFamily: 'Afacad'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Female Health App',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Afacad',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8.0),
            Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.white70, fontFamily: 'Afacad'),
            ),
            SizedBox(height: 16.0),
            Text(
              'This app helps you track your periods, symptoms, and mood to better understand your cycle patterns.',
              style: TextStyle(color: Colors.white, fontFamily: 'Afacad'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: Colors.white, fontFamily: 'Afacad'),
            ),
          ),
        ],
      ),
    );
  }

  // API-related methods
  Future<void> _updateUsername(String newName) async {
    if (_userId.isNotEmpty) {
      final response = await ApiService.updateUserName(_userId, newName);
      
      if (response['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userName', newName);
        
        setState(() {
          _userName = newName;
        });
        
        _showSuccessMessage('Username updated successfully');
      } else {
        _showErrorMessage(response['error'] ?? 'Failed to update username');
      }
    } else {
      _showErrorMessage('User ID not found. Please login again.');
    }
  }

  Future<void> _updatePassword(String currentPassword, String newPassword) async {
    if (_userId.isNotEmpty) {
      final response = await ApiService.changePassword(_userId, currentPassword, newPassword);
      
      if (response['success'] == true) {
        _showSuccessMessage('Password changed successfully');
      } else {
        _showErrorMessage(response['error'] ?? 'Failed to change password');
      }
    } else {
      _showErrorMessage('User ID not found. Please login again.');
    }
  }

  Future<void> _updateCycleSettings(int cycleLength, int periodLength) async {
    if (_userId.isNotEmpty) {
      final response = await ApiService.updateCycleSettings(
        _userId, 
        cycleLength,
        periodLength
      );
      
      if (response['success'] == true) {
        _showSuccessMessage('Cycle settings updated successfully');
      } else {
        _showErrorMessage(response['error'] ?? 'Failed to update cycle settings');
      }
    } else {
      _showErrorMessage('User ID not found. Please login again.');
    }
  }

  void _handleSignOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    await prefs.remove('userName');
    
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}