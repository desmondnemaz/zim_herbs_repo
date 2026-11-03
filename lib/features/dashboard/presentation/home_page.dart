import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_cubit.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_state.dart';
import 'package:zim_herbs_repo/features/dashboard/bloc/dashboard_cubit.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/features/dashboard/presentation/components/dashboard_screen.dart';
import 'package:zim_herbs_repo/features/dashboard/presentation/components/drawer_sidebar.dart';
import 'package:zim_herbs_repo/core/connection/bloc/connection_bloc.dart'
    as conn;
import 'package:zim_herbs_repo/core/utils/responsive.dart';

import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:zim_herbs_repo/features/dashboard/bloc/recommendations_bloc.dart';
import 'package:zim_herbs_repo/features/repository/herbs/data/datasources/herb_remote_datasource.dart';
import 'package:zim_herbs_repo/features/repository/herbs/data/repositories/herb_repository_impl.dart';
import 'package:zim_herbs_repo/features/marketplace/store/data/repository/store_repository.dart';
import 'package:zim_herbs_repo/features/admin/dashboard/presentation/admin_dashboard_page.dart';
import 'package:zim_herbs_repo/core/components/portal_switch_dialog.dart';
import 'package:zim_herbs_repo/core/components/app_page_app_bar.dart';
import 'package:zim_herbs_repo/features/profile/presentation/profile_page.dart';
import 'package:zim_herbs_repo/features/repository/herbs/presentation/pages/herbs_list.dart';
import 'package:zim_herbs_repo/features/repository/ailments/presentation/ailment_list.dart';
import 'package:zim_herbs_repo/features/repository/remedies/presentation/pages/remedies_list.dart';
import 'package:zim_herbs_repo/features/marketplace/store/presentation/store_page.dart';
import 'package:zim_herbs_repo/features/settings/presentation/settings_page.dart';
import 'package:zim_herbs_repo/features/notifications/presentation/notifications_page.dart';
import 'package:zim_herbs_repo/features/repository/contributions/presentation/contributions_page.dart';
import 'package:zim_herbs_repo/features/telemedicine/presentation/telemedicine_page.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Dashboard Drawer toggling
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _activeIndex = 0;

  static const _sectionsWithOwnHeader = {1, 2, 3, 4, 5, 6};

  String _getSectionTitle(int index) {
    switch (index) {
      case 1:
        return 'Herbs Catalog';
      case 2:
        return 'Ailments Catalog';
      case 3:
        return 'Remedies Catalog';
      case 4:
        return 'Marketplace';
      case 5:
        return 'Contributions';
      case 6:
        return 'Telemedicine';
      default:
        return 'Dashboard';
    }
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 1:
        return HerbsList(
          isPublicView: true,
          onBack: () => setState(() => _activeIndex = 0),
        );
      case 2:
        return AilmentsListPage(
          isPublicView: true,
          onBack: () => setState(() => _activeIndex = 0),
        );
      case 3:
        return RemediesList(
          isPublicView: true,
          onBack: () => setState(() => _activeIndex = 0),
        );
      case 4:
        return StorePage(
          onBack: () => setState(() => _activeIndex = 0),
        );
      case 5:
        return ContributionsPage(
          onBack: () => setState(() => _activeIndex = 0),
        );
      case 6:
        return TelemedicinePage(
          onBack: () => setState(() => _activeIndex = 0),
        );
      default:
        return DashboardScreen(
          toogleDashbordSideBar: () {
            if (Responsive.isDesktop(context)) {
              context.read<DashboardCubit>().toggleSidebar();
            } else {
              _scaffoldKey.currentState?.openDrawer();
            }
          },
          onNavigate: (i) => setState(() => _activeIndex = i),
        );
    }
  }

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
      elevation: 4,
      shadowColor: colorScheme.primary.withValues(alpha: 0.4),
      titleWidget: const _BrandLogo(),
      centerTitle: false,
      iconTheme: IconThemeData(
        color: colorScheme.onPrimary,
        size: rs.appBarIcon,
      ),
      actions: const [
        _OfflineBadge(),
        SizedBox(width: 4),
        _ProfileAvatar(),
        SizedBox(width: 8),
      ],
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);
    final isDesktop = Responsive.isDesktop(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => DashboardCubit()),
        BlocProvider(
          create: (context) {
            final client = Supabase.instance.client;
            final dataSource = HerbRemoteDataSource(client);
            final herbRepository = HerbRepositoryImpl(dataSource);
            return RecommendationsBloc(
              herbRepository: herbRepository,
              storeRepository: StoreRepository(),
            )..add(FetchRecommendations());
          },
        ),
      ],
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

              // 2. If viewing a secondary section within shell, return to Dashboard
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
            backgroundColor: Theme.of(context).colorScheme.surface,

            // Sidebar for Mobile/Tablet
            drawer: !isDesktop
                ? DrawerSideBar(
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
                  DrawerSideBar(
                    isExpanded: state.isSidebarVisible,
                    onToggle: () {
                      context.read<DashboardCubit>().toggleSidebar();
                    },
                    activeIndex: _activeIndex,
                    onNavTap: (i) => setState(() => _activeIndex = i),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      // ================= Persistent Global Header (Desktop Only) =================
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
                                    "Zim Herbs",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.65),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
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

                              // Action: View Admin Console (if staff/moderator/admin)
                              Builder(
                                builder: (context) {
                                  try {
                                    final authState =
                                        context.watch<AuthCubit>().state;
                                    if (authState is Authenticated &&
                                        authState.user.canModerate) {
                                      return Material(
                                        color: Colors.white.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                        child: InkWell(
                                          onTap: () async {
                                            final confirmed =
                                                await showPortalSwitchConfirmation(
                                              context: context,
                                              toAdmin: true,
                                            );
                                            if (confirmed && context.mounted) {
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      AdminDashboardPage(
                                                    user: authState.user,
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 7,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.admin_panel_settings_outlined,
                                                  size: 14,
                                                  color: Colors.white
                                                      .withValues(alpha: 0.9),
                                                ),
                                                const SizedBox(width: 6),
                                                const Text(
                                                  "View Admin App",
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
                                      );
                                    }
                                  } catch (_) {}
                                  return const SizedBox.shrink();
                                },
                              ),
                              const SizedBox(width: 14),
                              const _OfflineBadge(),
                              const SizedBox(width: 14),
                              const _ProfileAvatar(),
                            ],
                          ),
                        ),

                      // ================= Main Layout (Public Content) =================
                      Expanded(
                        child: _buildScreen(_activeIndex),
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

class _BrandLogo extends StatelessWidget {
  const _BrandLogo();

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);
    final logoSize = rs.appBarHeight * 0.65;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo image
        Image.asset(
          'assets/logo/logo.png',
          height: logoSize,
          width: logoSize,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Icon(
            Icons.grass,
            size: logoSize,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        const SizedBox(width: 10),
        // Brand text
        Flexible(
          child: Text(
            "ZIM-HERBS",
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: rs.appBarTitleFont,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
      ],
    );
  }
}

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
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
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

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();

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
    return 'U';
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
        final userName = state is Authenticated ? state.user.name : 'User';
        final userEmail = state is Authenticated ? state.user.email : null;
        final userRole =
            state is Authenticated ? state.user.role.displayName : 'Customer';
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

