import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zim_herbs_repo/core/errors/failure.dart';

/// A unified, responsive, and theme-aware error presentation widget.
///
/// Supports two primary display formats:
/// 1. **Full-page / Section view** (`AppErrorView(...)`): Centered layout with
///    icon illustration, friendly message, action buttons (retry, back), and
///    an expandable technical diagnostics card with one-tap clipboard copy.
/// 2. **Inline banner** (`AppErrorView.banner(...)`): Compact alert banner
///    with contextual iconography, action triggers, and optional dismiss button.
class AppErrorView extends StatefulWidget {
  final Failure? failure;
  final String? message;
  final String? title;
  final FailureType type;

  // View-specific options
  final VoidCallback? onRetry;
  final String retryLabel;
  final VoidCallback? onBack;
  final String backLabel;
  final bool compact;
  final bool showDetails;
  final EdgeInsetsGeometry padding;

  // Banner-specific options
  final bool isBanner;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;
  final String? actionLabel;
  final EdgeInsetsGeometry margin;

  /// Full-page or embedded section error view.
  const AppErrorView({
    super.key,
    this.failure,
    this.message,
    this.title,
    this.type = FailureType.unknown,
    this.onRetry,
    this.retryLabel = 'Try Again',
    this.onBack,
    this.backLabel = 'Go Back',
    this.compact = false,
    this.showDetails = true,
    this.padding = const EdgeInsets.all(24.0),
  })  : isBanner = false,
        onDismiss = null,
        onAction = null,
        actionLabel = null,
        margin = EdgeInsets.zero;

  /// Compact inline error banner (ideal for forms, card headers, or inline notifications).
  const AppErrorView.banner({
    super.key,
    this.failure,
    this.message,
    this.title,
    this.type = FailureType.unknown,
    this.onDismiss,
    this.onAction,
    this.actionLabel,
    this.margin = const EdgeInsets.only(bottom: 16),
    VoidCallback? onRetry,
    String? retryLabel,
  })  : isBanner = true,
        onRetry = onRetry ?? onAction,
        retryLabel = retryLabel ?? (actionLabel ?? 'Try Again'),
        onBack = null,
        backLabel = 'Go Back',
        compact = false,
        showDetails = false,
        padding = EdgeInsets.zero;

  @override
  State<AppErrorView> createState() => _AppErrorViewState();
}

class _AppErrorViewState extends State<AppErrorView> {
  bool _detailsExpanded = false;
  bool _copied = false;

  FailureType get _effectiveType => widget.failure?.type ?? widget.type;

  String get _effectiveTitle {
    if (widget.title != null && widget.title!.isNotEmpty) {
      return widget.title!;
    }
    if (widget.failure?.title != null && widget.failure!.title!.isNotEmpty) {
      return widget.failure!.title!;
    }
    return switch (_effectiveType) {
      FailureType.serverUnavailable => 'Server Unavailable',
      FailureType.noInternet => 'No Internet Connection',
      FailureType.timeout => 'Connection Timed Out',
      FailureType.accessDenied => 'Access Denied',
      FailureType.notFound => 'Not Found',
      FailureType.validation => 'Check Input',
      FailureType.invalidCredentials => 'Invalid Credentials',
      FailureType.userAlreadyExists => 'Account Already Exists',
      FailureType.userNotFound => 'Account Not Found',
      FailureType.weakPassword => 'Weak Password',
      FailureType.emailNotConfirmed => 'Email Verification Required',
      FailureType.tooManyRequests => 'Too Many Attempts',
      _ => widget.isBanner ? '' : 'Unable to Load Data',
    };
  }

  String get _effectiveMessage {
    if (widget.failure?.message != null &&
        widget.failure!.message.trim().isNotEmpty) {
      return widget.failure!.message;
    }
    if (widget.message != null && widget.message!.trim().isNotEmpty) {
      return widget.message!;
    }
    return 'An unexpected issue occurred while communicating with the server. Please try again.';
  }

  IconData get _icon {
    return switch (_effectiveType) {
      FailureType.noInternet => Icons.wifi_off_rounded,
      FailureType.serverUnavailable => Icons.cloud_off_rounded,
      FailureType.timeout => Icons.timer_off_outlined,
      FailureType.invalidCredentials => Icons.lock_person_rounded,
      FailureType.userAlreadyExists => Icons.person_search_rounded,
      FailureType.userNotFound => Icons.no_accounts_rounded,
      FailureType.weakPassword => Icons.shield_outlined,
      FailureType.emailNotConfirmed => Icons.mark_email_unread_rounded,
      FailureType.tooManyRequests => Icons.hourglass_top_rounded,
      FailureType.accessDenied => Icons.admin_panel_settings_outlined,
      FailureType.notFound => Icons.search_off_rounded,
      FailureType.validation => Icons.info_outline_rounded,
      _ => Icons.error_outline_rounded,
    };
  }

