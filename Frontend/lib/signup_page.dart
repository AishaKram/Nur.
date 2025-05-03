import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Controllers for text fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isPasswordVisible = false;  // Add password visibility state

  // Controllers for date fields (Date Pickers)
  final TextEditingController dobController = TextEditingController();
  final TextEditingController lastPeriodController = TextEditingController();

  // Occupation Dropdown
  String selectedOccupation = 'Employed'; // Default selected value
  final List<String> occupations = ['Employed', 'Student', 'Freelance', 'Unemployed'];

  // Checkbox state for terms acceptance
  bool termsAccepted = false;

  // Function to show Date Picker
  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('en', 'GB'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFFE4B8D2), // Header background
              onPrimary: Colors.white, // Header text
              onSurface: Color(0xFF938182), // Calendar text
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFFE3A2B3), // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    setState(() {
      if (pickedDate != null) {
        controller.text = DateFormat('dd/MM/yyyy').format(pickedDate);
      }
    });
    }

  String formatDobForBackend(String dob) {
    try {
      DateTime parsedDob = DateFormat('dd/MM/yyyy').parseStrict(dob);
      return DateFormat('dd-MM-yyyy').format(parsedDob); // Using hyphens instead of slashes for backend
    } catch (e) {
      print('Invalid DOB format: $dob');
      return ''; // Return empty string if the DOB is invalid
    }
  }

  String formatLastPeriodForBackend(String lastPeriod) {
    try {
      DateTime parsedDate = DateFormat('dd/MM/yyyy').parseStrict(lastPeriod);
      return DateFormat('yyyy-MM-dd').format(parsedDate); // Using hyphens instead of slashes for backend
    } catch (e) {
      print('Invalid date format for last period: $lastPeriod');
      return ''; // Return empty string if the date is invalid
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Dialog(
        backgroundColor: const Color(0xE6F1FFFB), // Increased opacity to 90%
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.black.withOpacity(0.8),
                  fontSize: 24,
                  fontFamily: 'Afacad',
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF6F5051), // Made fully opaque
                  fontSize: 14,
                  fontFamily: 'Afacad',
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  "OK",
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.8),
                    fontFamily: 'Afacad',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Dialog(
        backgroundColor: const Color(0xE6F1FFFB),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Privacy Policy',
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.8),
                    fontSize: 24,
                    fontFamily: 'Afacad',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Last Updated: April 19, 2025\n\n'
                  'Data Collection and Use\n'
                  'We collect and process the following types of personal information:\n'
                  '• Personal details (name, date of birth)\n'
                  '• Health-related information (menstrual cycle data, symptoms, mood)\n'
                  '• Account information (email, encrypted password)\n'
                  '• Usage data (app interactions, preferences)\n\n'
                  'Data Protection\n'
                  'We implement robust security measures to protect your sensitive health data:\n'
                  '• Encryption of all personal and health-related data\n'
                  '• Secure authentication systems\n'
                  '• Regular security audits and updates\n'
                  '• Restricted access to authorized personnel only\n\n'
                  'Data Sharing\n'
                  'We never share your personal health data with third parties without your explicit consent, except:\n'
                  '• When required by law\n'
                  '• For app functionality (with anonymous aggregation)\n'
                  '• With your healthcare providers (only with your permission)\n\n'
                  'Your Rights\n'
                  'You have the right to:\n'
                  '• Access your personal data\n'
                  '• Request data correction or deletion\n'
                  '• Export your data\n'
                  '• Withdraw consent at any time\n\n'
                  'Data Retention\n'
                  'We retain your data for as long as your account is active or as needed to provide services. You can request deletion of your data at any time.',
                  style: TextStyle(
                    color: Color(0xFF6F5051),
                    fontSize: 14,
                    fontFamily: 'Afacad',
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: Color(0xFFE4B8D2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    ),
                    child: Text(
                      "Close",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Afacad',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTermsOfUse(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Dialog(
        backgroundColor: const Color(0xE6F1FFFB),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Terms of Use',
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.8),
                    fontSize: 24,
                    fontFamily: 'Afacad',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Last Updated: April 19, 2025\n\n'
                  'Acceptance of Terms\n'
                  'By accessing or using our app, you agree to these Terms of Use and our Privacy Policy.\n\n'
                  'Health Disclaimer\n'
                  'Our app provides general health tracking and information. It is not a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of qualified healthcare professionals.\n\n'
                  'Account Responsibilities\n'
                  'You are responsible for:\n'
                  '• Maintaining account security\n'
                  '• Providing accurate information\n'
                  '• Keeping your data confidential\n'
                  '• Using the app appropriately\n\n'
                  'Prohibited Activities\n'
                  '• Sharing account credentials\n'
                  '• Submitting false information\n'
                  '• Attempting to access other users\' data\n'
                  '• Using the app for unlawful purposes\n\n'
                  'Data Accuracy\n'
                  'While we strive for accuracy, we cannot guarantee the precision of health predictions and suggestions. Use the apps features as guidance only.\n\n'
                  'Intellectual Property\n'
                  'All content and functionality in the app are protected by intellectual property rights and may not be copied or modified without permission.\n\n'
                  'Termination\n'
                  'We reserve the right to terminate or suspend accounts that violate these terms or for any other reason at our discretion.\n\n'
                  'Changes to Terms\n'
                  'We may update these terms periodically. Continued use of the app after changes constitutes acceptance of the new terms.',
                  style: TextStyle(
                    color: Color(0xFF6F5051),
                    fontSize: 14,
                    fontFamily: 'Afacad',
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: Color(0xFFE4B8D2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    ),
                    child: Text(
                      "Close",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Afacad',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> signUpUser() async {
    if (!termsAccepted) {
      _showErrorDialog(
        "Terms Required",
        "Please accept the Terms of Use and Privacy Policy to continue."
      );
      return;
    }

    // Get user input values
    String email = emailController.text.trim();  
    String password = passwordController.text;
    String name = nameController.text;
    String dobFormatted = formatDobForBackend(dobController.text.trim());  
    String profession = selectedOccupation;
    String lastPeriodFormatted = formatLastPeriodForBackend(lastPeriodController.text.trim()); 

    if (email.isEmpty || password.isEmpty || name.isEmpty || dobFormatted.isEmpty || lastPeriodFormatted.isEmpty) {
      _showErrorDialog(
        "Error",
        "All fields must be filled out and dates must be in DD/MM/YYYY format."
      );
      return;
    }

    String apiUrl = "http://127.0.0.1:5000/add_user";

    try {
      var response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
          "name": name,
          "dob": dobFormatted,  
          "profession": profession,
          "last_period": lastPeriodFormatted 
        }),
      );

      var responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Show success dialog and wait for user to click "OK" before navigating
        await showDialog(
          context: context,
          barrierDismissible: false, 
          barrierColor: Colors.black.withOpacity(0.7),
          builder: (context) => Dialog(
            backgroundColor: const Color(0xE6F1FFFB),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Success",
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.8),
                      fontSize: 24,
                      fontFamily: 'Afacad',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Account created successfully! You can now log in with your email and password.",
                    style: const TextStyle(
                      color: Color(0xFF6F5051),
                      fontSize: 14,
                      fontFamily: 'Afacad',
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Return to login page           
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      "OK",
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.8),
                        fontFamily: 'Afacad',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        _showErrorDialog("Error", responseData['error']);
      }
    } catch (e) {
      _showErrorDialog(
        "Error", 
        "Something went wrong! Please check your internet connection and try again."
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/background.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Scrollable Content
          SingleChildScrollView(
            child: Column(
              children: [
                // Motif Image and Title
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 149,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage("assets/images/cropmot.png"),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 50,
                      left: 40,
                      right: 40,
                      child: Text(
                        'Create your account.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontFamily: 'Afacad',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),

                // Input Fields
                buildInputField("What is your name?", Icons.person, nameController),
                buildInputField("What is your email?", Icons.email, emailController),
                buildInputField("What would you like your password to be?", Icons.lock, passwordController, isPassword: true),
                buildDateInputField("What is your date of birth?", Icons.calendar_today, dobController),

                // Occupation Dropdown
                buildDropdownField("What is your current occupation?", Icons.work),

                buildDateInputField("When was the last time you had your period?", Icons.event, lastPeriodController),

                SizedBox(height: 40),

                // Sign Up Button
                GestureDetector(
                  onTap: () {
                    if (termsAccepted) {
                      signUpUser();
                    } else {
                      _showErrorDialog("Error", "You must accept the Terms of Use and Privacy Policy.");
                    }
                  },
                  child: Container(
                    width: 120,
                    height: 41,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'sign up',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFE3A2B3),
                        fontSize: 22,
                        fontFamily: 'Afacad',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 30),

                // Terms & Privacy Policy Checkbox
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: termsAccepted,
                          onChanged: (value) {
                            setState(() {
                              termsAccepted = value!;
                            });
                          },
                          fillColor: WidgetStateProperty.resolveWith<Color>(
                            (Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Colors.white;
                              }
                              return Colors.white;
                            },
                          ),
                          checkColor: Color(0xFFE4B8D2),
                          shape: CircleBorder(),
                          side: BorderSide(color: Colors.white),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'I accept the ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontFamily: 'Afacad',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            TextSpan(
                              text: 'Terms of Use',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontFamily: 'Afacad',
                                fontWeight: FontWeight.w400,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => _showTermsOfUse(context),
                            ),
                            TextSpan(
                              text: ' and ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontFamily: 'Afacad',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontFamily: 'Afacad',
                                fontWeight: FontWeight.w400,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => _showPrivacyPolicy(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Function to build standard input fields
  Widget buildInputField(String labelText, IconData icon, TextEditingController controller, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            labelText,
            style: TextStyle(
              color: Color.fromARGB(255, 109, 87, 88),
              fontSize: 17,
              fontFamily: 'Afacad',
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 5),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(15),
            ),
            child: TextFormField(
              controller: controller,
              obscureText: isPassword && !_isPasswordVisible,
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: const Color.fromARGB(255, 179, 149, 149), size: 20),
                suffixIcon: isPassword ? Material(
                  color: Colors.transparent,
                  child: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: const Color.fromARGB(255, 179, 149, 149),
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                    style: IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ) : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Function to build date input fields
  Widget buildDateInputField(String labelText, IconData icon, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            labelText,
            style: TextStyle(
              color: Color.fromARGB(255, 109, 87, 88),
              fontSize: 17,
              fontFamily: 'Afacad',
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 5),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextFormField(
              controller: controller,
              readOnly: true,
              onTap: () => _selectDate(context, controller),
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: const Color.fromARGB(255, 179, 149, 149), size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Function to build dropdown for occupation
  Widget buildDropdownField(String labelText, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            labelText,
            style: TextStyle(
              color: Color.fromARGB(255, 109, 87, 88),
              fontSize: 17,
              fontFamily: 'Afacad',
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 5),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: DropdownButtonFormField<String>(
              value: selectedOccupation,
              items: occupations.map((occupation) {
                return DropdownMenuItem(
                  value: occupation,
                  child: Text(
                    occupation,
                    style: const TextStyle(
                      color: Color(0xFF6F5051),
                      fontSize: 14,
                      fontFamily: 'Afacad',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedOccupation = value!;
                });
              },
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: const Color.fromARGB(255, 179, 149, 149), size: 20), // Made icon smaller
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              ),
              icon: const Icon(Icons.arrow_drop_down, color: Color.fromARGB(255, 116, 97, 97), size: 20), // Made dropdown icon smaller too
              dropdownColor: Colors.white,
              style: const TextStyle(
                color: Color.fromARGB(255, 144, 111, 112),
                fontSize: 14,
                fontFamily: 'Afacad',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
