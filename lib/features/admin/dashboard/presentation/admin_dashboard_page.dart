import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/core/connection/bloc/connection_bloc.dart' as conn;
import 'package:zim_herbs_repo/core/utils/responsive.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_cubit.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_state.dart';
import 'package:zim_herbs_repo/features/auth/domain/user_model.dart';
import 'package:zim_herbs_repo/features/dashboard/bloc/dashboard_cubit.dart';
import 'package:zim_herbs_repo/features/admin/dashboard/presentation/components/admin_drawer_sidebar.dart';
import 'package:zim_herbs_repo/features/admin/dashboard/presentation/components/admin_dashboard_screen.dart';
import 'package:zim_herbs_repo/features/dashboard/presentation/home_page.dart';
import 'package:zim_herbs_repo/core/components/portal_switch_dialog.dart';
import 'package:zim_herbs_repo/core/components/app_page_app_bar.dart';
import 'package:zim_herbs_repo/features/profile/presentation/profile_page.dart';
import 'package:zim_herbs_repo/features/settings/presentation/settings_page.dart';
import 'package:zim_herbs_repo/features/notifications/presentation/notifications_page.dart';

class AdminDashboardPage extends StatefulWidget {
  final UserModel user;
  const AdminDashboardPage({super.key, required this.user});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _activeIndex = 0;

