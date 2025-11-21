import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swipe_app/providers/theme_provider.dart';
import 'package:swipe_app/widgets/bottom_navbar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  int _navIndex = 4; // Settings tab index

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.backgroundColor,
          appBar: AppBar(
            backgroundColor: themeProvider.backgroundColor,
            elevation: 0,
            title: Text(
              'Settings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: themeProvider.primaryTextColor,
              ),
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: themeProvider.primaryTextColor,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Section
                _buildSectionHeader('Profile', themeProvider),
                const SizedBox(height: 12),
                _buildProfileCard(themeProvider),
                const SizedBox(height: 24),

                // Notifications
                _buildSectionHeader('Notifications', themeProvider),
                const SizedBox(height: 12),
                _buildNotificationSection(themeProvider),
                const SizedBox(height: 24),

                // App Settings
                _buildSectionHeader('App Settings', themeProvider),
                const SizedBox(height: 12),
                _buildAppSettingsSection(themeProvider),
                const SizedBox(height: 24),

                // Account
                _buildSectionHeader('Account', themeProvider),
                const SizedBox(height: 12),
                _buildAccountSection(themeProvider),
                const SizedBox(height: 24),

                // About
                _buildSectionHeader('About', themeProvider),
                const SizedBox(height: 12),
                _buildAboutSection(themeProvider),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavBar(
            currentIndex: _navIndex,
            onTap: (index) {
              if (index != _navIndex) {
                Navigator.pop(context);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, ThemeProvider themeProvider) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: themeProvider.primaryTextColor,
      ),
    );
  }

  Widget _buildProfileCard(ThemeProvider themeProvider) {
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
                    color: themeProvider.primaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'john.doe@example.com',
                  style: TextStyle(
                    fontSize: 14,
                    color: themeProvider.secondaryTextColor,
                  ),
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

  Widget _buildNotificationSection(ThemeProvider themeProvider) {
    return Column(
      children: [
        _buildSwitchTile(
          themeProvider: themeProvider,
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
          themeProvider: themeProvider,
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
          themeProvider: themeProvider,
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

  Widget _buildAppSettingsSection(ThemeProvider themeProvider) {
    return Column(
      children: [
        _buildSwitchTile(
          themeProvider: themeProvider,
          icon: Icons.dark_mode,
          title: 'Dark Mode',
          subtitle: 'Switch to dark theme',
          value: themeProvider.isDarkMode,
          onChanged: (value) {
            themeProvider.toggleTheme();
          },
        ),
        _buildSettingsTile(
          themeProvider: themeProvider,
          icon: Icons.language,
          title: 'Language',
          subtitle: 'English',
          onTap: () => _showLanguagePicker(themeProvider),
        ),
        _buildSettingsTile(
          themeProvider: themeProvider,
          icon: Icons.storage,
          title: 'Clear Cache',
          subtitle: 'Free up storage space',
          onTap: () => _showClearCacheDialog(themeProvider),
        ),
      ],
    );
  }

  Widget _buildAccountSection(ThemeProvider themeProvider) {
    return Column(
      children: [
        _buildSettingsTile(
          themeProvider: themeProvider,
          icon: Icons.security,
          title: 'Privacy & Security',
          subtitle: 'Manage your privacy settings',
          onTap: () {
            // Navigate to privacy settings
          },
        ),
        _buildSettingsTile(
          themeProvider: themeProvider,
          icon: Icons.help,
          title: 'Help & Support',
          subtitle: 'Get help or contact support',
          onTap: () {
            // Navigate to help
          },
        ),
        _buildSettingsTile(
          themeProvider: themeProvider,
          icon: Icons.logout,
          title: 'Sign Out',
          subtitle: 'Sign out of your account',
          onTap: () => _showSignOutDialog(themeProvider),
          textColor: Colors.red,
        ),
      ],
    );
  }

  Widget _buildAboutSection(ThemeProvider themeProvider) {
    return Column(
      children: [
        _buildSettingsTile(
          themeProvider: themeProvider,
          icon: Icons.info,
          title: 'About jobr',
          subtitle: 'Version 1.0.0',
          onTap: () {
            // Show about dialog
          },
        ),
        _buildSettingsTile(
          themeProvider: themeProvider,
          icon: Icons.article,
          title: 'Terms of Service',
          subtitle: 'Read our terms and conditions',
          onTap: () {
            // Navigate to terms
          },
        ),
        _buildSettingsTile(
          themeProvider: themeProvider,
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
    required ThemeProvider themeProvider,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeProvider.borderColor),
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
            color: textColor ?? themeProvider.primaryTextColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: themeProvider.secondaryTextColor,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: themeProvider.secondaryTextColor,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({
    required ThemeProvider themeProvider,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeProvider.borderColor),
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
            color: themeProvider.primaryTextColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: themeProvider.secondaryTextColor,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF6366F1),
        ),
      ),
    );
  }

  void _showLanguagePicker(ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: themeProvider.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Language',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeProvider.primaryTextColor,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: Text(
                'English',
                style: TextStyle(color: themeProvider.primaryTextColor),
              ),
              trailing: const Icon(Icons.check, color: Color(0xFF6366F1)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: Text(
                'Spanish',
                style: TextStyle(color: themeProvider.primaryTextColor),
              ),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: Text(
                'French',
                style: TextStyle(color: themeProvider.primaryTextColor),
              ),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeProvider.cardColor,
        title: Text(
          'Clear Cache',
          style: TextStyle(color: themeProvider.primaryTextColor),
        ),
        content: Text(
          'Are you sure you want to clear the app cache?',
          style: TextStyle(color: themeProvider.secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: themeProvider.primaryTextColor),
            ),
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

  void _showSignOutDialog(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeProvider.cardColor,
        title: Text(
          'Sign Out',
          style: TextStyle(color: themeProvider.primaryTextColor),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: themeProvider.secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: themeProvider.primaryTextColor),
            ),
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
