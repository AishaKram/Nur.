import 'package:flutter/material.dart';
import 'api_service.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  final String oobCode;

  const ResetPasswordPage({super.key, required this.oobCode});

  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  String message = "";
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  // Custom dialog 
  void _showDialog(String title, String message, bool isError) {
    showDialog(
      context: context,
      barrierColor: const Color.fromARGB(255, 175, 132, 132).withOpacity(0.7),
      builder: (context) => Dialog(
        backgroundColor: const Color.fromARGB(230, 245, 230, 243),
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontFamily: 'Afacad',
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                message,
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
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  "OK",
                  style: TextStyle(
                    color: Color.fromARGB(130, 220, 143, 143),
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

  void _resetPassword() async {
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    
    if (password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        message = "Please fill in all fields";
      });
      return;
    }
    
    if (password.length < 8) {
      setState(() {
        message = "Password must be at least 8 characters long";
      });
      return;
    }
    
    if (password != confirmPassword) {
      setState(() {
        message = "Passwords do not match";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      message = "";
    });

    try {
      var response = await ApiService.confirmPasswordReset(widget.oobCode, password);
      
      setState(() {
        _isLoading = false;
      });
      
      if (response['success'] == true) {
        _showDialog(
          "Success", 
          response['message'] ?? "Your password has been reset successfully. You can now log in with your new password.",
          false
        );
        
        // Navigate back to login page after successful reset
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        });
      } else {
        _showDialog(
          "Error", 
          response['error'] ?? "Failed to reset password. Please try again or request a new reset link.",
          true
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        message = "An error occurred. Please try again.";
      });
      
      _showDialog(
        "Error",
        "Failed to reset password. Please try again later.",
        true
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: screenWidth,
        height: screenHeight,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: screenWidth * 0.063,
              top: screenHeight * 0.154,
              child: Container(
                width: screenWidth * 0.876,
                height: screenHeight * 0.75,
                decoration: ShapeDecoration(
                  color: const Color(0x63F1FFFB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(172),
                  ),
                ),
              ),
            ),
            
            // Motif
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: screenWidth,
                height: screenHeight,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/loginMo.png"),
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
            
            // Reset Password text
            Positioned(
              left: 0,
              top: screenHeight * 0.221,
              child: SizedBox(
                width: screenWidth,
                child: const Text(
                  'Reset Password',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontFamily: 'Afacad',
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            
            // New password field container
            Positioned(
              left: screenWidth * 0.13,
              top: screenHeight * 0.396,
              child: Container(
                width: screenWidth * 0.75,
                height: 43,
                decoration: ShapeDecoration(
                  color: Colors.white.withOpacity(0.78),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            
            // Confirm password field container
            Positioned(
              left: screenWidth * 0.13,
              top: screenHeight * 0.474,
              child: Container(
                width: screenWidth * 0.75,
                height: 43,
                decoration: ShapeDecoration(
                  color: Colors.white.withOpacity(0.78),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            
            // New password text field
            Positioned(
              left: screenWidth * 0.167,
              top: screenHeight * 0.396,
              child: SizedBox(
                width: screenWidth * 0.7,
                child: TextField(
                  controller: passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "new password",
                    hintStyle: const TextStyle(
                      color: Color(0xFFD4A3A3),
                      fontSize: 12,
                      fontFamily: 'Afacad',
                      fontWeight: FontWeight.w400,
                    ),
                    suffixIcon: Material(
                      color: Colors.transparent,
                      child: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: const Color(0xEF6F5051),
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Confirm password text field
            Positioned(
              left: screenWidth * 0.167,
              top: screenHeight * 0.474,
              child: SizedBox(
                width: screenWidth * 0.7,
                child: TextField(
                  controller: confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "confirm password",
                    hintStyle: const TextStyle(
                      color: Color(0xFFD4A3A3), 
                      fontSize: 12,
                      fontFamily: 'Afacad',
                      fontWeight: FontWeight.w400,
                    ),
                    suffixIcon: Material(
                      color: Colors.transparent,
                      child: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: const Color(0xEF6F5051),
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Reset button
            Positioned(
              left: screenWidth * 0.320,
              top: screenHeight * 0.60,
              child: GestureDetector(
                onTap: _isLoading ? null : _resetPassword,
                child: Container(
                  width: screenWidth * 0.35,
                  height: 41,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24, 
                          height: 24, 
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color.fromARGB(130, 220, 143, 143)),
                            strokeWidth: 2.5,
                          )
                        )
                      : const Text(
                          'Reset',
                          style: TextStyle(
                            color: Color.fromARGB(130, 220, 143, 143),
                            fontSize: 24,
                            fontFamily: 'Afacad',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
            ),
            
            // Error message text
            Positioned(
              left: screenWidth * 0.214,
              top: screenHeight * 0.67,
              child: SizedBox(
                width: screenWidth * 0.575,
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Color.fromARGB(255, 173, 68, 68),
                    fontSize: 14,
                    fontFamily: 'Afacad',
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            
            // Back to Login link
            Positioned(
              left: 0,
              top: screenHeight * 0.74,
              child: SizedBox(
                width: screenWidth,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    );
                  },
                  child: const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "Back to ",
                          style: TextStyle(
                            color: Color(0xFF6F5051),
                            fontFamily: 'Afacad',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        TextSpan(
                          text: "login",
                          style: TextStyle(
                            color: Color(0xFF6F5051),
                            fontFamily: 'Afacad',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            decoration: TextDecoration.underline
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}