import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/features/admin/moderation/data/models/supplier_moderation_model.dart';

/// A reusable, compact card for displaying a botanical supplier profile with review actions.
/// Designed for clean mobile readability and responsive grid/list presentation.
class SupplierReviewCard extends StatelessWidget {
  final SupplierModerationModel supplier;
  final VoidCallback onTap;
  final VoidCallback? onAction;
  final String actionLabel;
  final IconData actionIcon;
  final Color backgroundColor;
  final double elevation;

  const SupplierReviewCard({
    super.key,
    required this.supplier,
    required this.onTap,
    this.onAction,
    this.actionLabel = 'Review',
    this.actionIcon = Icons.rate_review_outlined,
    this.backgroundColor = Colors.white,
    this.elevation = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = supplier.isVerified
        ? Colors.green
        : (supplier.isRejected ? Colors.red : Colors.amber.shade800);

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
                    backgroundColor: Colors.blue.shade100,
                    backgroundImage: supplier.avatarUrl != null
                        ? NetworkImage(supplier.avatarUrl!)
                        : null,
                    child: supplier.avatarUrl == null
                        ? Icon(
                            Icons.storefront_rounded,
                            size: 24,
                            color: Colors.blue.shade800,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supplier.supplierName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Owner: ${supplier.fullName} (${supplier.email})',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (supplier.phoneNumber != null)
                          Text(
                            'Phone: ${supplier.phoneNumber}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              if (supplier.location != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          supplier.location!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (supplier.bio != null && supplier.bio!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Text(
                    supplier.bio!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  buildStatusBadge(
                    supplier.isVerified
                        ? 'APPROVED & PUBLISHED'
                        : (supplier.isRejected ? 'REJECTED' : 'PENDING APPROVAL'),
                    statusColor,
                  ),
                  if (onAction != null)
                    FilledButton.tonalIcon(
                      onPressed: onAction,
                      icon: Icon(actionIcon, size: 16),
                      label: Text(actionLabel),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
