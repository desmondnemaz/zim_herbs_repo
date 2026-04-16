import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/core/presentation/widgets/zimbabwe_widgets.dart';
import 'package:zim_herbs_repo/theme/spacing.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {

    // Dummy notifications (same as in NotificationsSection)
    final List<Map<String, dynamic>> notifications = [
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
      ),
      body: ZimbabweWorkBackground(
        child: ListView.builder(
          padding: const EdgeInsets.all(defaultPadding),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final note = notifications[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                    color: Colors.black.withValues(alpha: 0.1),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (note["color"] as Color).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    note["icon"] as IconData,
                    color: note["color"] as Color,
                    size: 28,
                  ),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      note["title"]!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      note["time"]!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    note["message"]!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
