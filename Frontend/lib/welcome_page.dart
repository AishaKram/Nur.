import 'package:flutter/material.dart';
import 'login_page.dart';  
import 'signup_page.dart'; 

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the screen size using MediaQuery
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: screenWidth, 
        height: screenHeight,
        clipBehavior: Clip.antiAlias,
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
            // Background motif image
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: screenWidth, 
                height: screenHeight, 
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/motif.png"), 
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
            // "Welcome to Nur" Text
            Positioned(
              left: screenWidth * 0.112, 
              top: screenHeight * 0.124, 
              child: SizedBox(
                width: screenWidth * 0.84, 
                height: screenHeight * 0.129, 
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Welcome To Nur.\n',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontFamily: 'Afacad',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: 'Nur.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontFamily: 'Afacad',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Subtitle Text
            Positioned(
              left: screenWidth * 0.112, 
              top: screenHeight * 0.235, 
              child: SizedBox(
                width: screenWidth * 0.84, 
                height: screenHeight * 0.129, 
                child: Text(
                  'your journey to a more balanced and productive you starts here.',
                  style: TextStyle(
                    color: Color(0xFF938182),
                    fontSize: 24,
                    fontFamily: 'Afacad',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            // Log In Button
            Positioned(
              left: screenWidth * 0.115,
              top: screenHeight * 0.634, 
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()), 
                  );
                },
                child: Container(
                  width: screenWidth * 0.773, 
                  height: screenHeight * 0.066, 
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'log in',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xCCB48491),
                        fontSize: 32,
                        fontFamily: 'Afacad',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Sign Up Button
            Positioned(
              left: screenWidth * 0.115, 
              top: screenHeight * 0.737, 
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignUpPage()), 
                  );
                },
                child: Container(
                  width: screenWidth * 0.773, 
                  height: screenHeight * 0.066, 
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'sign up',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xF2EB8FA7),
                        fontSize: 32,
                        fontFamily: 'Afacad',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
