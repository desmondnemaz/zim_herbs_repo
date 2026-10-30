import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';

/// A reusable badge/chip representing the current validation stage of a record.
class ValidationStatusChip extends StatelessWidget {
  final RecordValidationStatus status;
  final bool showIcon;
  final bool isOutlined;
  final double? fontSize;
  final EdgeInsetsGeometry padding;

  const ValidationStatusChip({
    super.key,
    required this.status,
    this.showIcon = true,
    this.isOutlined = false,
    this.fontSize,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    final effectiveFontSize = fontSize ?? 12.0;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isOutlined ? color.withValues(alpha: 0.04) : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOutlined ? color.withValues(alpha: 0.8) : color.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showIcon) ...[
            Icon(
              status.icon,
              size: effectiveFontSize + 3,
              color: color,
            ),
            const SizedBox(width: 5),
          ],
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontSize: effectiveFontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
