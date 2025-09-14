import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swipe_app/providers/theme_provider.dart';
import 'package:swipe_app/widgets/help_dialog.dart';

class LocationAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String location;
  final VoidCallback onLocationTap;
  final VoidCallback onProfileTap;
  final VoidCallback? onHelpTap;

  const LocationAppBar({
    super.key,
    required this.location,
    required this.onLocationTap,
    required this.onProfileTap,
    this.onHelpTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return AppBar(
          backgroundColor: themeProvider.backgroundColor,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: GestureDetector(
            onTap: onLocationTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on,
                  color: themeProvider.primaryTextColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  location,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: themeProvider.primaryTextColor,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: themeProvider.primaryTextColor,
                  size: 20,
                ),
              ],
            ),
          ),
          actions: [
            // Help/Info icon
            IconButton(
              onPressed: onHelpTap ?? () => HelpDialog.show(context),
              icon: Icon(
                Icons.help_outline,
                color: themeProvider.primaryTextColor,
                size: 24,
              ),
              tooltip: 'Help & Instructions',
            ),
            const SizedBox(width: 8),
            // Profile icon
            GestureDetector(
              onTap: onProfileTap,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6366F1),
                  border: Border.all(
                    color: themeProvider.borderColor,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
