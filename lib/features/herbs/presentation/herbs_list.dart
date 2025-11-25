import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/features/herbs/data/herbs_data.dart';
import 'package:zim_herbs_repo/features/herbs/presentation/components/desktop_herb_list.dart';
import 'package:zim_herbs_repo/features/herbs/presentation/components/mobile_herb_list.dart';
import 'package:zim_herbs_repo/theme/light_mode.dart';
import 'package:zim_herbs_repo/theme/spacing.dart';
import 'package:zim_herbs_repo/utils/responsive.dart';
import 'package:zim_herbs_repo/utils/responsive_sizes.dart';

class HerbsList extends StatefulWidget {
  const HerbsList({super.key});

  @override
  State<HerbsList> createState() => _HerbsListState();
}

class _HerbsListState extends State<HerbsList> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);

    // FILTER HERBS
    final filteredHerbs =
        herbs
            .where(
              (h) => h.name.toLowerCase().contains(searchQuery.toLowerCase()),
            )
            .toList();

    return Scaffold(
      appBar:
          Responsive.isDesktop(context)
              ? null
              : AppBar(
                toolbarHeight: 10,
                elevation: 0,
                backgroundColor: pharmacyTheme.colorScheme.primary,
              ),

      body: SafeArea(
        // Main Screen
        child: Container(
          decoration: BoxDecoration(
            color: pharmacyTheme.scaffoldBackgroundColor,
          ),
          child: Column(
            children: [
              // AppBar
              Container(
                padding: EdgeInsets.all(defaultPadding),
                decoration: BoxDecoration(
                  color: pharmacyTheme.colorScheme.primary,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: Icon(
                            Icons.arrow_back,
                            color: pharmacyTheme.colorScheme.secondary,
                            size: rs.appBarIcon,
                          ),
                        ),
                        SizedBox(width: defaultPadding),
                        Text(
                          "All Herbs",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: pharmacyTheme.colorScheme.secondary,
                            fontSize: rs.appBarTitleFont,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              //  SEARCH BAR
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Search herbs...",
                    filled: true,
                    fillColor: pharmacyTheme.colorScheme.onPrimary,
                    prefixIcon: Icon(
                      Icons.search,
                      color: pharmacyTheme.colorScheme.primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              //  AUTO SWITCH VIEW (MOBILE = LIST, DESKTOP/TABLET = GRID)
              Expanded(
                child:
                    Responsive.isMobile(context)
                        //
                        ? MobileHerbList(filteredHerbs: filteredHerbs, rs: rs)
                        : DesktopHerbList(filteredHerbs: filteredHerbs, rs: rs),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
