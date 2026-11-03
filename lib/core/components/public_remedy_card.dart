import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/features/repository/remedies/domain/entities/remedy.dart';

/// A dedicated, read-only card for displaying remedies on the public consumer/learner catalog.
///
/// Designed strictly for public browsing:
/// - Displays remedy name, target condition badge, key herbs, method of use, and preparation preview.
/// - Features a clean 'View Remedy' action button.
/// - Contains ZERO administrative code: NO 3-dots popup, NO delete, NO edit, NO verify, and NO checkboxes.
class PublicRemedyCard extends StatelessWidget {
  final Remedy remedy;
  final VoidCallback onTap;
  final String actionLabel;
  final Color backgroundColor;
  final double elevation;

  const PublicRemedyCard({
    super.key,
    required this.remedy,
    required this.onTap,
    this.actionLabel = 'View Remedy',
    this.backgroundColor = Colors.white,
    this.elevation = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final conditionName = remedy.conditionName ?? 'General Wellness';
    final hasHerbs = remedy.remedyHerbs.isNotEmpty;

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
              // Header: Icon badge & Remedy Title
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.green.shade200,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.healing_rounded,
                      color: Colors.green.shade700,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                remedy.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (remedy.isApproved ||
                                remedy.validationStatus.isApproved) ...[
                              const SizedBox(width: 6),
                              _buildVerifiedTag(),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Condition chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.medical_services_outlined,
                                size: 13,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  conditionName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Method / Preparation preview
              if (remedy.preparation.trim().isNotEmpty) ...[
                Text(
                  remedy.preparation.trim(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],

              // Herbs used chips
              if (hasHerbs) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: remedy.remedyHerbs.take(3).map((rh) {
                    final herbTitle = rh.herbName ?? 'Herb';
                    return Chip(
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      labelPadding: EdgeInsets.zero,
                      backgroundColor: Colors.teal.shade50,
                      avatar: CircleAvatar(
                        radius: 8,
                        backgroundColor: Colors.teal.shade700,
                        child: const Icon(
                          Icons.local_florist,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                      label: Text(
                        ' $herbTitle',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.teal.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
              ],

              // Footer: View Remedy button
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

  Widget _buildVerifiedTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: const Color(0xFF15803D).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFF15803D).withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            size: 13,
            color: Color(0xFF15803D),
          ),
          SizedBox(width: 4),
          Text(
            'Verified',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF15803D),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
