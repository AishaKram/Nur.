import 'package:flutter/material.dart';
import 'responsive_size_util.dart';

class ResponsiveNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const ResponsiveNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    // Initialize responsive sizing if not already done
    ResponsiveSizeUtil.init(context);
    
    // Match Settings page navigation bar style
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 317,
            height: 64,
            decoration: ShapeDecoration(
              color: Colors.white.withOpacity(0.7), // alpha: 178 ≈ 0.7
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
                    color: selectedIndex == 0 
                      ? const Color(0xFFAA8987) // Selected color
                      : Colors.black54, // Unselected color
                  ),
                  onPressed: () => onItemTapped(0),
                ),
                IconButton(
                  icon: Icon(
                    Icons.track_changes,
                    color: selectedIndex == 1 
                      ? const Color(0xFFAA8987) // Selected color
                      : Colors.black54, // Unselected color
                  ),
                  onPressed: () => onItemTapped(1),
                ),
                IconButton(
                  icon: Icon(
                    Icons.trending_up,
                    color: selectedIndex == 2 
                      ? const Color(0xFFAA8987) // Selected color
                      : Colors.black54, // Unselected color
                  ),
                  onPressed: () => onItemTapped(2),
                ),
                IconButton(
                  icon: Icon(
                    Icons.settings,
                    color: selectedIndex == 3 
                      ? const Color(0xFFAA8987) // Selected color
                      : Colors.black54, // Unselected color
                  ),
                  onPressed: () => onItemTapped(3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}