  Future<bool> _onWillPop(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(
          Icons.exit_to_app_rounded,
          size: 40,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text(
          'Exit Zim Herbs?',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to exit the application?',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Stay'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  String _getSectionTitle(int index) {
    switch (index) {
      case 0:
        return 'Overview';
      case 1:
        return 'Moderation';
      case 2:
        return 'Herb Management';
      case 3:
        return 'Conditions';
      case 4:
        return 'Remedies';
      case 5:
        return 'Marketplace';
      case 6:
        return 'User Management';
      case 7:
        return 'Reports';
      case 8:
        return 'Analytics';
      case 9:
        return 'Body Parts';
      default:
        return 'Overview';
    }
  }

  /// Sections whose screens render their own header with a back button
  /// (HerbsList, ConditionsListPage, RemediesList, StorePage via `onBack`).
  /// The shell must not stack its navbar on top of them.
  static const _sectionsWithOwnHeader = {2, 3, 4, 5, 7, 8, 9};

  /// Mobile/Tablet app bar, chosen per section:
  /// - Overview (home): brand navbar with drawer, offline badge and profile.
  /// - Sections with their own header: no shell app bar at all.
  /// - Other sections: a plain back app bar that returns to Overview.
  PreferredSizeWidget? _buildMobileAppBar(
    BuildContext context,
    ResponsiveSize rs,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_sectionsWithOwnHeader.contains(_activeIndex)) {
      return null;
    }

    if (_activeIndex != 0) {
      return AppPageAppBar(
        toolbarHeight: rs.appBarHeight,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => setState(() => _activeIndex = 0),
        ),
        title: _getSectionTitle(_activeIndex),
        actions: const [
          _OfflineBadge(),
          SizedBox(width: 8),
        ],
      );
    }

    return AppPageAppBar(
      toolbarHeight: rs.appBarHeight,
      titleWidget: const _AdminBrandLogo(),
      elevation: 4,
      shadowColor: colorScheme.primary.withValues(alpha: 0.4),
      actions: const [
        _OfflineBadge(),
        SizedBox(width: 4),
        _AdminProfileAvatar(),
        SizedBox(width: 8),
      ],
      iconTheme: IconThemeData(
        color: colorScheme.onPrimary,
        size: rs.appBarIcon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);
    final isDesktop = Responsive.isDesktop(context);

    return BlocProvider(
      create: (_) => DashboardCubit(),
      child: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) async {
              if (didPop) return;

              // 1. If mobile drawer is open, close it first
              if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
                _scaffoldKey.currentState?.closeDrawer();
                return;
              }

              // 2. If not on Overview (home), navigate back to Overview
              if (_activeIndex != 0) {
                setState(() => _activeIndex = 0);
                return;
              }

              // 3. If there are routes to pop in the Navigator, pop them
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
                return;
              }

              // 4. Only when on home with no previous routes, confirm exit
              final shouldExit = await _onWillPop(context);
              if (shouldExit) {
                if (Platform.isAndroid) {
                  SystemNavigator.pop();
                } else {
                  exit(0);
                }
              }
            },
            child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: const Color(0xFFF3F8F2),

            // Sidebar for Mobile/Tablet
            drawer: !isDesktop
                ? AdminDrawerSideBar(
                    user: widget.user,
                    activeIndex: _activeIndex,
                    onNavTap: (i) => setState(() => _activeIndex = i),
                  )
                : null,

            // ================= AppBar for Mobile/Tablet =================
            appBar: !isDesktop ? _buildMobileAppBar(context, rs) : null,

            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isDesktop)
                  AdminDrawerSideBar(
                    user: widget.user,
                    isExpanded: state.isSidebarVisible,
                    onToggle: () => context.read<DashboardCubit>().toggleSidebar(),
                    activeIndex: _activeIndex,
                    onNavTap: (i) => setState(() => _activeIndex = i),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      // ===== Persistent Global Header (Desktop Only) =====
                      if (isDesktop)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.10),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Contextual breadcrumb
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.user.isAdmin
                                        ? "Admin Console"
                                        : "Moderator Console",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.65),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Icon(
                                      Icons.chevron_right_rounded,
                                      size: 16,
                                      color: Colors.white.withValues(alpha: 0.45),
                                    ),
                                  ),
                                  Text(
                                    _getSectionTitle(_activeIndex),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),

                              // Action: View Public App
                              Material(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                child: InkWell(
                                  onTap: () async {
                                    final confirmed = await showPortalSwitchConfirmation(
                                      context: context,
                                      toAdmin: false,
                                    );
                                    if (confirmed && context.mounted) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => const HomePage()),
                                      );
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 7,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.open_in_new_rounded,
                                          size: 14,
                                          color: Colors.white.withValues(alpha: 0.9),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          "View Public App",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              const _OfflineBadge(),
                              const SizedBox(width: 14),
                              const _AdminProfileAvatar(),
                            ],
                          ),
                        ),

                      // ===== Main Admin Content =====
                      Expanded(
                        child: AdminDashboardScreen(
                          user: widget.user,
                          activeIndex: _activeIndex,
                          onNavigate: (i) => setState(() => _activeIndex = i),
                          onToggleSidebar: () {
                            if (isDesktop) {
                              context.read<DashboardCubit>().toggleSidebar();
                            } else {
                              _scaffoldKey.currentState?.openDrawer();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Brand Logo ────────────────────────────────────────────────────────────────
class _AdminBrandLogo extends StatelessWidget {
  const _AdminBrandLogo();

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);
    final logoSize = rs.appBarHeight * 0.55;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.admin_panel_settings,
            size: logoSize, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            "ZIM-HERBS ADMIN",
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: rs.appBarTitleFont * 0.9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.3,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Offline Badge ──────────────────────────────────────────────────────────────
class _OfflineBadge extends StatelessWidget {
  const _OfflineBadge();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<conn.ConnectionBloc, conn.ConnectionState>(
      builder: (context, state) {
        if (state.status != conn.ConnectionStatus.offline) {
          return const SizedBox.shrink();
        }
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.redAccent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off, color: Colors.white, size: 12),
              SizedBox(width: 4),
              Text(
                "OFFLINE",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Profile Avatar ─────────────────────────────────────────────────────────────
class _AdminProfileAvatar extends StatelessWidget {
  const _AdminProfileAvatar();

  static String _extractInitials(String name, [String? email]) {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) {
      final parts =
          trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      } else if (parts.isNotEmpty && parts.first.isNotEmpty) {
        return parts.first[0].toUpperCase();
      }
    }
    if (email != null && email.trim().isNotEmpty) {
      final emailName = email.trim().split('@').first;
      if (emailName.isNotEmpty) {
        return emailName[0].toUpperCase();
      }
    }
    return 'A';
  }

  static void _showSignOutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFD32F2F)),
            SizedBox(width: 10),
            Text(
              'Sign Out',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out of your account?',
          style: TextStyle(color: Color(0xFF4B5563), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
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
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<AuthCubit>().signOut();
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);
    final theme = Theme.of(context);
    final double radius = rs.pick(mobile: 17, tablet: 18, desktop: 18);

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final userName = state is Authenticated ? state.user.name : 'Admin';
        final userEmail = state is Authenticated ? state.user.email : null;
        final userRole = state is Authenticated
            ? state.user.role.displayName
            : 'Administrator';
        final initials = _extractInitials(userName, userEmail);

        return Theme(
          data: theme.copyWith(
            popupMenuTheme: PopupMenuThemeData(
              color: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              elevation: 8,
            ),
          ),
          child: PopupMenuButton<int>(
            tooltip: '$userName - Profile & Account',
            offset: const Offset(0, 48),
            onSelected: (value) {
              switch (value) {
                case 1:
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  );
                  break;
                case 2:
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  );
                  break;
                case 3:
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsPage()),
                  );
                  break;
                case 4:
                  _showSignOutConfirmation(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              // ── Header: User Identity ──
              PopupMenuItem<int>(
                enabled: false,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF1E293B),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (userEmail != null && userEmail.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              userEmail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              userRole,
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 1),

              // ── View Full Profile ──
              const PopupMenuItem<int>(
                value: 1,
                child: Row(
                  children: [
                    Icon(Icons.person_rounded,
                        size: 20, color: Color(0xFF334155)),
                    SizedBox(width: 12),
                    Text(
                      'View Profile',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Settings ──
              const PopupMenuItem<int>(
                value: 2,
                child: Row(
                  children: [
                    Icon(Icons.settings_rounded,
                        size: 20, color: Color(0xFF334155)),
                    SizedBox(width: 12),
                    Text(
                      'Account Settings',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Notifications ──
              const PopupMenuItem<int>(
                value: 3,
                child: Row(
                  children: [
                    Icon(Icons.notifications_rounded,
                        size: 20, color: Color(0xFF334155)),
                    SizedBox(width: 12),
                    Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),

              const PopupMenuDivider(height: 1),

              // ── Sign Out ──
              const PopupMenuItem<int>(
                value: 4,
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded,
                        size: 20, color: Color(0xFFD32F2F)),
                    SizedBox(width: 12),
                    Text(
                      'Sign Out',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD32F2F),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: radius,
                backgroundColor: Colors.white,
                child: Text(
                  initials,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: rs.pick(mobile: 12, tablet: 12, desktop: 12),
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
