import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  
  bool get isDarkMode => _isDarkMode;
  
  ThemeProvider() {
    _loadThemePreference();
  }
  
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveThemePreference();
    notifyListeners();
  }
  
  void setTheme(bool isDark) {
    _isDarkMode = isDark;
    _saveThemePreference();
    notifyListeners();
  }
  
  // Load theme preference from SharedPreferences
  void _loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }
  
  // Save theme preference to SharedPreferences
  void _saveThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', _isDarkMode);
  }
  
  // Helper methods for colors
  Color get backgroundColor => _isDarkMode ? Colors.black : Colors.white;
  Color get primaryTextColor => _isDarkMode ? Colors.white : const Color(0xFF1E293B);
  Color get secondaryTextColor => _isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600;
  Color get cardColor => _isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF8FAFC);
  Color get borderColor => _isDarkMode ? const Color(0xFF3A3A3A) : const Color(0xFFE2E8F0);
}