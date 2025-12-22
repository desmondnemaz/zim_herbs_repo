import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/features/herbs/data/models.dart';

import 'package:zim_herbs_repo/theme/spacing.dart';
import 'package:zim_herbs_repo/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/features/herbs/presentation/herb_details.dart';

//
class DesktopHerbList extends StatelessWidget {
  const DesktopHerbList({
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
    return GridView.builder(
      padding: EdgeInsets.all(defaultPadding),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200, // Slightly wider for actions
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: filteredHerbs.length,
      itemBuilder: (context, index) {
        final herb = filteredHerbs[index];
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HerbDetailsPage(herbId: herb.id),
              ),
            );
          },
          child: Card(
            color: Theme.of(context).colorScheme.primary,
            elevation: 2,
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: Hero(
                        tag: 'herb-image-${herb.nameEn}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child:
                              herb.primaryImageUrl != null
                                  ? Image.network(
                                    herb.primaryImageUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder:
                                        (_, __, ___) =>
                                            Container(color: Colors.grey),
                                  )
                                  : Container(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withValues(alpha: 0.2),
                                    child: Center(
                                      child: Icon(
                                        Icons.spa,
                                        size: 40,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onPrimary,
                                      ),
                                    ),
                                  ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Text(
                            herb.nameEn,
                            style: TextStyle(
                              fontSize: rs.titleFont,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (herb.nameSn != null || herb.nameNd != null)
                            Text(
                              "${herb.nameSn ?? ''}${herb.nameSn != null && herb.nameNd != null ? ' / ' : ''}${herb.nameNd ?? ''}",
                              style: TextStyle(
                                fontSize: rs.subtitleFont,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimary.withValues(alpha: 0.7),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit(herb);
                      } else if (value == 'delete') {
                        onDelete(herb);
                      }
                    },
                    itemBuilder:
                        (context) => [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                    icon: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.more_vert, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
