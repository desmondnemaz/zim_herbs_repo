import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/core/components/herb_review_card.dart';
import 'package:zim_herbs_repo/core/components/public_herb_card.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/features/repository/herbs/domain/entities/herb.dart';
import 'package:zim_herbs_repo/features/repository/herbs/presentation/pages/herb_details.dart';

class DesktopHerbList extends StatelessWidget {
  const DesktopHerbList({
    super.key,
    required this.filteredHerbs,
    required this.rs,
    this.onTapHerb,
    this.onDelete,
    this.onVerify,
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
  final ValueChanged<Herb>? onTapHerb;
  final Function(Herb)? onDelete;
  final Function(Herb)? onVerify;
  final bool isSelectionMode;
  final Set<String> selectedHerbIds;
  final ValueChanged<Herb>? onToggleSelect;
  final ValueChanged<Herb>? onLongPress;
  final bool showStatusChip;
  final String? currentUserId;
  final bool isPublicView;

  @override
  Widget build(BuildContext context) {
    if (filteredHerbs.isEmpty) {
      return const Center(child: Text('No herbs found'));
    }

    return GridView.builder(
      padding: EdgeInsets.all(rs.defaultPadding),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 460,
        mainAxisExtent: 190,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filteredHerbs.length,
      itemBuilder: (context, index) {
        final herb = filteredHerbs[index];

        if (isPublicView) {
          return PublicHerbCard(
            herb: herb,
            onTap: () {
              if (onTapHerb != null) {
                onTapHerb!(herb);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HerbDetailsPage(herbId: herb.id, isPublicView: isPublicView),
                  ),
                );
              }
            },
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
          actionLabel: 'View Details',
          actionIcon: Icons.visibility_outlined,
          onTap: () {
            if (isSelectionMode) {
              onToggleSelect?.call(herb);
            } else if (onTapHerb != null) {
              onTapHerb!(herb);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HerbDetailsPage(herbId: herb.id, isPublicView: isPublicView),
                ),
              );
            }
          },
          onLongPress: () {
            if (!isSelectionMode) {
              onLongPress?.call(herb);
            } else {
              onToggleSelect?.call(herb);
            }
          },
          onAction: () {
            if (onTapHerb != null) {
              onTapHerb!(herb);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HerbDetailsPage(herbId: herb.id, isPublicView: isPublicView),
                ),
              );
            }
          },
          trailing: (!isSelectionMode &&
                  ((!herb.isApproved && onVerify != null) || onDelete != null))
              ? PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'verify') {
                      onVerify?.call(herb);
                    } else if (value == 'delete') {
                      onDelete?.call(herb);
                    }
                  },
                  itemBuilder: (context) => [
                    if (!herb.isApproved && onVerify != null)
                      const PopupMenuItem(
                        value: 'verify',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.green, size: 18),
                            SizedBox(width: 8),
                            Text('Verify Herb',
                                style: TextStyle(color: Colors.green)),
                          ],
                        ),
                      ),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ),
                  ],
                  icon: const Icon(Icons.more_vert, size: 20),
                )
              : null,
        );
      },
    );
  }
}
