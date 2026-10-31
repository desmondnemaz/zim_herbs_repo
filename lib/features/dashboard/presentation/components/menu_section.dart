import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/features/dashboard/data/models/menu_item_model.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';

// Screen Imports for Route Resolution
import 'package:zim_herbs_repo/features/repository/herbs/presentation/pages/herbs_list.dart';
import 'package:zim_herbs_repo/features/repository/remedies/presentation/pages/remedies_list.dart';
import 'package:zim_herbs_repo/features/repository/conditions/presentation/condition_list.dart';
import 'package:zim_herbs_repo/features/marketplace/store/presentation/store_page.dart';
import 'package:zim_herbs_repo/features/telemedicine/presentation/telemedicine_page.dart';
import 'package:zim_herbs_repo/features/repository/contributions/presentation/contributions_page.dart';
import 'package:zim_herbs_repo/features/dashboard/presentation/coming_soon.dart';

// --- Route Resolution Helper ---
Widget getPageForRoute(String routeName) {
  switch (routeName) {
    case '/herbs':
      return const HerbsList(isPublicView: true);
    case '/remedies':
    case '/treatments':
      return const RemediesList(isPublicView: true);
    case '/conditions':
      return const ConditionsListPage(isPublicView: true);
    case '/store':
      return const StorePage();
    case '/telemed':
      return const TelemedicinePage();
    case '/contributions':
      return const ContributionsPage();
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
            children: MenuCategory.values.where((category) {
              if (category == MenuCategory.all) return true;
              return zimHerbalMenuItems.any((item) => item.category == category);
            }).map((category) {
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

class _MenuItemTheme {
  final Color primaryColor;
  final Color gradientEnd;
  final Color pastelBackground;

  const _MenuItemTheme({
    required this.primaryColor,
    required this.gradientEnd,
    required this.pastelBackground,
  });
}

_MenuItemTheme _getMenuItemTheme(String title) {
  switch (title.toLowerCase().trim()) {
    case 'herbs':
      return const _MenuItemTheme(
        primaryColor: Color(0xFF22633C),
        gradientEnd: Color(0xFF1B5E20),
        pastelBackground: Color(0xFFEAF5EB),
      );
    case 'conditions':
      return const _MenuItemTheme(
        primaryColor: Color(0xFF106F74),
        gradientEnd: Color(0xFF0D5458),
        pastelBackground: Color(0xFFE6F5F5),
      );
    case 'remedies':
      return const _MenuItemTheme(
        primaryColor: Color(0xFF295CA2),
        gradientEnd: Color(0xFF1D447B),
        pastelBackground: Color(0xFFEBF3FC),
      );
    case 'herbal store':
    case 'store':
    case 'marketplace':
      return const _MenuItemTheme(
        primaryColor: Color(0xFFA85B18),
        gradientEnd: Color(0xFF85450E),
        pastelBackground: Color(0xFFFEF5EB),
      );
    case 'telemedicine':
      return const _MenuItemTheme(
        primaryColor: Color(0xFF684B8A),
        gradientEnd: Color(0xFF50386C),
        pastelBackground: Color(0xFFF4EEF9),
      );
    case 'practitioners':
      return const _MenuItemTheme(
        primaryColor: Color(0xFF4F46E5),
        gradientEnd: Color(0xFF3730A3),
        pastelBackground: Color(0xFFEEF2FF),
      );
    case 'ai chatbot':
    case 'chatbot':
      return const _MenuItemTheme(
        primaryColor: Color(0xFF0F766E),
        gradientEnd: Color(0xFF115E59),
        pastelBackground: Color(0xFFF0FDF4),
      );
    case 'knowledge':
      return const _MenuItemTheme(
        primaryColor: Color(0xFF7C3AED),
        gradientEnd: Color(0xFF5B21B6),
        pastelBackground: Color(0xFFF5F3FF),
      );
    case 'contributions':
    case 'innovation':
      return const _MenuItemTheme(
        primaryColor: Color(0xFFD97706),
        gradientEnd: Color(0xFFB45309),
        pastelBackground: Color(0xFFFFFBEB),
      );
    default:
      return const _MenuItemTheme(
        primaryColor: Color(0xFF22633C),
        gradientEnd: Color(0xFF1B5E20),
        pastelBackground: Color(0xFFEAF5EB),
      );
  }
}

class _MenuCard extends StatelessWidget {
  final MenuItemModel item;
  final ResponsiveSize rs;
  const _MenuCard({required this.item, required this.rs});

  @override
  Widget build(BuildContext context) {
    final itemTheme = _getMenuItemTheme(item.title);

    if (!item.isAvailable) {
      // --- Pastel styling for locked / coming soon items ---
      return ClipRRect(
        borderRadius: BorderRadius.circular(rs.borderRadius * 1.5),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: itemTheme.pastelBackground,
                borderRadius: BorderRadius.circular(rs.borderRadius * 1.5),
                border: Border.all(
                  color: itemTheme.primaryColor.withValues(alpha: 0.22),
                  width: 1.0,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: itemTheme.primaryColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.icon,
                        color: itemTheme.primaryColor.withValues(alpha: 0.65),
                        size: rs.icon,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF1E293B),
                        fontSize: rs.subtitleFont * 0.95,
                        fontWeight: FontWeight.w600,
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
                  color: itemTheme.primaryColor.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 10, color: Colors.white),
                    SizedBox(width: 2),
                    Text(
                      "SOON",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
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

    // --- Active Premium Layout with Admin Dashboard Domain Color ---
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            itemTheme.primaryColor,
            itemTheme.gradientEnd,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(rs.borderRadius * 1.5),
        boxShadow: [
          BoxShadow(
            color: itemTheme.primaryColor.withValues(alpha: 0.28),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.2,
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: Colors.white, size: rs.icon),
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: rs.titleFont * 0.95,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
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
