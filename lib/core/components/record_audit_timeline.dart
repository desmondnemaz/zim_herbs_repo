import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/core/components/validation_status_chip.dart';
import 'package:zim_herbs_repo/core/models/record_audit_entry.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';

/// An interactive and visual vertical timeline widget displaying the
/// validation pipeline history and audit traceability for a repository record.
class RecordAuditTimeline extends StatelessWidget {
  final List<RecordAuditEntry> history;
  final RecordValidationStatus currentStatus;
  final String? title;

  const RecordAuditTimeline({
    super.key,
    required this.history,
    required this.currentStatus,
    this.title = 'Validation & Audit History',
  });

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[dt.month - 1];
    final day = dt.day.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$month $day, $year • $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        color: Color(0xFF2E7D32),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title ?? 'Validation & Audit History',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Step-by-step verification lifecycle and user traceability',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ValidationStatusChip(status: currentStatus),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 20),

          // Timeline items
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final entry = history[index];
              final isLast = index == history.length - 1;
              return _buildTimelineStep(context, entry, isLast: isLast);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(
    BuildContext context,
    RecordAuditEntry entry, {
    required bool isLast,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isRejected = entry.stage == RecordValidationStatus.rejected;

    // Node icon & colors
    Color nodeColor;
    Color nodeBorderColor;
    Widget nodeIcon;

    if (isRejected) {
      nodeColor = const Color(0xFFDC2626);
      nodeBorderColor = const Color(0xFFDC2626);
      nodeIcon = const Icon(Icons.close_rounded, color: Colors.white, size: 16);
    } else if (entry.isCompleted) {
      nodeColor = const Color(0xFF16A34A);
      nodeBorderColor = const Color(0xFF16A34A);
      nodeIcon = const Icon(Icons.check_rounded, color: Colors.white, size: 16);
    } else if (entry.isCurrent) {
      nodeColor = entry.stage.color;
      nodeBorderColor = entry.stage.color;
      nodeIcon = Icon(entry.stage.icon, color: Colors.white, size: 14);
    } else {
      nodeColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
      nodeBorderColor = isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);
      nodeIcon = Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          shape: BoxShape.circle,
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Node and connector line
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: (entry.isCompleted || entry.isCurrent || isRejected)
                      ? nodeColor
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: nodeBorderColor,
                    width: 2,
                  ),
                  boxShadow: (entry.isCurrent || entry.isCompleted)
                      ? [
                          BoxShadow(
                            color: nodeColor.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Center(child: nodeIcon),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: entry.isCompleted && !isRejected
                        ? const Color(0xFF16A34A).withValues(alpha: 0.5)
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Right: Content details
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step Title & Status Badge
                  Row(
                    children: [
                      Text(
                        entry.stage.label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: (entry.isCompleted || entry.isCurrent || isRejected)
                              ? (isDark ? Colors.white : const Color(0xFF0F172A))
                              : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStageBadge(entry),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Actor Information
                  if (entry.actorId != null && entry.actorId!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            size: 14,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'By: ${entry.actorName ?? entry.actorId}',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Timestamp
                  if (entry.timestamp != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDateTime(entry.timestamp!),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Rejection reason or moderator notes callout
                  if (entry.notes != null && entry.notes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isRejected
                            ? (isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2))
                            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isRejected
                              ? const Color(0xFFFCA5A5)
                              : const Color(0xFFCBD5E1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isRejected
                                    ? Icons.warning_amber_rounded
                                    : Icons.notes_rounded,
                                size: 16,
                                color: isRejected
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isRejected
                                    ? 'Rejection Reason / Required Remediation:'
                                    : 'Moderator Notes:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isRejected
                                      ? const Color(0xFFDC2626)
                                      : (isDark ? Colors.white : const Color(0xFF334155)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            entry.notes!,
                            style: TextStyle(
                              fontSize: 13,
                              color: isRejected
                                  ? (isDark ? const Color(0xFFFECACA) : const Color(0xFF991B1B))
                                  : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageBadge(RecordAuditEntry entry) {
    if (entry.stage == RecordValidationStatus.rejected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'Action Required',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFFDC2626),
          ),
        ),
      );
    }

    if (entry.isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF16A34A).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'Completed',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF16A34A),
          ),
        ),
      );
    }

    if (entry.isCurrent) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: entry.stage.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'In Progress',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: entry.stage.color,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF94A3B8).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Pending',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }
}
