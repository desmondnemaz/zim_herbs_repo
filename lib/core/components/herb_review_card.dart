import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/core/components/validation_status_chip.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';

/// A reusable, compact card for displaying an Herb (accepting either [Herb] domain entity or [HerbModel])
/// with review, view-only, selection, and moderation actions.
/// Designed for clean mobile readability with a customizable background (defaulting to white).
class HerbReviewCard extends StatelessWidget {
  /// Accepts either a domain [Herb] entity or a data [HerbModel].
  final dynamic herb;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onAction;
  final String actionLabel;
  final IconData? actionIcon;
  final Color backgroundColor;
  final double elevation;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool?>? onToggleSelect;
  final Widget? trailing;
  final bool showAction;
  final bool showStatusChip;
  final String? currentUserId;

  const HerbReviewCard({
    super.key,
    required this.herb,
    required this.onTap,
    this.onLongPress,
    this.onAction,
    this.actionLabel = 'Review',
    this.actionIcon,
    this.backgroundColor = Colors.white,
    this.elevation = 1.5,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onToggleSelect,
    this.trailing,
    this.showAction = true,
    this.showStatusChip = true,
    this.currentUserId,
  });

  String get _nameEn => herb.nameEn as String;
  String? get _nameSn => herb.nameSn as String?;
  String? get _nameNd => herb.nameNd as String?;
  String? get _description => herb.description as String?;
  bool get _isApproved => herb.isApproved as bool;
  RecordValidationStatus get _validationStatus =>
      herb.validationStatus as RecordValidationStatus;
  String? get _primaryImageUrl => herb.primaryImageUrl as String?;

  String? get _createdBy {
    try {
      final dynamic cb = (herb as dynamic).createdBy;
      if (cb != null) return cb.toString();
    } catch (_) {}
    return null;
  }

  bool get _isAuthor =>
      currentUserId != null && _createdBy != null && _createdBy == currentUserId;

  int get _remediesCount {
    try {
      final dynamic remedies = (herb as dynamic).remedies;
      if (remedies is List) {
        return remedies.length;
      }
    } catch (_) {}
    return 0;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final vernacularNames = [
      if (_nameSn != null && _nameSn!.trim().isNotEmpty)
        'Shona: ${_nameSn!.trim()}',
      if (_nameNd != null && _nameNd!.trim().isNotEmpty)
        'Ndebele: ${_nameNd!.trim()}',
    ];
    final vernacularSubtitle = vernacularNames.isNotEmpty
        ? vernacularNames.join(' • ')
        : 'Vernacular names not specified';

    final hasDescription =
        _description != null && _description!.trim().isNotEmpty;
    final descriptionText = hasDescription
        ? _description!.trim()
        : 'No summary description provided.';

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

                  // Herb Thumbnail
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      image: _primaryImageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(_primaryImageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _primaryImageUrl == null
                        ? Icon(Icons.local_florist,
                            color: Colors.green.shade700)
                        : null,
                  ),
                  const SizedBox(width: 14),

                  // Info Header & Description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      _nameEn,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // "My Creation" is a learner-only tag; staff views
                                  // (showStatusChip) treat every herb uniformly.
                                  if (_isAuthor && !showStatusChip) ...[
                                    const SizedBox(width: 6),
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
                                ],
                              ),
                            ),
                            if (showStatusChip)
                              ValidationStatusChip(
                                status: _validationStatus,
                              )
                            else if (_isAuthor)
                              _buildCreatorStatusChip(),
                            if (trailing != null) ...[
                              const SizedBox(width: 4),
                              trailing!,
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          vernacularSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: vernacularNames.isEmpty
                                ? FontStyle.italic
                                : FontStyle.normal,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: vernacularNames.isEmpty ? 0.45 : 0.65,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          descriptionText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            fontStyle: hasDescription
                                ? FontStyle.normal
                                : FontStyle.italic,
                            color: hasDescription
                                ? theme.colorScheme.onSurface
                                    .withValues(alpha: 0.75)
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Streamlined Card Action Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_remediesCount > 0)
                    Text(
                      '$_remediesCount associated ${_remediesCount == 1 ? 'remedy' : 'remedies'}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.55),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  if (showAction)
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
