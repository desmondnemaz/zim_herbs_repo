import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/features/herbs/data/models.dart';

import 'package:zim_herbs_repo/theme/spacing.dart';
import 'package:zim_herbs_repo/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/features/herbs/presentation/herb_details.dart';

class MobileHerbList extends StatelessWidget {
  const MobileHerbList({
    super.key,
    required this.filteredHerbs,
    required this.rs,
    required this.onEdit,
    required this.onDelete,
  });

  final List<HerbModel> filteredHerbs;
  final ResponsiveSize rs;
  final Function(HerbModel) onEdit;
  final Function(HerbModel) onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(defaultPadding),
      itemCount: filteredHerbs.length,
      itemBuilder: (context, index) {
        final herb = filteredHerbs[index];

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HerbDetailsPage(herbId: herb.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, defaultPadding / 2, 0, 0),
            child: Card(
              color: Theme.of(context).colorScheme.primary,
              elevation: 2,
              child: ListTile(
                contentPadding: const EdgeInsets.all(8),
                leading: Hero(
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
                title: Text(
                  herb.nameEn,
                  style: TextStyle(
                    fontSize: rs.titleFont,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
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
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit(herb);
                    } else if (value == 'delete') {
                      onDelete(herb);
                    }
                  },
                  itemBuilder:
                      (BuildContext context) => <PopupMenuEntry<String>>[
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
