import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zim_herbs_repo/features/conditions/data/repository/model.dart';
import 'package:zim_herbs_repo/features/conditions/presentation/condition_details.dart';
import 'package:zim_herbs_repo/utils/enums.dart';
import 'package:zim_herbs_repo/utils/responsive_sizes.dart';

class MobileConditionList extends StatelessWidget {
  const MobileConditionList({
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
      child: ListView.separated(
        padding: EdgeInsets.all(rs.defaultPadding),
        itemCount: conditions.length,
        separatorBuilder: (_, __) => SizedBox(height: rs.rowSpacing),
        itemBuilder: (context, index) {
          final condition = conditions[index];
          return Card(
            color: Theme.of(context).colorScheme.primary, // PRIMARY color
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
                  width: rs.icon / 1.5,
                  height: rs.icon / 1.5,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              title: Text(
                condition.name,
                style: TextStyle(
                  fontSize: rs.titleFont,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              subtitle: Text(
                bodySystemLabel(condition.bodySystem),
                style: TextStyle(
                  fontSize: rs.subtitleFont,
                  color: Colors.white70,
                ),
              ),
              trailing: PopupMenuButton<String>(
                iconColor: Theme.of(context).colorScheme.onPrimary,
                onSelected: (value) {
                  if (value == 'edit') onEdit?.call(condition);
                  if (value == 'delete') onDelete?.call(condition);
                },
                itemBuilder:
                    (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
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
          );
        },
      ),
    );
  }
}
