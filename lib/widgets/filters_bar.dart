import 'package:flutter/material.dart';

class FiltersBar extends StatelessWidget {
  final List<String> filters;
  final int selectedIndex;
  final ValueChanged<int> onFilterSelected;

  const FiltersBar({
    super.key,
    required this.filters,
    required this.selectedIndex,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          return ChoiceChip(
            label: Text(filters[index]),
            selected: isSelected,
            onSelected: (_) => onFilterSelected(index),
            selectedColor: const Color(0xFF6366F1),
            backgroundColor: const Color(0xFFF1F5F9),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF1E293B),
              fontWeight: FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          );
        },
      ),
    );
  }
}
