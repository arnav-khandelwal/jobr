import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swipe_app/providers/theme_provider.dart';

class HelpDialog extends StatelessWidget {
  const HelpDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const HelpDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return AlertDialog(
          backgroundColor: themeProvider.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.help_outline, color: Color(0xFF6366F1)),
              const SizedBox(width: 12),
              Text(
                'How to Use Jobr',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.primaryTextColor,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHelpItem(
                  themeProvider,
                  Icons.swipe_right,
                  'Swipe Right',
                  'Apply to a job you\'re interested in',
                  Colors.green,
                ),
                const SizedBox(height: 12),
                _buildHelpItem(
                  themeProvider,
                  Icons.swipe_left,
                  'Swipe Left',
                  'Skip a job you\'re not interested in',
                  Colors.orange,
                ),
                const SizedBox(height: 12),
                _buildHelpItem(
                  themeProvider,
                  Icons.location_on,
                  'Change Location',
                  'Tap the location to switch between India and Remote',
                  const Color(0xFF6366F1),
                ),
                const SizedBox(height: 12),
                _buildHelpItem(
                  themeProvider,
                  Icons.filter_list,
                  'Use Filters',
                  'Filter jobs by type: All, Remote, Full-time, etc.',
                  const Color(0xFF6366F1),
                ),
                const SizedBox(height: 12),
                _buildHelpItem(
                  themeProvider,
                  Icons.refresh,
                  'Refresh Jobs',
                  'Get new job listings by tapping the refresh icon',
                  const Color(0xFF6366F1),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, 
                           color: Color(0xFF6366F1), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tip: You can tap the job card to view more details!',
                          style: TextStyle(
                            fontSize: 14,
                            color: themeProvider.primaryTextColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Got it!',
                style: TextStyle(
                  color: Color(0xFF6366F1),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpItem(ThemeProvider themeProvider, IconData icon, String title, String description, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.primaryTextColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: themeProvider.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}