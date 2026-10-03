import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zim_herbs_repo/core/errors/failure.dart';

/// A rich, responsive, theme-aware error view for screens and content sections
/// when fetching data or executing server operations fails.
class AppErrorView extends StatefulWidget {
  final Failure? failure;
  final String? message;
  final String? title;
  final FailureType type;
  final VoidCallback? onRetry;
  final String retryLabel;
  final VoidCallback? onBack;
  final String backLabel;
  final bool compact;
  final bool showDetails;
  final EdgeInsetsGeometry padding;

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
  });

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
      _ => 'Unable to Load Data',
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
      FailureType.serverUnavailable => Icons.cloud_off_rounded,
      FailureType.noInternet => Icons.wifi_off_rounded,
      FailureType.timeout => Icons.timer_off_outlined,
      FailureType.accessDenied => Icons.admin_panel_settings_outlined,
      FailureType.notFound => Icons.search_off_rounded,
      _ => Icons.error_outline_rounded,
    };
  }

  Color _accentColor(BuildContext context) {
    return switch (_effectiveType) {
      FailureType.serverUnavailable => const Color(0xFFEA580C), // Orange-red
      FailureType.noInternet || FailureType.timeout => const Color(0xFFD97706), // Amber
      FailureType.accessDenied => const Color(0xFF4F46E5), // Indigo
      _ => Theme.of(context).colorScheme.error,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _accentColor(context);
    final isDark = theme.brightness == Brightness.dark;

    final content = Center(
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
                  color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accent.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  _icon,
                  size: widget.compact ? 28 : 38,
                  color: accent,
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

              // Friendly Message
              Text(
                _effectiveMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: widget.compact ? 13 : 14.5,
                  height: 1.45,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
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
              if (widget.showDetails && widget.failure?.originalError != null) ...[
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
                                color: accent,
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
                                    if (mounted) setState(() => _copied = false);
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

    return content;
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
