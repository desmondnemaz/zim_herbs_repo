import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/core/components/herb_review_card.dart';
import 'package:zim_herbs_repo/core/components/public_herb_card.dart';
import 'package:zim_herbs_repo/core/theme/spacing.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/features/repository/herbs/domain/entities/herb.dart';
import 'package:zim_herbs_repo/features/repository/herbs/presentation/pages/herb_details.dart';

/// Reusable mobile list of herbs with clean 'View' action cards.
/// Edits and management actions are relocated strictly to the full detail page.
class MobileHerbList extends StatelessWidget {
  const MobileHerbList({
    super.key,
    required this.filteredHerbs,
    required this.rs,
    this.onView,
    this.isSelectionMode = false,
    this.selectedHerbIds = const {},
    this.onToggleSelect,
    this.onLongPress,
    this.showStatusChip = false,
    this.currentUserId,
    this.isPublicView = false,
  });

  final ResponsiveSize rs;
  final List<Herb> filteredHerbs;
  final Function(Herb)? onView;
  final bool isSelectionMode;
  final Set<String> selectedHerbIds;
  final ValueChanged<Herb>? onToggleSelect;
  final ValueChanged<Herb>? onLongPress;
  final bool showStatusChip;
  final String? currentUserId;
  final bool isPublicView;

  void _navigateToDetails(BuildContext context, Herb herb) {
    if (onView != null) {
      onView!(herb);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HerbDetailsPage(
            herbId: herb.id,
            isPublicView: isPublicView,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.all(defaultPadding),
      itemCount: filteredHerbs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final herb = filteredHerbs[index];

        if (isPublicView) {
          return PublicHerbCard(
            herb: herb,
            onTap: () => _navigateToDetails(context, herb),
          );
        }

        final isSelected = selectedHerbIds.contains(herb.id);

        return HerbReviewCard(
          herb: herb,
          currentUserId: currentUserId,
          isSelected: isSelected,
          isSelectionMode: isSelectionMode,
          onToggleSelect: (_) => onToggleSelect?.call(herb),
          showStatusChip: showStatusChip,
          actionLabel: 'View',
          actionIcon: Icons.visibility_outlined,
          onTap: () {
            if (isSelectionMode) {
              onToggleSelect?.call(herb);
            } else {
              _navigateToDetails(context, herb);
            }
          },
          onLongPress: () {
            if (!isSelectionMode) {
              onLongPress?.call(herb);
            } else {
              onToggleSelect?.call(herb);
            }
          },
          onAction: () => _navigateToDetails(context, herb),
          trailing: isSelectionMode
              ? (isSelected
                  ? Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    )
                  : null)
              : null,
        );
      },
    );
  }
}
