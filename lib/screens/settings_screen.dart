import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _darkMode = false;

  // Helper method to get background color based on dark mode
  Color get _backgroundColor => _darkMode ? Colors.black : Colors.white;
  
  // Helper method to get primary text color based on dark mode
  Color get _primaryTextColor => _darkMode ? Colors.white : const Color(0xFF1E293B);
  
  // Helper method to get secondary text color based on dark mode
  Color get _secondaryTextColor => _darkMode ? Colors.grey.shade300 : Colors.grey.shade600;
  
  // Helper method to get card color based on dark mode
  Color get _cardColor => _darkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF8FAFC);
  
  // Helper method to get border color based on dark mode
  Color get _borderColor => _darkMode ? const Color(0xFF3A3A3A) : const Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor, // Changed from hardcoded Colors.white
      appBar: AppBar(
        backgroundColor: _backgroundColor, // Changed from hardcoded Colors.white
        elevation: 0,
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _primaryTextColor, // Changed from hardcoded color
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: _primaryTextColor), // Changed from hardcoded color
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _buildSectionHeader('Profile'),
            const SizedBox(height: 12),
            _buildProfileCard(),
            const SizedBox(height: 24),

            // Notifications
            _buildSectionHeader('Notifications'),
            const SizedBox(height: 12),
            _buildNotificationSection(),
            const SizedBox(height: 24),

            // App Settings
            _buildSectionHeader('App Settings'),
            const SizedBox(height: 12),
            _buildAppSettingsSection(),
            const SizedBox(height: 24),

            // Account
            _buildSectionHeader('Account'),
            const SizedBox(height: 12),
            _buildAccountSection(),
            const SizedBox(height: 24),

            // About
            _buildSectionHeader('About'),
            const SizedBox(height: 12),
            _buildAboutSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: _primaryTextColor, // Changed from hardcoded color
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF6366F1),
            child: const Icon(Icons.person, size: 32, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'John Doe',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _primaryTextColor, // Changed from hardcoded color
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'john.doe@example.com',
                  style: TextStyle(fontSize: 14, color: _secondaryTextColor), // Changed from hardcoded color
                ),
                const SizedBox(height: 8),
                const Text(
                  'Flutter Developer',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // Navigate to edit profile
            },
            icon: const Icon(Icons.edit, color: Color(0xFF6366F1)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection() {
    return Column(
      children: [
        _buildSwitchTile(
          icon: Icons.notifications,
          title: 'All Notifications',
          subtitle: 'Receive all app notifications',
          value: _notificationsEnabled,
          onChanged: (value) {
            setState(() {
              _notificationsEnabled = value;
            });
          },
        ),
        _buildSwitchTile(
          icon: Icons.email,
          title: 'Email Notifications',
          subtitle: 'Get job alerts via email',
          value: _emailNotifications,
          onChanged: (value) {
            setState(() {
              _emailNotifications = value;
            });
          },
        ),
        _buildSwitchTile(
          icon: Icons.phone_android,
          title: 'Push Notifications',
          subtitle: 'Get instant job alerts',
          value: _pushNotifications,
          onChanged: (value) {
            setState(() {
              _pushNotifications = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildAppSettingsSection() {
    return Column(
      children: [
        _buildSwitchTile(
          icon: Icons.dark_mode,
          title: 'Dark Mode',
          subtitle: 'Switch to dark theme',
          value: _darkMode,
          onChanged: (value) {
            setState(() {
              _darkMode = value;
            });
          },
        ),
        _buildSettingsTile(
          icon: Icons.language,
          title: 'Language',
          subtitle: 'English',
          onTap: () => _showLanguagePicker(),
        ),
        _buildSettingsTile(
          icon: Icons.storage,
          title: 'Clear Cache',
          subtitle: 'Free up storage space',
          onTap: () => _showClearCacheDialog(),
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return Column(
      children: [
        _buildSettingsTile(
          icon: Icons.security,
          title: 'Privacy & Security',
          subtitle: 'Manage your privacy settings',
          onTap: () {
            // Navigate to privacy settings
          },
        ),
        _buildSettingsTile(
          icon: Icons.help,
          title: 'Help & Support',
          subtitle: 'Get help or contact support',
          onTap: () {
            // Navigate to help
          },
        ),
        _buildSettingsTile(
          icon: Icons.logout,
          title: 'Sign Out',
          subtitle: 'Sign out of your account',
          onTap: () => _showSignOutDialog(),
          textColor: Colors.red,
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      children: [
        _buildSettingsTile(
          icon: Icons.info,
          title: 'About jobr',
          subtitle: 'Version 1.0.0',
          onTap: () {
            // Show about dialog
          },
        ),
        _buildSettingsTile(
          icon: Icons.article,
          title: 'Terms of Service',
          subtitle: 'Read our terms and conditions',
          onTap: () {
            // Navigate to terms
          },
        ),
        _buildSettingsTile(
          icon: Icons.privacy_tip,
          title: 'Privacy Policy',
          subtitle: 'Read our privacy policy',
          onTap: () {
            // Navigate to privacy policy
          },
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _cardColor, // Changed from hardcoded color
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor), // Changed from hardcoded color
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: textColor ?? const Color(0xFF6366F1),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor ?? _primaryTextColor, // Changed from hardcoded color
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 14, color: _secondaryTextColor), // Changed from hardcoded color
        ),
        trailing: Icon(
          Icons.chevron_right, 
          color: _darkMode ? Colors.grey.shade400 : Colors.grey.shade400
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _cardColor, // Changed from hardcoded color
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor), // Changed from hardcoded color
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF6366F1)),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _primaryTextColor, // Changed from hardcoded color
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 14, color: _secondaryTextColor), // Changed from hardcoded color
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF6366F1),
        ),
      ),
    );
  }

  void _showLanguagePicker() {
    // Implementation for language picker
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor, // Added dynamic color
        title: Text('Clear Cache', style: TextStyle(color: _primaryTextColor)), // Added dynamic color
        content: Text(
          'Are you sure you want to clear the app cache?',
          style: TextStyle(color: _secondaryTextColor), // Added dynamic color
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: _primaryTextColor)), // Added dynamic color
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor, // Added dynamic color
        title: Text('Sign Out', style: TextStyle(color: _primaryTextColor)), // Added dynamic color
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: _secondaryTextColor), // Added dynamic color
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: _primaryTextColor)), // Added dynamic color
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
