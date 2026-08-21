import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zim_herbs_repo/features/repository/conditions/domain/entities/condition.dart';
import 'package:zim_herbs_repo/features/repository/conditions/presentation/condition_details.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';

class MobileConditionList extends StatelessWidget {
  const MobileConditionList({
    super.key,
    required this.conditions,
    required this.rs,
    required this.onRefresh,
    this.onEdit,
    this.onDelete,
  });

  final List<Condition> conditions;
  final ResponsiveSize rs;
  final Future<void> Function() onRefresh;
  final Function(Condition)? onEdit;
  final Function(Condition)? onDelete;

  @override
  Widget build(BuildContext context) {
    if (conditions.isEmpty) {
      return const Center(child: Text('No conditions found'));
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: EdgeInsets.all(rs.defaultPadding),
        itemCount: conditions.length,
        separatorBuilder: (_, _) => SizedBox(height: rs.rowSpacing),
        itemBuilder: (context, index) {
          final condition = conditions[index];
          return Card(
            color: Theme.of(context).colorScheme.primary,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(rs.borderRadius),
            ),
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            ConditionDetailsPage(conditionId: condition.id),
                  ),
                );
              },
              leading: CircleAvatar(
                radius: rs.icon / 2.5,
                backgroundColor: getBodySystemColor(
                  condition.bodySystem,
                ).withValues(alpha: 0.2),
                child: SvgPicture.asset(
                  getBodySystemSvg(condition.bodySystem),
                  width: rs.icon / 2,
                  height: rs.icon / 2,
                  colorFilter: ColorFilter.mode(
                    getBodySystemColor(condition.bodySystem),
                    BlendMode.srcIn,
                  ),
                ),
              ),
              title: Text(
                condition.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: rs.subtitleFont,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              subtitle: Text(
                bodySystemLabel(condition.bodySystem),
                style: TextStyle(
                  fontSize: rs.captionFont,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              trailing:
                  (onEdit != null || onDelete != null)
                      ? PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        onSelected: (value) {
                          if (value == 'edit') {
                            onEdit?.call(condition);
                          } else if (value == 'delete') {
                            onDelete?.call(condition);
                          }
                        },
                        itemBuilder:
                            (context) => [
                              if (onEdit != null)
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 20),
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
                                      Icon(
                                        Icons.delete,
                                        size: 20,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                      )
                      : null,
            ),
          );
        },
      ),
    );
  }
}
