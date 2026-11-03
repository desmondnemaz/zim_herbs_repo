import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/core/components/ailment_review_card.dart';
import 'package:zim_herbs_repo/core/components/public_ailment_card.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import '../../domain/entities/ailment.dart';
import '../ailment_details.dart';

class DesktopAilmentList extends StatelessWidget {
  const DesktopAilmentList({
    super.key,
    List<Ailment>? ailments,
    List<Ailment>? conditions,
    required this.rs,
    required this.onRefresh,
    this.onEdit,
    this.onDelete,
    this.isPublicView = false,
  }) : ailments = ailments ?? conditions ?? const [];

  final List<Ailment> ailments;
  final ResponsiveSize rs;
  final Future<void> Function() onRefresh;
  final Function(Ailment)? onEdit;
  final Function(Ailment)? onDelete;
  final bool isPublicView;

  // Backward-compatible alias
  List<Ailment> get conditions => ailments;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 460,
          mainAxisExtent: 200,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: ailments.length,
        itemBuilder: (context, index) {
          final ailment = ailments[index];

          if (isPublicView) {
            return PublicAilmentCard(
              ailment: ailment,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AilmentDetailsPage(
                          ailmentId: ailment.id,
                          isPublicView: isPublicView,
                        ),
                  ),
                );
              },
            );
          }

          return AilmentReviewCard(
            ailment: ailment,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AilmentDetailsPage(
                          ailmentId: ailment.id,
                          isPublicView: isPublicView,
                        ),
                ),
              );
            },
            onEdit: onEdit != null ? () => onEdit!(ailment) : null,
            onDelete: onDelete != null ? () => onDelete!(ailment) : null,
          );
        },
      ),
    );
  }
}

/// Backward compatibility typedef
typedef DesktopConditionList = DesktopAilmentList;
