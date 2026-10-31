import 'package:flutter/material.dart';

/// A reusable, compact search bar with a customizable background (defaulting to white).
class AppSearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final Color backgroundColor;
  final double height;
  final Widget? leading;
  final VoidCallback? onClear;

  const AppSearchBar({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.controller,
    this.backgroundColor = Colors.white,
    this.height = 38.0,
    this.leading,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: TextField(
        controller: controller,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(fontSize: 13),
        onChanged: onChanged,
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: 12.5,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
          ),
          prefixIcon: leading ??
              Icon(
                Icons.search,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
          prefixIconConstraints: BoxConstraints(
            minWidth: 38,
            minHeight: height,
            maxHeight: height,
          ),
          suffixIcon: onClear != null
              ? IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(
                    minWidth: 36,
                    minHeight: height,
                    maxHeight: height,
                  ),
                  onPressed: onClear,
                )
              : null,
          suffixIconConstraints: onClear != null
              ? BoxConstraints(
                  minWidth: 36,
                  minHeight: height,
                  maxHeight: height,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}
