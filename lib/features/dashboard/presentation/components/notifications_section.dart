//=====================Right Notifications Panel========================
import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/theme/spacing.dart';
import 'package:zim_herbs_repo/utils/responsive_sizes.dart';

class NotificationsSection extends StatelessWidget {
  const NotificationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    // Sizing
    final rs = ResponsiveSize(context);

    // Dummy notifications
    final List<Map<String, String>> dummyNotifications = [
      {
        "title": "New Herb Added",
        "message": "Moringa has been added to the herbs list.",
      },
      {
        "title": "Update Available",
        "message": "A new update is available for the Knowledge section.",
      },
      {
        "title": "Reminder",
        "message": "Update practitioner verification details.",
      },
    ];

    return Container(
      padding: EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(10),
          topLeft: Radius.circular(10),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(defaultPadding),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(10),
                topLeft: Radius.circular(10),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    "Notifications",
                    style: TextStyle(
                      fontSize: rs.titleFont,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Build dummy notifications list
                ...dummyNotifications.map((note) {
                  return SizedBox(
                    // <--- Forces equal width
                    width: double.infinity, // <---
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 4,
                            offset: Offset(0, 1),
                            color: Colors.black12,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note["title"]!,
                            style: TextStyle(
                              fontSize: rs.subtitleFont,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            note["message"]!,
                            style: TextStyle(
                              fontSize: rs.subtitleFont,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
