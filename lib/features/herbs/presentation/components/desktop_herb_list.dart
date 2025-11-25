


import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/features/herbs/data/herbs_data.dart';
import 'package:zim_herbs_repo/features/herbs/presentation/herb_details.dart';
import 'package:zim_herbs_repo/theme/light_mode.dart';
import 'package:zim_herbs_repo/theme/spacing.dart';
import 'package:zim_herbs_repo/utils/responsive_sizes.dart';


//
class DesktopHerbList extends StatelessWidget {
  const DesktopHerbList({
    super.key,
    required this.filteredHerbs,
    required this.rs,
  });

  final List<Herb> filteredHerbs;
  final ResponsiveSize rs;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
        padding: EdgeInsets.all(defaultPadding),
        gridDelegate:
            SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
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
                builder: (context) => HerbDetailsPage(),
              ),
            );
          },
            child: Card(
              color: pharmacyTheme.colorScheme.secondary,
              elevation: 2,
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(1.0),
                        child: Image.asset(
                          herb.imagePath,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      herb.name,
                      style: TextStyle(
                        fontSize: rs.subtitleFont,
                        fontWeight: FontWeight.bold,
                        color: pharmacyTheme
                            .colorScheme.onSecondary,
                      ),
                      textAlign: TextAlign.center,
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