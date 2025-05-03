import 'package:flutter/material.dart';

/// A utility class that provides methods for responsive sizing
class ResponsiveSizeUtil {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeHorizontal;
  static late double blockSizeVertical;
  static late double safeAreaHorizontal;
  static late double safeAreaVertical;
  static late double safeBlockHorizontal;
  static late double safeBlockVertical;
  static late double textScaleFactor;
  static late bool isSmallScreen;

  // Initialize the responsive size utility with the current BuildContext
  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    textScaleFactor = _mediaQueryData.textScaleFactor;
    
    // Create sizing blocks (1% of screen width/height)
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;
    
    // Calculate the safe area (accounting for system UI elements)
    safeAreaHorizontal = _mediaQueryData.padding.left + _mediaQueryData.padding.right;
    safeAreaVertical = _mediaQueryData.padding.top + _mediaQueryData.padding.bottom;
    
    // Calculate safe blocks (1% of safe area)
    safeBlockHorizontal = (screenWidth - safeAreaHorizontal) / 100;
    safeBlockVertical = (screenHeight - safeAreaVertical) / 100;
    
    // Determine if the screen is small (useful for further adjustments)
    isSmallScreen = screenWidth < 360;
  }

  // Get adaptive font size based on design size and current screen size
  static double getAdaptiveFontSize(double size) {
    // Cap text scaling factor to prevent text from becoming too large
    double scalingFactor = textScaleFactor > 1.2 ? 1.2 : textScaleFactor;
    
    // Adjust font size for small screens
    if (isSmallScreen) {
      return size * 0.8 * scalingFactor;
    }
    return size * scalingFactor;
  }
  
  // Get adaptive size for width dimensions
  static double getAdaptiveWidth(double size) {
    return size * blockSizeHorizontal;
  }
  
  // Get adaptive size for height dimensions
  static double getAdaptiveHeight(double size) {
    return size * blockSizeVertical;
  }
  
  // Get adaptive size value based on screen width (percentage-based)
  static double wp(double percentage) {
    return percentage * safeBlockHorizontal;
  }
  
  // Get adaptive size value based on screen height (percentage-based)
  static double hp(double percentage) {
    return percentage * safeBlockVertical;
  }
}