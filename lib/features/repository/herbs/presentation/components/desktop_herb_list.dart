import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/core/theme/spacing.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/features/repository/herbs/domain/entities/herb.dart';
import 'package:zim_herbs_repo/features/repository/herbs/presentation/pages/herb_details.dart';

//
class DesktopHerbList extends StatelessWidget {
  const DesktopHerbList({
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
        final isSelected = selectedHerbIds.contains(herb.id);

        return InkWell(
          borderRadius: BorderRadius.circular(12),
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
          child: Card(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.85)
                : Theme.of(context).colorScheme.primary,
            elevation: isSelected ? 4 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isSelected
                  ? BorderSide(
                      color: Theme.of(context).colorScheme.secondary,
                      width: 3,
                    )
                  : BorderSide.none,
            ),
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
                                        (_, _, _) =>
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
                if (isSelectionMode)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surface
                            .withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Checkbox(
                        value: isSelected,
                        activeColor:
                            Theme.of(context).colorScheme.secondary,
                        checkColor: Colors.black,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        onChanged: (_) => onToggleSelect?.call(herb),
                      ),
                    ),
                  ),
                if (!herb.isApproved)
                  Positioned(
                    top: 6,
                    left: isSelectionMode ? 36 : 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Unverified',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                if (!isSelectionMode)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: PopupMenuButton<String>(
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
                          (context) => [
                            if (!herb.isApproved && onVerify != null)
                              const PopupMenuItem(
                                value: 'verify',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Verify Herb',
                                      style: TextStyle(color: Colors.green),
                                    ),
                                  ],
                                ),
                              ),
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.more_vert, size: 20),
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
