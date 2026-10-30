import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/core/theme/spacing.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/features/repository/herbs/domain/entities/herb.dart';
import 'package:zim_herbs_repo/features/repository/herbs/presentation/pages/herb_details.dart';

class MobileHerbList extends StatelessWidget {
  const MobileHerbList({
    super.key,
    required this.filteredHerbs,
    required this.rs,
    required this.onEdit,
    required this.onDelete,
    this.onVerify,
    this.isSelectionMode = false,
    this.selectedHerbIds = const {},
    this.onToggleSelect,
    this.onLongPress,
  });

  final ResponsiveSize rs;
  final List<Herb> filteredHerbs;
  final Function(Herb) onEdit;
  final Function(Herb) onDelete;
  final Function(Herb)? onVerify;
  final bool isSelectionMode;
  final Set<String> selectedHerbIds;
  final ValueChanged<Herb>? onToggleSelect;
  final ValueChanged<Herb>? onLongPress;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(defaultPadding),
      itemCount: filteredHerbs.length,
      itemBuilder: (context, index) {
        final herb = filteredHerbs[index];
        final isSelected = selectedHerbIds.contains(herb.id);

        return InkWell(
          onTap: () {
            if (isSelectionMode) {
              onToggleSelect?.call(herb);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HerbDetailsPage(herbId: herb.id),
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, defaultPadding / 2, 0, 0),
            child: Card(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.85)
                  : Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isSelected
                    ? BorderSide(
                        color: Theme.of(context).colorScheme.secondary,
                        width: 2.5,
                      )
                    : BorderSide.none,
              ),
              elevation: isSelected ? 4 : 2,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelectionMode)
                      Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: Checkbox(
                          value: isSelected,
                          activeColor:
                              Theme.of(context).colorScheme.secondary,
                          checkColor: Colors.black,
                          side: const BorderSide(
                            color: Colors.white,
                            width: 2,
                          ),
                          onChanged: (_) => onToggleSelect?.call(herb),
                        ),
                      ),
                    Hero(
                      tag: 'herb-image-${herb.nameEn}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child:
                            herb.primaryImageUrl != null
                                ? Image.network(
                                  herb.primaryImageUrl!,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    debugPrint(
                                      'FAILED IMAGE URL: ${herb.primaryImageUrl}',
                                    );
                                    debugPrint('Error: $error');
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey,
                                    );
                                  },
                                )
                                : Container(
                                  width: 60,
                                  height: 60,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary.withValues(alpha: 0.2),
                                  child: Icon(
                                    Icons.spa,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        herb.nameEn,
                        style: TextStyle(
                          fontSize: rs.titleFont,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    if (!herb.isApproved) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade300,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Unverified',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle:
                    (herb.nameSn != null || herb.nameNd != null)
                        ? Text(
                          "${herb.nameSn ?? ''}${herb.nameSn != null && herb.nameNd != null ? ' / ' : ''}${herb.nameNd ?? ''}",
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimary.withValues(alpha: 0.7),
                            fontSize: rs.subtitleFont,
                          ),
                        )
                        : null,
                trailing: isSelectionMode
                    ? (isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.secondary,
                          )
                        : null)
                    : PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'verify') {
                            onVerify?.call(herb);
                          } else if (value == 'edit') {
                            onEdit(herb);
                          } else if (value == 'delete') {
                            onDelete(herb);
                          }
                        },
                        itemBuilder:
                            (BuildContext context) => <PopupMenuEntry<String>>[
                              if (!herb.isApproved && onVerify != null)
                                const PopupMenuItem<String>(
                                  value: 'verify',
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    ),
                                    title: Text(
                                      'Verify Herb',
                                      style: TextStyle(color: Colors.green),
                                    ),
                                  ),
                                ),
                              const PopupMenuItem<String>(
                                value: 'edit',
                                child: ListTile(
                                  leading: Icon(Icons.edit),
                                  title: Text('Edit'),
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(Icons.delete, color: Colors.red),
                                  title: Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ),
                            ],
                        icon: Icon(
                          Icons.more_vert,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
