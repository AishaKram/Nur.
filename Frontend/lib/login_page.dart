import 'package:flutter/material.dart';
import 'api_service.dart'; 
import 'homepage.dart';
import 'signup_page.dart';
import 'userPreferences.dart';
import 'user_model.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String message = "";
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
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

  void loginUser() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog(
        "Error",
        "Please fill in all fields"
      );
      return;
    }

    setState(() {
      _isLoading = true;
      message = "";
    });

    try {
      print("Attempting login...");
      var response = await ApiService.loginUser(email, password);
      print("Login response: $response");
      
      if (response["message"] == "Login successful!") {
        print("Login successful, attempting navigation");
        print("User data: ${response["user"]}");
        
        // Create User object from response
        final user = User(
          name: response["user"]["name"] ?? "User",
          email: response["user"]["email"] ?? "",
          userId: response["user"]["userId"] ?? "",  
          currentPhase: response["user"]["currentPhase"] ?? "Menstrual",
          cycleDay: response["user"]["cycleDay"] ?? 1,
          daysLeft: response["user"]["daysLeft"] ?? 5,
        );
        
        // Save user data
        await UserPreferences.saveUser(user);
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => HomePage(
                userName: user.name,
                currentPhase: user.currentPhase,
                cycleDay: user.cycleDay,
                daysLeft: user.daysLeft,
                userId: user.userId, 
              ),
            ),
          );
        }
      } else {
        print("Login failed: ${response["message"] ?? response["error"]}");
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog(
          response["message"] == "Login successful!" ? "Success" : "Error",
          response["message"] ?? response["error"]
        );
      }
      
    } catch (e) {
      print("Error during login: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog(
          "Error",
          "An error occurred. Please try again."
        );
      }
    }
  }

  Future<void> _resetPassword(String email) async {
    setState(() {
      message = "Sending reset email...";
    });

    try {
      if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
          .hasMatch(email)) {
        setState(() {
          message = "Please enter a valid email address";
        });
        return;
      }

      var response = await ApiService.resetPassword(email);
      setState(() {
        message = response["message"] ?? response["error"];
      });
      
      // Show a success message dialog after closing the reset dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorDialog(
          "Password Reset",
          "Password reset instructions have been sent to your email address. Please check your inbox and follow the instructions to reset your password."
        );
      });
    } catch (e) {
      setState(() {
        message = "An error occurred. Please try again.";
      });
      
      _showErrorDialog(
        "Error",
        "There was a problem sending the password reset email. Please try again later."
      );
    }
  }

  void _showForgotPasswordDialog(BuildContext context) {
    TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      barrierColor: const Color.fromARGB(255, 175, 132, 132).withOpacity(0.7),
      builder: (context) {
        return Dialog(
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
                  "Reset Password",
                  style: TextStyle(
                    color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.8), 
                    fontSize: 24,
                    fontFamily: 'Afacad',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: ShapeDecoration(
                    color: Colors.white.withOpacity(0.9), 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 15),
                      hintText: "Enter your email",
                      hintStyle: TextStyle(
                        color: Color.fromARGB(255, 97, 59, 61), 
                        fontSize: 12,
                        fontFamily: 'Afacad',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF6F5051), 
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          fontFamily: 'Afacad',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: () async {
                        String email = emailController.text.trim();
                        if (email.isNotEmpty) {
                          await _resetPassword(email);
                          Navigator.pop(context);
                        }
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.9), 
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        "Send Reset Link",
                        style: TextStyle(
                          color: const Color.fromARGB(255, 224, 145, 145).withOpacity(0.8),
                          fontFamily: 'Afacad',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: screenWidth,
        height: screenHeight,
        decoration: ShapeDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background.jpg"),
            fit: BoxFit.cover,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          shadows: [
            BoxShadow(
              color: Color(0x3F000000),
              blurRadius: 4,
              offset: Offset(0, 4),
              spreadRadius: 0,
            )
          ],
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
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: screenWidth,
                height: screenHeight,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/loginMo.png"),
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
            Positioned(
              left: screenWidth * 0.10, 
              top: screenHeight * 0.221,
              child: SizedBox(
                width: screenWidth * 0.839,
                height: screenHeight * 0.129,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Welcome back',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontFamily: 'Afacad',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: '.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontFamily: 'Afacad',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
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
            Positioned(
              left: screenWidth * 0.167,
              top: screenHeight * 0.396,
              child: SizedBox(
                width: screenWidth * 0.7,
                child: TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "email",
                    hintStyle: TextStyle(
                      color: Color(0xFFD4A3A3), 
                      fontSize: 12,
                      fontFamily: 'Afacad',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: screenWidth * 0.167,
              top: screenHeight * 0.473,
              child: SizedBox(
                width: screenWidth * 0.7,
                child: TextField(
                  controller: passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "password",
                    hintStyle: const TextStyle(
                      color: Color(0xFFB98AAA),
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
                          style: IconButton.styleFrom(
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                       ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: screenWidth * 0.70,
              top: screenHeight * 0.548,
              child: GestureDetector(
                onTap: () {
                  _showForgotPasswordDialog(context);
                },
                child: SizedBox(
                  width: screenWidth * 0.249,
                  child: Text(
                    'forgot password?',
                    style: TextStyle(
                      color: Color(0xFF6F5051), 
                      fontSize: 14,
                      fontFamily: 'Afacad',
                      fontWeight: FontWeight.w400,
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0xFF6F5051), 
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: screenWidth * 0.320,
              top: screenHeight * 0.70, 
              child: GestureDetector(
                onTap: loginUser,
                child: Container(
                  width: screenWidth * 0.35, 
                  height: 41,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'log in',
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
            Positioned(
              left: screenWidth * 0.320,
              top: screenHeight * 0.77, 
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignUpPage()),
                  );
                },
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: "don't have an account? ",
                        style: TextStyle(
                          color: Color(0xFF6F5051),
                        ),
                      ),
                      TextSpan(
                        text: "sign up",
                        style: TextStyle(
                          color: Color(0xFF6F5051),
                          decoration: TextDecoration.underline
                        ),
                      ),
                      TextSpan(
                        text: " now",
                        style: TextStyle(
                          color: Color(0xFF6F5051),
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Positioned(
              left: screenWidth * 0.214,
              top: screenHeight * 0.82,  
              child: SizedBox(
                width: screenWidth * 0.575,
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF6F2A2A),
                    fontSize: 14,
                    fontFamily: 'Afacad',
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
