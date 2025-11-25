import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/features/herbs/data/herbs_data.dart';
import 'package:zim_herbs_repo/features/herbs/presentation/herb_details.dart';
import 'package:zim_herbs_repo/theme/light_mode.dart';
import 'package:zim_herbs_repo/theme/spacing.dart';
import 'package:zim_herbs_repo/utils/responsive_sizes.dart';

class MobileHerbList extends StatelessWidget {
  const MobileHerbList({
    super.key,
    required this.filteredHerbs,
    required this.rs,
  });

  final List<Herb> filteredHerbs;
  final ResponsiveSize rs;

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
              MaterialPageRoute(builder: (context) => HerbDetailsPage()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, defaultPadding / 2, 0, 0),
            child: Card(
              color: pharmacyTheme.colorScheme.secondary,
              elevation: 2,
              child: ListTile(
                contentPadding: const EdgeInsets.all(1),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    herb.imagePath,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(
                  herb.name,
                  style: TextStyle(
                    fontSize: rs.subtitleFont,
                    fontWeight: FontWeight.bold,
                    color: pharmacyTheme.colorScheme.onSecondary,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: rs.appBarIcon,
                  color: pharmacyTheme.colorScheme.onSecondary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
