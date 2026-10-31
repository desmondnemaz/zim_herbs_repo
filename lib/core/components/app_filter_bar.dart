import 'package:flutter/material.dart';

/// Data class representing an individual filter option.
class FilterOption<T> {
  final String label;
  final T value;
  final int? count;
  final Color? activeColor;

  const FilterOption({
    required this.label,
    required this.value,
    this.count,
    this.activeColor,
  });

  String get displayLabel => count != null ? '$label ($count)' : label;
}

/// A reusable horizontal filter chips bar with a customizable chip background (defaulting to white).
class AppFilterBar<T> extends StatelessWidget {
  final List<FilterOption<T>> options;
  final T selectedValue;
  final ValueChanged<T> onSelected;
  final Color chipBackgroundColor;
  final EdgeInsetsGeometry padding;

  const AppFilterBar({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
    this.chipBackgroundColor = Colors.white,
    this.padding = const EdgeInsets.only(right: 20),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (int i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _buildChip(context, options[i], theme),
          ],
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildChip(
    BuildContext context,
    FilterOption<T> option,
    ThemeData theme,
  ) {
    final isSelected = option.value == selectedValue;
    final primary = option.activeColor ?? theme.colorScheme.primary;

    return ChoiceChip(
      showCheckmark: false,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      labelPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: -2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      label: Text(option.displayLabel),
      selected: isSelected,
      onSelected: (_) => onSelected(option.value),
      selectedColor: primary.withValues(alpha: 0.14),
      backgroundColor: chipBackgroundColor,
      side: BorderSide(
        color: isSelected
            ? primary.withValues(alpha: 0.6)
            : theme.colorScheme.outline.withValues(alpha: 0.22),
        width: 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        color: isSelected ? primary : Colors.grey.shade700,
      ),
      visualDensity: const VisualDensity(horizontal: -2, vertical: -3),
    );
  }
}
