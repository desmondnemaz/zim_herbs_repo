import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/theme/light_mode.dart';
import 'package:zim_herbs_repo/theme/spacing.dart';
import 'package:zim_herbs_repo/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/utils/responsive.dart'; // your responsive file

class HerbDetailsPage extends StatelessWidget {
  const HerbDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);

    return Scaffold(
      backgroundColor: pharmacyTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // -------------------- CUSTOM APP BAR --------------------
            Container(
              padding: EdgeInsets.all(defaultPadding),
              color: pharmacyTheme.colorScheme.primary,
              child: Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.arrow_back,
                      color: pharmacyTheme.colorScheme.secondary,
                      size: rs.appBarIcon,
                    ),
                  ),
                  SizedBox(width: defaultPadding),
                  Text(
                    "Herb Details",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: rs.appBarTitleFont,
                      color: pharmacyTheme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),

            // -------------------- MAIN CONTENT --------------------
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth:
                          Responsive.isMobile(context)
                              ? double.infinity
                              : Responsive.isTablet(context)
                              ? 750
                              : 800,
                    ),

                    // =========================================
                    //              HERB CONTENT CARD
                    // =========================================
                    child: Container(
                      margin: EdgeInsets.all(defaultPadding),
                      padding: EdgeInsets.all(defaultPadding),
                      decoration: BoxDecoration(
                        color: pharmacyTheme.colorScheme.onPrimary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 8,
                            color: Colors.black12,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ----------------- IMAGE -----------------
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              "assets/images/zumbani.png",
                              height:
                                  Responsive.isMobile(context)
                                      ? 240
                                      : Responsive.isTablet(context)
                                      ? 320
                                      : 400,

                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),

                          SizedBox(height: 20),

                          _sectionTitle("Herb Name", rs),
                          _sectionText("This is a placeholder name.", rs),
                          SizedBox(height: defaultPadding),

                          _sectionTitle("Description", rs),
                          _sectionText(
                            "This herb is commonly used for healing and wellness. Replace with your full description later.",
                            rs,
                          ),
                          SizedBox(height: defaultPadding),

                          _sectionTitle("Benefits", rs),
                          _sectionText(
                            "• Boosts immunity\n• Helps digestion\n• Supports natural healing",
                            rs,
                          ),
                          SizedBox(height: defaultPadding),

                          _sectionTitle("Preparation", rs),
                          _sectionText(
                            "Boil a handful of leaves in water for 10 minutes. Drink warm.",
                            rs,
                          ),
                          SizedBox(height: defaultPadding),

                          _sectionTitle("Dosage", rs),
                          _sectionText("1 cup, 2–3 times a day.", rs),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------- STYLE HELPERS --------------------
  Widget _sectionTitle(String title, ResponsiveSize rs) {
    return Container( padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: pharmacyTheme.colorScheme.primary.withValues(alpha: .2),
      borderRadius: BorderRadius.circular(12),
    ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: rs.subtitleFont,
          fontWeight: FontWeight.bold,
          color: pharmacyTheme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _sectionText(String value, ResponsiveSize rs) {
    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: Text(
        value,
        style: TextStyle(
          fontSize: rs.subtitleFont,
          height: 1.4,
          color: pharmacyTheme.colorScheme.primary,
        ),
      ),
    );
  }
}
