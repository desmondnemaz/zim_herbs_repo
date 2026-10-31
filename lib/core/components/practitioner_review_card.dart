import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/features/admin/moderation/data/models/herbalist_moderation_model.dart';

/// A reusable, compact card for displaying an herbalist / practitioner profile with review actions.
/// Designed for clean mobile readability with a customizable background (defaulting to white).
class PractitionerReviewCard extends StatelessWidget {
  final HerbalistModerationModel herbalist;
  final VoidCallback onTap;
  final VoidCallback? onAction;
  final String actionLabel;
  final IconData actionIcon;
  final Color backgroundColor;
  final double elevation;

  const PractitionerReviewCard({
    super.key,
    required this.herbalist,
    required this.onTap,
    this.onAction,
    this.actionLabel = 'Review',
    this.actionIcon = Icons.rate_review_outlined,
    this.backgroundColor = Colors.white,
    this.elevation = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = herbalist.isVerified
        ? Colors.green
        : (herbalist.isRejected ? Colors.red : Colors.amber.shade800);

    return Card(
      color: backgroundColor,
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: statusColor.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.indigo.shade100,
                    backgroundImage: herbalist.avatarUrl != null
                        ? NetworkImage(herbalist.avatarUrl!)
                        : null,
                    child: herbalist.avatarUrl == null
                        ? Text(
                            herbalist.fullName.isNotEmpty
                                ? herbalist.fullName[0].toUpperCase()
                                : 'P',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo.shade800,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          herbalist.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          herbalist.email,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (herbalist.phoneNumber != null)
                          Text(
                            'Phone: ${herbalist.phoneNumber}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  buildStatusBadge(
                    herbalist.verificationStatus.toUpperCase(),
                    statusColor,
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildMetaInfo(
                      Icons.school_outlined,
                      'Specialisation',
                      herbalist.specialisation,
                    ),
                  ),
                  Expanded(
                    child: _buildMetaInfo(
                      Icons.history_toggle_off_rounded,
                      'Experience',
                      '${herbalist.yearsOfExperience} years',
                    ),
                  ),
                  if (herbalist.location != null)
                    Expanded(
                      child: _buildMetaInfo(
                        Icons.location_on_outlined,
                        'Location',
                        herbalist.location!,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Streamlined Action Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.tonalIcon(
                    icon: Icon(actionIcon, size: 16),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaInfo(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  static Widget buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
