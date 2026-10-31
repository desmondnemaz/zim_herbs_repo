import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/core/components/condition_review_card.dart';
import 'package:zim_herbs_repo/core/components/public_condition_card.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/features/repository/conditions/domain/entities/condition.dart';
import 'package:zim_herbs_repo/features/repository/conditions/presentation/condition_details.dart';

class DesktopConditionList extends StatelessWidget {
  const DesktopConditionList({
    super.key,
    required this.conditions,
    required this.rs,
    required this.onRefresh,
    this.onEdit,
    this.onDelete,
    this.isPublicView = false,
  });

  final List<Condition> conditions;
  final ResponsiveSize rs;
  final Future<void> Function() onRefresh;
  final Function(Condition)? onEdit;
  final Function(Condition)? onDelete;
  final bool isPublicView;

  @override
  Widget build(BuildContext context) {
    if (conditions.isEmpty) {
      return const Center(child: Text('No conditions found'));
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: GridView.builder(
        padding: EdgeInsets.all(rs.defaultPadding),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 460,
          mainAxisExtent: 180,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: conditions.length,
        itemBuilder: (context, index) {
          final condition = conditions[index];

          if (isPublicView) {
            return PublicConditionCard(
              condition: condition,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ConditionDetailsPage(conditionId: condition.id),
                  ),
                );
              },
            );
          }

          return ConditionReviewCard(
            condition: condition,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ConditionDetailsPage(conditionId: condition.id),
                ),
              );
            },
            onEdit: onEdit != null ? () => onEdit!(condition) : null,
            onDelete: onDelete != null ? () => onDelete!(condition) : null,
          );
        },
      ),
    );
  }
}