  _ErrorColorPalette _resolveColors(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (_effectiveType) {
      case FailureType.noInternet:
      case FailureType.timeout:
        return _ErrorColorPalette(
          accentColor: const Color(0xFFD97706),
          backgroundColor:
              isDark ? const Color(0xFF2C2214) : const Color(0xFFFFF7ED),
          borderColor:
              isDark ? const Color(0xFF854D0E) : const Color(0xFFFDBA74),
          iconBgColor:
              isDark ? const Color(0xFF451A03) : const Color(0xFFFFEDD5),
          titleColor:
              isDark ? const Color(0xFFFDE68A) : const Color(0xFF9A3412),
          textColor:
              isDark ? const Color(0xFFE2E8F0) : const Color(0xFF7C2D12),
        );

      case FailureType.userAlreadyExists:
      case FailureType.emailNotConfirmed:
        return _ErrorColorPalette(
          accentColor: const Color(0xFF2563EB),
          backgroundColor:
              isDark ? const Color(0xFF142436) : const Color(0xFFEFF6FF),
          borderColor:
              isDark ? const Color(0xFF1E40AF) : const Color(0xFF93C5FD),
          iconBgColor:
              isDark ? const Color(0xFF172554) : const Color(0xFFDBEAFE),
          titleColor:
              isDark ? const Color(0xFFBFDBFE) : const Color(0xFF1E40AF),
          textColor:
              isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E3A8A),
        );

      case FailureType.accessDenied:
        return _ErrorColorPalette(
          accentColor: const Color(0xFF4F46E5),
          backgroundColor:
              isDark ? const Color(0xFF201A38) : const Color(0xFFEEF2FF),
          borderColor:
              isDark ? const Color(0xFF4338CA) : const Color(0xFFA5B4FC),
          iconBgColor:
              isDark ? const Color(0xFF312E81) : const Color(0xFFE0E7FF),
          titleColor:
              isDark ? const Color(0xFFC7D2FE) : const Color(0xFF3730A3),
          textColor:
              isDark ? const Color(0xFFE2E8F0) : const Color(0xFF312E81),
        );

      case FailureType.serverUnavailable:
        return _ErrorColorPalette(
          accentColor: const Color(0xFFEA580C),
          backgroundColor:
              isDark ? const Color(0xFF2E1711) : const Color(0xFFFFF1F2),
          borderColor:
              isDark ? const Color(0xFF9A3412) : const Color(0xFFFECDD3),
          iconBgColor:
              isDark ? const Color(0xFF431407) : const Color(0xFFFFE4E6),
          titleColor:
              isDark ? const Color(0xFFFECDD3) : const Color(0xFF9F1239),
          textColor:
              isDark ? const Color(0xFFF1F5F9) : const Color(0xFF881337),
        );

      default:
        final error = Theme.of(context).colorScheme.error;
        return _ErrorColorPalette(
          accentColor: error,
          backgroundColor:
              isDark ? const Color(0xFF2D181A) : const Color(0xFFFEF2F2),
          borderColor:
              isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA),
          iconBgColor:
              isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2),
          titleColor:
              isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
          textColor:
              isDark ? const Color(0xFFE2E8F0) : const Color(0xFF7F1D1D),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isBanner) {
      return _buildBanner(context);
    }
    return _buildFullScreenView(context);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Inline Banner Rendering
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildBanner(BuildContext context) {
    final effectiveMessage = _effectiveMessage;
    if (effectiveMessage.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final palette = _resolveColors(context);
    final effectiveTitle = _effectiveTitle;
    final actionCb = widget.onAction ?? widget.onRetry;
    final actionText = widget.actionLabel ?? (widget.onRetry != null ? widget.retryLabel : null);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: widget.margin,
      decoration: BoxDecoration(
        color: palette.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: palette.borderColor,
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
                    color: palette.iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _icon,
                    size: 18,
                    color: palette.accentColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (effectiveTitle.isNotEmpty)
                        Text(
                          effectiveTitle,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: palette.titleColor,
                          ),
                        ),
                      if (effectiveTitle.isNotEmpty) const SizedBox(height: 2),
                      Text(
                        effectiveMessage,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w400,
                          color: palette.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.onDismiss != null)
                  InkWell(
                    onTap: widget.onDismiss,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: palette.textColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
              ],
            ),
            if (actionCb != null && actionText != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: actionCb,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    backgroundColor: palette.iconBgColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: palette.titleColor,
                  ),
                  label: Text(
                    actionText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: palette.titleColor,
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

  // ───────────────────────────────────────────────────────────────────────────
  // Full-Page / Embedded Section Rendering
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildFullScreenView(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _resolveColors(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.compact ? 420 : 480),
        child: Padding(
          padding: widget.padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Badge
              Container(
                width: widget.compact ? 56 : 76,
                height: widget.compact ? 56 : 76,
                decoration: BoxDecoration(
                  color: palette.accentColor.withValues(alpha: isDark ? 0.18 : 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: palette.accentColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  _icon,
                  size: widget.compact ? 28 : 38,
                  color: palette.accentColor,
                ),
              ),
              SizedBox(height: widget.compact ? 14 : 20),

              // Title
              Text(
                _effectiveTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: widget.compact ? 17 : 20,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ) ??
                    TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: widget.compact ? 17 : 20,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
              ),
              const SizedBox(height: 8),

              // Message
              Text(
                _effectiveMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: widget.compact ? 13 : 14.5,
                  height: 1.45,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF475569),
                ),
              ),
              SizedBox(height: widget.compact ? 16 : 24),

              // Actions (Retry & Back)
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  if (widget.onBack != null)
                    OutlinedButton.icon(
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: Text(widget.backLabel),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  if (widget.onRetry != null)
                    ElevatedButton.icon(
                      onPressed: widget.onRetry,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(
                        _effectiveType == FailureType.noInternet
                            ? 'Reconnect & Retry'
                            : widget.retryLabel,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 12,
                        ),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                ],
              ),

              // Technical Details (Discreet Collapsible for debugging/admins)
              if (widget.showDetails &&
                  widget.failure?.originalError != null) ...[
                const SizedBox(height: 18),
                TextButton.icon(
                  onPressed: () => setState(() {
                    _detailsExpanded = !_detailsExpanded;
                  }),
                  icon: Icon(
                    _detailsExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.info_outline_rounded,
                    size: 15,
                    color: Colors.grey.shade600,
                  ),
                  label: Text(
                    _detailsExpanded ? 'Hide Details' : 'Technical Details',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                if (_detailsExpanded) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Type: ${_effectiveType.name}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: palette.accentColor,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                final text =
                                    '${widget.failure?.originalError}\n${widget.failure?.stackTrace ?? ''}';
                                Clipboard.setData(ClipboardData(text: text));
                                setState(() => _copied = true);
                                Future.delayed(
                                  const Duration(seconds: 2),
                                  () {
                                    if (mounted) {
                                      setState(() => _copied = false);
                                    }
                                  },
                                );
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    _copied ? Icons.check : Icons.copy_rounded,
                                    size: 13,
                                    color: _copied
                                        ? Colors.green
                                        : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _copied ? 'Copied' : 'Copy',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _copied
                                          ? Colors.green
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          widget.failure?.originalError.toString() ?? '',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A Sliver wrapper for [AppErrorView], suitable for CustomScrollView sliver lists.
class AppSliverErrorView extends StatelessWidget {
  final Failure? failure;
  final String? message;
  final String? title;
  final FailureType type;
  final VoidCallback? onRetry;
  final String retryLabel;

  const AppSliverErrorView({
    super.key,
    this.failure,
    this.message,
    this.title,
    this.type = FailureType.unknown,
    this.onRetry,
    this.retryLabel = 'Try Again',
  });

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: AppErrorView(
        failure: failure,
        message: message,
        title: title,
        type: type,
        onRetry: onRetry,
        retryLabel: retryLabel,
      ),
    );
  }
}

/// Compatibility component forwarding to [AppErrorView.banner].
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
    return AppErrorView.banner(
      failure: failure,
      message: message,
      title: title,
      type: type,
      onDismiss: onDismiss,
      onAction: onAction,
      actionLabel: actionLabel,
      margin: margin,
    );
  }
}

class _ErrorColorPalette {
  final Color accentColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconBgColor;
  final Color titleColor;
  final Color textColor;

  const _ErrorColorPalette({
    required this.accentColor,
    required this.backgroundColor,
    required this.borderColor,
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

