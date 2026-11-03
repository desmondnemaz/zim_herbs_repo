import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
import 'package:zim_herbs_repo/features/repository/ailments/domain/entities/ailment.dart';

/// A reusable, compact card for displaying an [Ailment] with review, view, and moderation actions.
/// Inspired by HerbReviewCard and RemedyReviewCard for clean mobile and desktop readability.
class AilmentReviewCard extends StatelessWidget {
  final Ailment ailment;
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
  final bool showCategoryChip;

  static const _fallback = Ailment(id: '', name: '');

  const AilmentReviewCard({
    super.key,
    Ailment? ailment,
    Ailment? condition,
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
    bool? showCategoryChip,
    bool? showSystemChip,
  })  : ailment = ailment ?? condition ?? _fallback,
        showCategoryChip = showSystemChip ?? showCategoryChip ?? true;

  /// Backward compatibility constructor for Condition
  const AilmentReviewCard.forCondition({
    super.key,
    required Ailment condition,
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
    bool showSystemChip = true,
  })  : ailment = condition,
        showCategoryChip = showSystemChip;

  Ailment get condition => ailment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = getAilmentCategoryColor(ailment.ailmentCategory);
    final categorySvg = getAilmentCategorySvg(ailment.ailmentCategory);
    final categoryLabel = ailmentCategoryLabel(ailment.ailmentCategory);

    final hasDesc = ailment.description != null &&
        ailment.description!.trim().isNotEmpty;
    final hasSymptoms = ailment.symptoms.isNotEmpty;
    final descText = hasDesc
        ? ailment.description!.trim()
        : (hasSymptoms
            ? 'Symptoms: ${ailment.symptoms.join(", ")}'
            : 'No summary description provided.');
    final isPlaceholder = !hasDesc && !hasSymptoms;

    final bodyPartsSubtitle = ailment.bodyParts.isNotEmpty
        ? 'Targeted: ${ailment.bodyParts.map((b) => b.nameEn).join(", ")}'
        : '$categoryLabel Category';

    final effectiveActionIcon = actionIcon ?? Icons.visibility_outlined;

    return Card(
      color: backgroundColor,
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: categoryColor.withValues(alpha: 0.35),
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
                      color: categoryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: categoryColor.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(11),
                    child: SvgPicture.asset(
                      categorySvg,
                      colorFilter: ColorFilter.mode(
                        categoryColor,
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
                                ailment.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (showCategoryChip) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: categoryColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: categoryColor.withValues(alpha: 0.35),
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
                                        color: categoryColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      categoryLabel,
                                      style: TextStyle(
                                        color: categoryColor,
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
                            color: ailment.bodyParts.isNotEmpty
                                ? categoryColor.withValues(alpha: 0.9)
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

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (ailment.symptoms.isNotEmpty ||
                      ailment.precautions.isNotEmpty)
                    Expanded(
                      child: Text(
                        [
                          if (ailment.symptoms.isNotEmpty)
                            '${ailment.symptoms.length} ${ailment.symptoms.length == 1 ? 'symptom' : 'symptoms'}',
                          if (ailment.precautions.isNotEmpty)
                            '${ailment.precautions.length} ${ailment.precautions.length == 1 ? 'precaution' : 'precautions'}',
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

/// Backward compatibility alias
typedef ConditionReviewCard = AilmentReviewCard;
