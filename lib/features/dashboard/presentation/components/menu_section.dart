import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/features/dashboard/data/models/menu_item_model.dart';
import 'package:zim_herbs_repo/utils/responsive_sizes.dart';

// Screen Imports for Route Resolution
import 'package:zim_herbs_repo/features/herbs/presentation/herbs_list.dart';
import 'package:zim_herbs_repo/features/treatments/presentation/treatments_list.dart';
import 'package:zim_herbs_repo/features/conditions/presentation/condition_list.dart';
import 'package:zim_herbs_repo/features/store/presentation/store_page.dart';
import 'package:zim_herbs_repo/features/telemedicine/presentation/telemedicine_page.dart';
import 'package:zim_herbs_repo/features/dashboard/presentation/coming_soon.dart';

// --- Route Resolution Helper ---
Widget getPageForRoute(String routeName) {
  switch (routeName) {
    case '/herbs':
      return const HerbsList();
    case '/treatments':
      return const TreatmentsList();
    case '/diseases':
      return const ConditionsListPage();
    case '/store':
      return const StorePage();
    case '/telemed':
      return const TelemedicinePage();
    default:
      return const ComingSoonPage();
  }
}

class MenuSection extends StatefulWidget {
  const MenuSection({super.key});

  @override
  State<MenuSection> createState() => _MenuSectionState();
}

class _MenuSectionState extends State<MenuSection> {
  MenuCategory _selectedCategory = MenuCategory.all;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rs = ResponsiveSize(context);
    
    // Filter logic driven by state choices
    final filteredItems = zimHerbalMenuItems.where((item) {
      if (_selectedCategory == MenuCategory.all) return true;
      return item.category == _selectedCategory;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: rs.defaultPadding, vertical: 8.0),
          child: Text(
            "Explore Repository",
            style: TextStyle(
              fontSize: rs.titleFont * 1.1, 
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        
        // --- Dynamic Segmented Filter Sliders ---
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: rs.defaultPadding - 4, vertical: 8.0),
          child: Row(
            children: MenuCategory.values.map((category) {
              final isSelected = _selectedCategory == category;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ChoiceChip(
                  label: Text(_getCategoryLabel(category)),
                  selected: isSelected,
                  selectedColor: theme.colorScheme.primary,
                  backgroundColor: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(rs.borderRadius),
                    side: BorderSide(
                      color: isSelected 
                          ? theme.colorScheme.primary 
                          : theme.colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  labelStyle: TextStyle(
                    color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: rs.bodyFont * 0.9,
                  ),
                  onSelected: (bool selected) {
                    if (selected) {
                      setState(() => _selectedCategory = category);
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        
        const SizedBox(height: 8),

        // --- Adaptive Layout Matrix ---
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: rs.defaultPadding),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: rs.pick(mobile: 150, tablet: 180, desktop: 200),
            crossAxisSpacing: rs.gridSpacing,
            mainAxisSpacing: rs.gridSpacing,
            childAspectRatio: rs.cardAspectRatio,
          ),
          itemCount: filteredItems.length,
          itemBuilder: (context, index) {
            final item = filteredItems[index];
            return _MenuCard(item: item, rs: rs);
          },
        ),
      ],
    );
  }

  String _getCategoryLabel(MenuCategory category) {
    switch (category) {
      case MenuCategory.all: return "All Services";
      case MenuCategory.core: return "Clinical Library";
      case MenuCategory.services: return "Care & Store";
      case MenuCategory.insights: return "Resources";
    }
  }
}

class _MenuCard extends StatelessWidget {
  final MenuItemModel item;
  final ResponsiveSize rs;
  const _MenuCard({required this.item, required this.rs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!item.isAvailable) {
      // --- Frosted Glass Display Strategy for locked assets ---
      return ClipRRect(
        borderRadius: BorderRadius.circular(rs.borderRadius * 1.5),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(rs.borderRadius * 1.5),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.15)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, color: theme.colorScheme.primary.withValues(alpha: 0.4), size: rs.icon),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.colorScheme.primary.withValues(alpha: 0.6), 
                        fontSize: rs.subtitleFont * 0.95, 
                        fontWeight: FontWeight.w600
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 10, color: theme.colorScheme.onSecondary),
                    const SizedBox(width: 2),
                    Text(
                      "SOON",
                      style: TextStyle(color: theme.colorScheme.onSecondary, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showComingSoonToast(context, item.title),
              ),
            )
          ],
        ),
      );
    }

    // --- Active Premium Layout ---
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(rs.borderRadius * 1.5),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(rs.borderRadius * 1.5),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => getPageForRoute(item.routeName)),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: theme.colorScheme.secondary, size: rs.icon),
              const SizedBox(height: 8),
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: rs.titleFont * 0.95,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoonToast(BuildContext context, String title) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
        content: Text(
          "The $title feature is currently under active development.",
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
      ),
    );
  }
}
