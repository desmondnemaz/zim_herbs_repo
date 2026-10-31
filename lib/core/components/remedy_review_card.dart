import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zim_herbs_repo/core/components/validation_status_chip.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';

/// A reusable, compact card for displaying a remedy (accepting either [Remedy] domain entity
/// or [RemedyModel]) with review, view-only, and moderation actions.
/// Designed for clean mobile and desktop readability inspired by HerbReviewCard.
class RemedyReviewCard extends StatelessWidget {
  /// Accepts either a domain [Remedy] entity or a data [RemedyModel].
  final dynamic remedy;
  final VoidCallback onTap;
  final VoidCallback? onAction;
  final VoidCallback? onToggleApproval;
  final VoidCallback? onReject;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String actionLabel;
  final IconData? actionIcon;
  final Color backgroundColor;
  final double elevation;
  final Widget? trailing;
  final bool showAction;
  final bool showStatusChip;
  final bool isSelected;
  final bool isSelectionMode;
  final ValueChanged<bool?>? onToggleSelect;
  final VoidCallback? onLongPress;
  final String? currentUserId;

  const RemedyReviewCard({
    super.key,
    required this.remedy,
    required this.onTap,
    this.onAction,
    this.onToggleApproval,
    this.onReject,
    this.onEdit,
    this.onDelete,
    this.actionLabel = 'View Details',
    this.actionIcon,
    this.backgroundColor = Colors.white,
    this.elevation = 1.5,
    this.trailing,
    this.showAction = true,
    this.showStatusChip = true,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onToggleSelect,
    this.onLongPress,
    this.currentUserId,
  });

  String get _name {
    try {
      final dynamic dn = (remedy as dynamic).displayName;
      if (dn is String && dn.isNotEmpty) return dn;
    } catch (_) {}
    try {
      final dynamic n = (remedy as dynamic).name;
      if (n is String && n.isNotEmpty) return n;
    } catch (_) {}
    return 'Unnamed Remedy';
  }

  String get _preparation {
    try {
      final dynamic prep = (remedy as dynamic).preparation;
      if (prep is String) return prep.trim();
    } catch (_) {}
    return '';
  }

  String? get _notes {
    try {
      final dynamic n = (remedy as dynamic).notes;
      if (n is String && n.trim().isNotEmpty) return n.trim();
    } catch (_) {}
    return null;
  }

  String? get _dosageAdults {
    try {
      final dynamic d = (remedy as dynamic).dosageAdults;
      if (d is String && d.trim().isNotEmpty) return d.trim();
    } catch (_) {}
    return null;
  }

  String? get _moderationComments {
    try {
      final dynamic mc = (remedy as dynamic).moderationComments;
      if (mc is String && mc.trim().isNotEmpty) return mc.trim();
    } catch (_) {}
    return null;
  }

  bool get _isApproved {
    try {
      final dynamic a = (remedy as dynamic).isApproved;
      if (a is bool) return a;
    } catch (_) {}
    return false;
  }

  RecordValidationStatus get _validationStatus {
    try {
      final dynamic vs = (remedy as dynamic).validationStatus;
      if (vs is RecordValidationStatus) return vs;
    } catch (_) {}
    return _isApproved
        ? RecordValidationStatus.published
        : RecordValidationStatus.submitted;
  }

  String? get _conditionName {
    try {
      final dynamic cond = (remedy as dynamic).condition;
      if (cond != null && cond.name != null) return cond.name.toString();
    } catch (_) {}
    try {
      final dynamic cn = (remedy as dynamic).conditionName;
      if (cn != null && cn.toString().trim().isNotEmpty) {
        return cn.toString().trim();
      }
    } catch (_) {}
    return null;
  }

  BodySystem? get _conditionBodySystem {
    try {
      final dynamic cond = (remedy as dynamic).condition;
      if (cond != null && cond.bodySystem != null) {
        return cond.bodySystem as BodySystem;
      }
    } catch (_) {}
    try {
      final dynamic bs = (remedy as dynamic).conditionBodySystem;
      if (bs != null && bs is BodySystem) return bs;
    } catch (_) {}
    return null;
  }

  int get _herbsCount {
    try {
      final dynamic herbs = (remedy as dynamic).remedyHerbs;
      if (herbs is List) return herbs.length;
    } catch (_) {}
    return 0;
  }

  String? get _createdBy {
    try {
      final dynamic cb = (remedy as dynamic).createdBy;
      if (cb is String && cb.isNotEmpty) return cb;
    } catch (_) {}
    return null;
  }

  bool get _isAuthor =>
      currentUserId != null && _createdBy != null && _createdBy == currentUserId;

