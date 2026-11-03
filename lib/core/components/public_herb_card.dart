import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/features/repository/herbs/domain/entities/herb.dart';

/// A dedicated, read-only card for displaying herbs on the public customer/learner catalog.
///
/// Designed strictly for public browsing:
/// - Displays thumbnail, botanical name, vernacular names, summary description, and remedy count.
/// - Features a clean 'View Details' action button.
/// - Contains ZERO administrative code: NO 3-dots popup, NO delete, NO edit, NO verify, and NO checkboxes.
class PublicHerbCard extends StatelessWidget {
  final Herb herb;
  final VoidCallback onTap;
  final String actionLabel;
  final Color backgroundColor;
  final double elevation;

  const PublicHerbCard({
    super.key,
    required this.herb,
    required this.onTap,
    this.actionLabel = 'View Details',
    this.backgroundColor = Colors.white,
    this.elevation = 1.5,
  });

  String get _nameEn => herb.nameEn;
  String? get _nameSn => herb.nameSn;
  String? get _nameNd => herb.nameNd;
  String? get _description => herb.description;
  String? get _primaryImageUrl => herb.primaryImageUrl;

  int get _remediesCount {
    try {
      final dynamic remedies = (herb as dynamic).remedies;
      if (remedies is List) {
        return remedies.length;
      }
    } catch (_) {}
    return 0;
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        ? Icon(
                            Icons.local_florist,
                            color: Colors.green.shade700,
                          )
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
                              child: Text(
                                _nameEn,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (herb.isApproved ||
                                herb.validationStatus.isApproved) ...[
                              const SizedBox(width: 6),
                              _buildVerifiedTag(),
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

              // Public Card Action Row (Strictly 'View Details' - ZERO admin options)
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
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.visibility_outlined, size: 16),
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
                    onPressed: onTap,
                  ),
                ],
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
