import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zim_herbs_repo/features/repository/conditions/domain/entities/condition.dart';
import 'package:zim_herbs_repo/features/repository/conditions/presentation/condition_details.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';

class DesktopConditionList extends StatelessWidget {
  const DesktopConditionList({
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
      child: GridView.builder(
        padding: EdgeInsets.all(rs.defaultPadding),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 220,
          crossAxisSpacing: rs.gridSpacing,
          mainAxisSpacing: rs.gridSpacing,
          childAspectRatio: 0.9,
        ),
        itemCount: conditions.length,
        itemBuilder: (context, index) {
          final condition = conditions[index];

          return InkWell(
            borderRadius: BorderRadius.circular(rs.borderRadius),
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
            child: Card(
              color: Theme.of(context).colorScheme.primary,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(rs.borderRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child:
                          (onEdit != null || onDelete != null)
                              ? PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  Icons.more_vert,
                                  size: 18,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
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
                                              Icon(Icons.edit, size: 18),
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
                                                size: 18,
                                                color: Colors.red,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Delete',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                              )
                              : const SizedBox(height: 18),
                    ),
                    CircleAvatar(
                      radius: rs.icon / 2,
                      backgroundColor: getBodySystemColor(
                        condition.bodySystem,
                      ).withValues(alpha: 0.2),
                      child: SvgPicture.asset(
                        getBodySystemSvg(condition.bodySystem),
                        width: rs.icon / 1.5,
                        height: rs.icon / 1.5,
                        colorFilter: ColorFilter.mode(
                          getBodySystemColor(condition.bodySystem),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      condition.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: rs.bodyFont,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bodySystemLabel(condition.bodySystem),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: rs.captionFont,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
