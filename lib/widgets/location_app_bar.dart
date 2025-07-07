import 'package:flutter/material.dart';

class LocationAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String location;
  final VoidCallback onProfileTap;
  final VoidCallback onLocationTap;

  const LocationAppBar({
    super.key,
    required this.location,
    required this.onProfileTap,
    required this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.location_on, color: Color(0xFF6366F1)),
        onPressed: onLocationTap,
      ),
      title: Text(
        location,
        style: const TextStyle(
          color: Color(0xFF1E293B),
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.person_outline, color: Color(0xFF6366F1)),
          onPressed: onProfileTap,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
