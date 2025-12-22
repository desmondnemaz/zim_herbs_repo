import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zim_herbs_repo/features/conditions/data/repository/model.dart';
import 'package:zim_herbs_repo/features/conditions/presentation/condition_details.dart';
import 'package:zim_herbs_repo/utils/enums.dart';
import 'package:zim_herbs_repo/utils/responsive_sizes.dart';

class DesktopConditionList extends StatelessWidget {
  const DesktopConditionList({
    super.key,
    required this.conditions,
    required this.rs,
    required this.onRefresh,
    this.onEdit,
    this.onDelete,
  });

  final List<ConditionModel> conditions;
  final ResponsiveSize rs;
  final Future<void> Function() onRefresh;
  final Function(ConditionModel)? onEdit;
  final Function(ConditionModel)? onDelete;

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
              color: Theme.of(context).colorScheme.primary, // PRIMARY color
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(rs.borderRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: getBodySystemColor(
                          condition.bodySystem,
                        ).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(rs.borderRadius),
                        ),
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          getBodySystemSvg(condition.bodySystem),
                          width: rs.icon,
                          height: rs.icon,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(rs.padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          condition.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: rs.titleFont,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // text in white
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bodySystemLabel(condition.bodySystem),
                          style: TextStyle(
                            fontSize: rs.subtitleFont,
                            color: Colors.white70,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: PopupMenuButton<String>(
                            iconColor: Theme.of(context).colorScheme.onPrimary,
                            onSelected: (value) {
                              if (value == 'edit') onEdit?.call(condition);
                              if (value == 'delete') onDelete?.call(condition);
                            },
                            itemBuilder:
                                (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
