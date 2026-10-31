import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
import 'package:zim_herbs_repo/features/repository/conditions/domain/entities/condition.dart';

/// A dedicated, read-only card for displaying medical conditions on the public consumer/learner catalog.
///
/// Designed strictly for public browsing:
/// - Displays condition name, body system badge, symptoms summary, and body parts chips.
/// - Features a clean 'Explore Remedies' action button.
/// - Contains ZERO administrative code: NO edit dialog, NO delete confirmation, NO 3-dots popup, and NO checkboxes.
class PublicConditionCard extends StatelessWidget {
  final Condition condition;
  final VoidCallback onTap;
  final String actionLabel;
  final Color backgroundColor;
  final double elevation;

  const PublicConditionCard({
    super.key,
    required this.condition,
    required this.onTap,
    this.actionLabel = 'Explore Remedies',
    this.backgroundColor = Colors.white,
    this.elevation = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSymptoms = condition.symptoms.isNotEmpty;
    final hasBodyParts = condition.bodyParts.isNotEmpty;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Icon badge & Condition Name + System
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.blue.shade200,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.medical_information_rounded,
                      color: Colors.blue.shade700,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          condition.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Body System chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            bodySystemLabel(condition.bodySystem),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Description preview
              if (condition.description != null &&
                  condition.description!.trim().isNotEmpty) ...[
                Text(
                  condition.description!.trim(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],

              // Symptoms or Body parts preview
              if (hasSymptoms) ...[
                Text(
                  'Common symptoms: ${condition.symptoms.take(3).join(', ')}',
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

              if (hasBodyParts) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: condition.bodyParts.take(3).map((bp) {
                    return Chip(
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      labelPadding: EdgeInsets.zero,
                      backgroundColor: Colors.grey.shade100,
                      label: Text(
                        bp.displayName,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
              ],

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
          ),
        ),
      ),
    );
  }
}
