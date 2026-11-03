import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/core/components/ailment_review_card.dart';
import 'package:zim_herbs_repo/core/components/public_ailment_card.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import '../../domain/entities/ailment.dart';
import '../ailment_details.dart';

class MobileAilmentList extends StatelessWidget {
  const MobileAilmentList({
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
    if (ailments.isEmpty) {
      return const Center(child: Text('No ailments found'));
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: EdgeInsets.all(rs.defaultPadding),
        itemCount: ailments.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
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
                        AilmentDetailsPage(ailmentId: ailment.id),
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
                      AilmentDetailsPage(ailmentId: ailment.id),
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

/// Backward-compatible alias
typedef MobileConditionList = MobileAilmentList;
