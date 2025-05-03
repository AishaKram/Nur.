import 'package:flutter/material.dart';
import 'welcome_page.dart';
import 'login_Page.dart';
import 'splash_screen.dart';
import 'reset_password_page.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nur App',
      theme: ThemeData(
        fontFamily: 'Afacad',
        textSelectionTheme: TextSelectionThemeData(
          selectionColor: const Color(0x7FE4B7D2).withOpacity(0.3),  
          cursorColor: const Color(0xD676252F),  
          selectionHandleColor: const Color(0xD676252F),  
        ),
      ),
      builder: (context, child) {
        // Apply responsive wrapper to all screens
        return MediaQuery(
          // Set text scaling to prevent text from becoming too large
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
          child: ResponsiveWrapper(child: child!),
        );
      },
      home: SplashScreen(),
      routes: {
        '/welcome': (context) => const WelcomePage(),
        '/login': (context) => const LoginPage(),
        '/reset-password-test': (context) => const ResetPasswordPage(oobCode: 'test-code'),
      },
      onGenerateRoute: (settings) {
        // Handle deep links for password reset
        final uri = Uri.parse(settings.name ?? '');
        
  
        if (uri.path.contains('/__/auth/action') || uri.path.contains('/auth/action')) {
          // Extract the oobCode (out-of-band code) from the URL
          final oobCode = uri.queryParameters['oobCode'];
          final mode = uri.queryParameters['mode'];
          
          if (oobCode != null && oobCode.isNotEmpty && mode == 'resetPassword') {
            return MaterialPageRoute(
              builder: (context) => ResetPasswordPage(oobCode: oobCode),
            );
          }
        }
        
        // keep the original check for direct reset-password links
        if (uri.path == '/reset-password') {
          final oobCode = uri.queryParameters['oobCode'];
          
          if (oobCode != null && oobCode.isNotEmpty) {
            return MaterialPageRoute(
              builder: (context) => ResetPasswordPage(oobCode: oobCode),
            );
          }
        }
        return null;
      },
    );
  }
}

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  const ResponsiveWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        double screenHeight = constraints.maxHeight;
  
        double verticalPadding = 0.0;
        if (screenHeight / screenWidth > 2.1) { 
          verticalPadding = 8.0;
        }

        return Container(
          width: screenWidth,
          height: screenHeight,
          padding: EdgeInsets.symmetric(vertical: verticalPadding),
          child: child,
        );
      },
    );
  }
}
