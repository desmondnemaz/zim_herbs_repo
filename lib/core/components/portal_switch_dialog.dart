import 'package:flutter/material.dart';

/// Shows a standardized, attractive confirmation dialog before switching between
/// the Public App and the Admin Console.
///
/// Returns `true` if the user confirms the portal transition, or `false` if cancelled.
Future<bool> showPortalSwitchConfirmation({
  required BuildContext context,
  required bool toAdmin,
}) async {
  final theme = Theme.of(context);
  final isToAdmin = toAdmin;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isToAdmin
                  ? Colors.amber.shade50
                  : Colors.green.shade50,
              shape: BoxShape.circle,
              border: Border.all(
                color: isToAdmin
                    ? Colors.amber.shade200
                    : Colors.green.shade200,
                width: 1,
              ),
            ),
            child: Icon(
              isToAdmin
                  ? Icons.admin_panel_settings_rounded
                  : Icons.storefront_rounded,
              color: isToAdmin
                  ? Colors.amber.shade800
                  : Colors.green.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isToAdmin ? 'Switch to Admin Console?' : 'Switch to Public App?',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
      content: Text(
        isToAdmin
            ? 'You are about to switch to the administrative and moderation console. Do you want to proceed?'
            : 'You are about to switch to the public catalog and herbal marketplace. Do you want to proceed?',
        style: const TextStyle(
          color: Color(0xFF4B5563),
          fontSize: 14,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx, false),
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isToAdmin
                ? const Color(0xFF2E7D32)
                : theme.colorScheme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () => Navigator.pop(dialogCtx, true),
          child: Text(
            isToAdmin ? 'Switch to Admin' : 'Switch to Public',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}
