import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/core/errors/failure.dart';

/// An attractive, responsive inline error banner with contextual icons,
/// actions (e.g. "Switch to Sign In" or "Retry"), and dismiss button.
class AppErrorBanner extends StatelessWidget {
  final Failure? failure;
  final String? message;
  final String? title;
  final FailureType type;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;
  final String? actionLabel;
  final EdgeInsetsGeometry margin;

  const AppErrorBanner({
    super.key,
    this.failure,
    this.message,
    this.title,
    this.type = FailureType.unknown,
    this.onDismiss,
    this.onAction,
    this.actionLabel,
    this.margin = const EdgeInsets.only(bottom: 16),
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMessage = failure?.message ?? message;
    if (effectiveMessage == null || effectiveMessage.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final effectiveType = failure?.type ?? type;
    final effectiveTitle = title ?? failure?.title ?? _defaultTitle(effectiveType);

    final colors = _resolveColors(context, effectiveType);
    final icon = _resolveIcon(effectiveType);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: margin,
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.borderColor,
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colors.iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: colors.iconColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (effectiveTitle != null && effectiveTitle.isNotEmpty)
                        Text(
                          effectiveTitle,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: colors.titleColor,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        effectiveMessage,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w400,
                          color: colors.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onDismiss != null)
                  InkWell(
                    onTap: onDismiss,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: colors.textColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
              ],
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    backgroundColor: colors.iconBgColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: colors.titleColor,
                  ),
                  label: Text(
                    actionLabel!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colors.titleColor,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _defaultTitle(FailureType type) {
    switch (type) {
      case FailureType.noInternet:
        return 'No Internet Connection';
      case FailureType.serverUnavailable:
        return 'Server Unavailable';
      case FailureType.timeout:
        return 'Connection Timed Out';
      case FailureType.invalidCredentials:
        return 'Invalid Credentials';
      case FailureType.userAlreadyExists:
        return 'Account Already Exists';
      case FailureType.userNotFound:
        return 'Account Not Found';
      case FailureType.weakPassword:
        return 'Weak Password';
      case FailureType.emailNotConfirmed:
        return 'Email Verification Required';
      case FailureType.tooManyRequests:
        return 'Too Many Attempts';
      case FailureType.accessDenied:
        return 'Access Denied';
      case FailureType.validation:
        return 'Check Input';
      default:
        return null;
    }
  }

  IconData _resolveIcon(FailureType type) {
    switch (type) {
      case FailureType.noInternet:
        return Icons.wifi_off_rounded;
      case FailureType.serverUnavailable:
        return Icons.cloud_off_rounded;
      case FailureType.timeout:
        return Icons.timer_off_outlined;
      case FailureType.invalidCredentials:
        return Icons.lock_person_rounded;
      case FailureType.userAlreadyExists:
        return Icons.person_search_rounded;
      case FailureType.userNotFound:
        return Icons.no_accounts_rounded;
      case FailureType.weakPassword:
        return Icons.shield_outlined;
      case FailureType.emailNotConfirmed:
        return Icons.mark_email_unread_rounded;
      case FailureType.tooManyRequests:
        return Icons.hourglass_top_rounded;
      case FailureType.accessDenied:
        return Icons.admin_panel_settings_outlined;
      case FailureType.validation:
        return Icons.info_outline_rounded;
      default:
        return Icons.error_outline_rounded;
    }
  }

  _BannerColorSet _resolveColors(BuildContext context, FailureType type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (type) {
      case FailureType.noInternet:
      case FailureType.timeout:
        return _BannerColorSet(
          backgroundColor: isDark
              ? const Color(0xFF2C2214)
              : const Color(0xFFFFF7ED),
          borderColor: isDark
              ? const Color(0xFF854D0E)
              : const Color(0xFFFDBA74),
          iconColor: const Color(0xFFD97706),
          iconBgColor: isDark
              ? const Color(0xFF451A03)
              : const Color(0xFFFFEDD5),
          titleColor: isDark
              ? const Color(0xFFFDE68A)
              : const Color(0xFF9A3412),
          textColor: isDark
              ? const Color(0xFFE2E8F0)
              : const Color(0xFF7C2D12),
        );

      case FailureType.userAlreadyExists:
      case FailureType.emailNotConfirmed:
        return _BannerColorSet(
          backgroundColor: isDark
              ? const Color(0xFF142436)
              : const Color(0xFFEFF6FF),
          borderColor: isDark
              ? const Color(0xFF1E40AF)
              : const Color(0xFF93C5FD),
          iconColor: const Color(0xFF2563EB),
          iconBgColor: isDark
              ? const Color(0xFF172554)
              : const Color(0xFFDBEAFE),
          titleColor: isDark
              ? const Color(0xFFBFDBFE)
              : const Color(0xFF1E3A8A),
          textColor: isDark
              ? const Color(0xFFE2E8F0)
              : const Color(0xFF1E40AF),
        );

      case FailureType.accessDenied:
      case FailureType.invalidCredentials:
      case FailureType.serverUnavailable:
      case FailureType.weakPassword:
      case FailureType.tooManyRequests:
      case FailureType.validation:
      case FailureType.unknown:
      default:
        return _BannerColorSet(
          backgroundColor: isDark
              ? const Color(0xFF321919)
              : const Color(0xFFFEF2F2),
          borderColor: isDark
              ? const Color(0xFF991B1B)
              : const Color(0xFFFCA5A5),
          iconColor: const Color(0xFFDC2626),
          iconBgColor: isDark
              ? const Color(0xFF450A0A)
              : const Color(0xFFFEE2E2),
          titleColor: isDark
              ? const Color(0xFFFECACA)
              : const Color(0xFF991B1B),
          textColor: isDark
              ? const Color(0xFFE2E8F0)
              : const Color(0xFF7F1D1D),
        );
    }
  }
}

class _BannerColorSet {
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color iconBgColor;
  final Color titleColor;
  final Color textColor;

  const _BannerColorSet({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.iconBgColor,
    required this.titleColor,
    required this.textColor,
  });
}

/// Helper method to show consistent, well-styled snack bars across the app
void showAppErrorSnackBar(
  BuildContext context, {
  Failure? failure,
  String? message,
  String? title,
  FailureType type = FailureType.unknown,
  VoidCallback? onAction,
  String? actionLabel,
  Duration duration = const Duration(seconds: 4),
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  final effectiveMessage = failure?.message ?? message;
  if (effectiveMessage == null || effectiveMessage.trim().isEmpty) return;

  final effectiveType = failure?.type ?? type;
  final effectiveTitle = title ?? failure?.title;

  messenger.clearSnackBars();

  final (icon, iconColor) = switch (effectiveType) {
    FailureType.noInternet => (Icons.wifi_off_rounded, const Color(0xFFFBBF24)),
    FailureType.timeout => (Icons.timer_off_outlined, const Color(0xFFFBBF24)),
    FailureType.serverUnavailable => (Icons.cloud_off_rounded, const Color(0xFFFB923C)),
    FailureType.invalidCredentials => (Icons.lock_person_rounded, const Color(0xFFF87171)),
    FailureType.userAlreadyExists => (Icons.person_search_rounded, const Color(0xFF60A5FA)),
    FailureType.accessDenied => (Icons.admin_panel_settings_outlined, const Color(0xFFF87171)),
    _ => (Icons.error_outline_rounded, const Color(0xFFF87171)),
  };

  final resolvedActionLabel = actionLabel ??
      (onAction != null &&
              (effectiveType == FailureType.serverUnavailable ||
                  effectiveType == FailureType.noInternet ||
                  effectiveType == FailureType.timeout)
          ? 'RETRY'
          : null);

  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      elevation: 6,
      backgroundColor: const Color(0xFF1E293B),
      duration: duration,
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (effectiveTitle != null && effectiveTitle.isNotEmpty)
                  Text(
                    effectiveTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                Text(
                  effectiveMessage,
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      action: onAction != null && resolvedActionLabel != null
          ? SnackBarAction(
              label: resolvedActionLabel,
              textColor: const Color(0xFF38BDF8),
              onPressed: onAction,
            )
          : SnackBarAction(
              label: 'DISMISS',
              textColor: Colors.white70,
              onPressed: () => messenger.hideCurrentSnackBar(),
            ),
    ),
  );
}
