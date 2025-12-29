//=====================Right Notifications Panel========================
import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/theme/spacing.dart';
import 'package:zim_herbs_repo/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/core/presentation/widgets/zimbabwe_widgets.dart';

class NotificationsSection extends StatelessWidget {
  const NotificationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    // Sizing
    final rs = ResponsiveSize(context);

    // Dummy notifications
    final List<Map<String, dynamic>> dummyNotifications = [
      {
        "title": "New Herb Added",
        "message": "Moringa has been added to the herbs list.",
        "icon": Icons.eco,
        "time": "2 mins ago",
        "color": Colors.green,
      },
      {
        "title": "Update Available",
        "message": "A new update for Knowledge section.",
        "icon": Icons.update,
        "time": "1 hour ago",
        "color": Colors.blue,
      },
      {
        "title": "Reminder",
        "message": "Update practitioner verification details.",
        "icon": Icons.notification_important,
        "time": "3 hours ago",
        "color": Colors.orange,
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
      child: ZimbabweWorkBackground(
        patternColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.05),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: defaultPadding),
              child: Text(
                "Notifications",
                style: TextStyle(
                  fontSize: rs.titleFont,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Column(
              children:
                  dummyNotifications.map((note) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                            color: Colors.black.withValues(alpha: 0.05),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (note["color"] as Color).withValues(
                                alpha: 0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              note["icon"] as IconData,
                              size: 20,
                              color: note["color"] as Color,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      note["title"]!,
                                      style: TextStyle(
                                        fontSize: rs.subtitleFont,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                      ),
                                    ),
                                    Text(
                                      note["time"]!,
                                      style: TextStyle(
                                        fontSize: rs.subtitleFont - 2,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  note["message"]!,
                                  style: TextStyle(
                                    fontSize: rs.subtitleFont - 1,
                                    color: Colors.black87,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
