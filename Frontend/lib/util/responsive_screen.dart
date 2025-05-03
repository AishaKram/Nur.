import 'package:flutter/material.dart';
import 'responsive_size_util.dart';

/// A responsive screen wrapper that ensures consistent layout across different device sizes
class ResponsiveScreen extends StatelessWidget {
  final Widget child;
  final bool resizeToAvoidBottomInset;
  final bool extendBody;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final String? backgroundImagePath;

  const ResponsiveScreen({
    super.key,
    required this.child,
    this.resizeToAvoidBottomInset = true,
    this.extendBody = false,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.backgroundImagePath,
  });

  @override
  Widget build(BuildContext context) {
    // Initialize responsive utils with current context
    ResponsiveSizeUtil.init(context);

    return Scaffold(
      extendBody: extendBody, // Important for proper nav bar display
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      bottomNavigationBar: bottomNavigationBar,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: backgroundColor,
          image: backgroundImagePath != null
              ? DecorationImage(
                  image: AssetImage(backgroundImagePath!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: SafeArea(
          bottom: false, // Allow content to extend under the nav bar
          // Use SingleChildScrollView to handle small screens and prevent overflow
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: ResponsiveSizeUtil.screenHeight - 
                    (ResponsiveSizeUtil.safeAreaVertical + 
                     (bottomNavigationBar != null ? 100 : 0)), // Increased to account for padding
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}