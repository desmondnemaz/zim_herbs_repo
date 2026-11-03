import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
import 'package:zim_herbs_repo/features/repository/ailments/domain/entities/ailment.dart';

/// A dedicated, read-only card for displaying ailments on the public consumer/learner catalog.
///
/// Designed strictly for public browsing:
/// - Displays ailment name, category badge, symptoms summary, and body parts.
/// - Features a clean 'Explore Remedies' action button.
/// - Contains ZERO administrative code: NO edit dialog, NO delete confirmation, NO 3-dots popup, and NO checkboxes.
class PublicAilmentCard extends StatelessWidget {
  final Ailment ailment;
  final VoidCallback onTap;
  final String actionLabel;
  final Color backgroundColor;
  final double elevation;
  final bool showSymptoms;

  static const _fallback = Ailment(id: '', name: '');

  const PublicAilmentCard({
    super.key,
    Ailment? ailment,
    Ailment? condition,
    required this.onTap,
    this.actionLabel = 'Explore Remedies',
    this.backgroundColor = Colors.white,
    this.elevation = 1.5,
    this.showSymptoms = false,
  }) : ailment = ailment ?? condition ?? _fallback;

  Ailment get condition => ailment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSymptoms = ailment.symptoms.isNotEmpty;
    final hasBodyParts = ailment.bodyParts.isNotEmpty;
    final categoryColor = getAilmentCategoryColor(ailment.ailmentCategory);

    return Card(
      color: backgroundColor,
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.18),
          width: 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isBounded = constraints.maxHeight.isFinite;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: isBounded
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header: Icon badge & Ailment Name + Category
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: categoryColor.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.medical_information_rounded,
                              color: categoryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ailment.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                // Category chip
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: categoryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    ailmentCategoryLabel(ailment.ailmentCategory),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: categoryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Description preview
                      if (ailment.description != null &&
                          ailment.description!.trim().isNotEmpty) ...[
                        Text(
                          ailment.description!.trim(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                      ],

                      // Symptoms preview (cut by default on public cards to prevent overflow and keep cards clean)
                      if (showSymptoms && hasSymptoms) ...[
                        Text(
                          'Common symptoms: ${ailment.symptoms.take(3).join(', ')}',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                      ],

                      // Affected body parts (plain text per user request)
                      if (hasBodyParts) ...[
                        Text(
                          'Affected: ${ailment.bodyParts.map((bp) => bp.displayName).join(", ")}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                  if (!isBounded) const SizedBox(height: 10),

                  // Footer: Explore remedies button
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonalIcon(
                      onPressed: onTap,
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: Text(actionLabel),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Backward compatibility alias
typedef PublicConditionCard = PublicAilmentCard;