  Widget _buildCreatorStatusChip() {
    final isPub = _isApproved || _validationStatus.isApproved;
    final color = isPub ? const Color(0xFF16A34A) : const Color(0xFFD97706);
    final label = isPub ? 'Published' : 'Pending Review';
    final icon = isPub ? Icons.check_circle_outline_rounded : Icons.schedule;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  IconData get _effectiveActionIcon {
    if (actionIcon != null) return actionIcon!;
    final normalized = actionLabel.toLowerCase().trim();
    if (normalized == 'view' || normalized == 'view details') {
      return Icons.visibility_outlined;
    } else if (normalized == 'edit') {
      return Icons.edit_note_rounded;
    }
    return Icons.rate_review_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final hasPrep = _preparation.isNotEmpty;
    final hasNotes = _notes != null;
    final descText = hasPrep
        ? 'Prep: $_preparation'
        : (hasNotes ? _notes! : 'No preparation notes provided.');
    final isPlaceholder = !hasPrep && !hasNotes;

    final systemColor = _conditionBodySystem != null
        ? getBodySystemColor(_conditionBodySystem!)
        : Colors.teal.shade700;

    final hasMenu = onToggleApproval != null ||
        onReject != null ||
        onEdit != null ||
        onDelete != null;

    final effectiveBgColor = isSelected
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
        : backgroundColor;

    final effectiveBorderSide = isSelected
        ? BorderSide(
            color: theme.colorScheme.primary,
            width: 2.0,
          )
        : ((_isAuthor && !showStatusChip)
            ? BorderSide(
                color: Colors.teal.shade400,
                width: 1.4,
              )
            : ((showStatusChip)
                ? BorderSide(
                    color: _isApproved
                        ? Colors.green.shade300
                        : Colors.amber.shade400,
                    width: 1.2,
                  )
                : BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.18),
                    width: 1.0,
                  )));

    return Card(
      color: effectiveBgColor,
      elevation: isSelected ? elevation + 1.5 : elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: effectiveBorderSide,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Optional selection checkbox
                  if (isSelectionMode) ...[
                    Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: Checkbox(
                        value: isSelected,
                        onChanged: onToggleSelect,
                        activeColor: theme.colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],

                  // Leading Thumbnail / Body System Badge
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
                    child: _conditionBodySystem != null
                        ? SvgPicture.asset(
                            getBodySystemSvg(_conditionBodySystem!),
                            colorFilter: ColorFilter.mode(
                              systemColor,
                              BlendMode.srcIn,
                            ),
                          )
                        : Icon(
                            Icons.auto_awesome,
                            color: systemColor,
                            size: 26,
                          ),
                  ),
                  const SizedBox(width: 14),

                  // Middle Info Block
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (showStatusChip) ...[
                              const SizedBox(width: 6),
                              ValidationStatusChip(
                                status: _validationStatus,
                              ),
                            ] else if (_isAuthor) ...[
                              const SizedBox(width: 6),
                              _buildCreatorStatusChip(),
                            ],
                            if (trailing != null) ...[
                              const SizedBox(width: 4),
                              trailing!,
                            ] else if (hasMenu) ...[
                              PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert,
                                  size: 19,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                                padding: EdgeInsets.zero,
                                onSelected: (val) {
                                  if (val == 'toggle_approval') {
                                    onToggleApproval?.call();
                                  } else if (val == 'reject') {
                                    onReject?.call();
                                  } else if (val == 'edit') {
                                    onEdit?.call();
                                  } else if (val == 'delete') {
                                    onDelete?.call();
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  if (onToggleApproval != null)
                                    PopupMenuItem(
                                      value: 'toggle_approval',
                                      child: Row(
                                        children: [
                                          Icon(
                                            _isApproved
                                                ? Icons.close
                                                : Icons.check_circle_outline,
                                            color: _isApproved
                                                ? Colors.amber
                                                : Colors.green,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _isApproved
                                                ? 'Unapprove'
                                                : 'Approve',
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (onReject != null &&
                                      _validationStatus !=
                                          RecordValidationStatus.rejected)
                                    const PopupMenuItem(
                                      value: 'reject',
                                      child: Row(
                                        children: [
                                          Icon(Icons.cancel_outlined,
                                              color: Colors.red, size: 18),
                                          SizedBox(width: 8),
                                          Text(
                                            'Reject',
                                            style:
                                                TextStyle(color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ),
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
                                          Text(
                                            'Delete',
                                            style:
                                                TextStyle(color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        if (_isAuthor && !showStatusChip) ...[
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.teal.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.teal.withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 11,
                                  color: Colors.teal,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'My Creation',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 2),
                        Text(
                          _conditionName != null
                              ? 'Target Condition: $_conditionName'
                              : 'Condition: General / Unspecified',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _conditionName != null
                                ? Colors.green.shade800
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
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
              if (_dosageAdults != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Dosage (Adults): $_dosageAdults',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
              if (_moderationComments != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.feedback_outlined,
                          size: 15, color: Colors.red.shade700),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Moderator Note: $_moderationComments',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),

              // Streamlined Action Row (matching HerbReviewCard & ConditionReviewCard)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      [
                        if (_herbsCount > 0)
                          '$_herbsCount ${_herbsCount == 1 ? 'herb' : 'herbs'} included',
                        if (_conditionBodySystem != null)
                          bodySystemLabel(_conditionBodySystem!),
                      ].join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                  if (showAction) ...[
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      icon: Icon(_effectiveActionIcon, size: 16),
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
