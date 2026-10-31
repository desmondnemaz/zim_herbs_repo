import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
import 'package:zim_herbs_repo/features/repository/conditions/domain/entities/condition.dart';

/// A reusable, compact card for displaying a [Condition] with review, view, and moderation actions.
/// Inspired by HerbReviewCard and RemedyReviewCard for clean mobile and desktop readability.
class ConditionReviewCard extends StatelessWidget {
  final Condition condition;
  final VoidCallback onTap;
  final VoidCallback? onAction;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String actionLabel;
  final IconData? actionIcon;
  final Color backgroundColor;
  final double elevation;
  final Widget? trailing;
  final bool showAction;
  final bool showSystemChip;

  const ConditionReviewCard({
    super.key,
    required this.condition,
    required this.onTap,
    this.onAction,
    this.onEdit,
    this.onDelete,
    this.actionLabel = 'View Details',
    this.actionIcon,
    this.backgroundColor = Colors.white,
    this.elevation = 1.5,
    this.trailing,
    this.showAction = true,
    this.showSystemChip = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final systemColor = getBodySystemColor(condition.bodySystem);
    final systemSvg = getBodySystemSvg(condition.bodySystem);
    final systemLabel = bodySystemLabel(condition.bodySystem);

    final hasDesc = condition.description != null &&
        condition.description!.trim().isNotEmpty;
    final hasSymptoms = condition.symptoms.isNotEmpty;
    final descText = hasDesc
        ? condition.description!.trim()
        : (hasSymptoms
            ? 'Symptoms: ${condition.symptoms.join(", ")}'
            : 'No summary description provided.');
    final isPlaceholder = !hasDesc && !hasSymptoms;

    final bodyPartsSubtitle = condition.bodyParts.isNotEmpty
        ? 'Targeted: ${condition.bodyParts.map((b) => b.nameEn).join(", ")}'
        : '$systemLabel System';

    final effectiveActionIcon = actionIcon ?? Icons.visibility_outlined;

    return Card(
      color: backgroundColor,
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: systemColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon badge thumbnail
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: systemColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: systemColor.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(11),
                    child: SvgPicture.asset(
                      systemSvg,
                      colorFilter: ColorFilter.mode(
                        systemColor,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Middle info column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                condition.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (showSystemChip) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: systemColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: systemColor.withValues(alpha: 0.35),
                                    width: 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: systemColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      systemLabel,
                                      style: TextStyle(
                                        color: systemColor,
                                        fontSize: 11.0,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (trailing != null) ...[
                              const SizedBox(width: 4),
                              trailing!,
                            ] else if (onEdit != null || onDelete != null) ...[
                              PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert,
                                  size: 19,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                                padding: EdgeInsets.zero,
                                onSelected: (val) {
                                  if (val == 'edit') onEdit?.call();
                                  if (val == 'delete') onDelete?.call();
                                },
                                itemBuilder: (ctx) => [
                                  if (onEdit != null)
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined, size: 18),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                  if (onDelete != null)
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline,
                                              color: Colors.red, size: 18),
                                          SizedBox(width: 8),
                                          Text('Delete',
                                              style:
                                                  TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          bodyPartsSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: condition.bodyParts.isNotEmpty
                                ? systemColor.withValues(alpha: 0.9)
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.55),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          descText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            fontStyle: isPlaceholder
                                ? FontStyle.italic
                                : FontStyle.normal,
                            color: isPlaceholder
                                ? theme.colorScheme.onSurface
                                    .withValues(alpha: 0.45)
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Streamlined Action row (matching HerbReviewCard pattern)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (condition.symptoms.isNotEmpty ||
                      condition.precautions.isNotEmpty)
                    Expanded(
                      child: Text(
                        [
                          if (condition.symptoms.isNotEmpty)
                            '${condition.symptoms.length} ${condition.symptoms.length == 1 ? 'symptom' : 'symptoms'}',
                          if (condition.precautions.isNotEmpty)
                            '${condition.precautions.length} ${condition.precautions.length == 1 ? 'precaution' : 'precautions'}',
                        ].join(' • '),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.55),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  else
                    const Spacer(),
                  if (showAction) ...[
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      icon: Icon(effectiveActionIcon, size: 16),
                      label: Text(actionLabel),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: onAction ?? onTap,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
