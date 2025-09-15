import 'package:flutter/material.dart';
import 'package:swipe_app/screens/settings_screen.dart';
import 'package:swipe_app/screens/preferences_screen.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == 2) {
            // Navigate to preferences screen
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const PreferencesScreen()),
            );
          } else if (index == 3) {
            // Navigate to settings screen
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          } else {
            // Call the parent's onTap for other indices
            onTap(index);
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF6366F1),
        unselectedItemColor: const Color(0xFF64748B),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined), // Shows a clipboard with checkmarks
            label: 'Track',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tune),
            label: 'Preferences',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
