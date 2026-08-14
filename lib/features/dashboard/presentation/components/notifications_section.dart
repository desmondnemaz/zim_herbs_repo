//=====================Right Notifications Panel========================
import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/core/theme/spacing.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';


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
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: defaultPadding),
            child: Text(
              "Notifications",
              style: TextStyle(
                fontSize: rs.titleFont,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Column(
            children:
                dummyNotifications.map((note) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: (note["color"] as Color).withValues(alpha: 0.1),
                          child: Icon(
                            note["icon"] as IconData,
                            color: note["color"] as Color,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      note["title"]!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
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
    );
  }
}
