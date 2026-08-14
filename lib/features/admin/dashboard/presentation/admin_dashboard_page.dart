import 'package:flutter/material.dart';
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

class AdminDashboardPage extends StatefulWidget {
  final UserModel user;
  const AdminDashboardPage({super.key, required this.user});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _activeIndex = 0;

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);
    final isDesktop = Responsive.isDesktop(context);

    return BlocProvider(
      create: (_) => DashboardCubit(),
      child: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: Theme.of(context).colorScheme.surface,

            // Sidebar for Mobile/Tablet
            drawer: !isDesktop
                ? AdminDrawerSideBar(
                    activeIndex: _activeIndex,
                    onNavTap: (i) => setState(() => _activeIndex = i),
                  )
                : null,

            // ================= AppBar for Mobile/Tablet =================
            appBar: !isDesktop
                ? AppBar(
                    toolbarHeight: rs.appBarHeight,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    elevation: 4,
                    shadowColor:
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                    title: const _AdminBrandLogo(),
                    centerTitle: false,
                    actions: const [
                      _OfflineBadge(),
                      SizedBox(width: 4),
                      _AdminProfileAvatar(),
                      SizedBox(width: 8),
                    ],
                    iconTheme: IconThemeData(
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: rs.appBarIcon,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                  )
                : null,

            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isDesktop)
                  AdminDrawerSideBar(
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
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Admin badge chip
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondary
                                      .withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified_user,
                                        size: 13,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.user.name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              const _OfflineBadge(),
                              const SizedBox(width: 12),
                              const _AdminProfileAvatar(),
                              const SizedBox(width: 4),
                            ],
                          ),
                        ),

                      // ===== Main Admin Content =====
                      Expanded(
                        child: AdminDashboardScreen(
                          activeIndex: _activeIndex,
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

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);
    final theme = Theme.of(context);
    final double radius = rs.pick(mobile: 17, tablet: 19, desktop: 21);

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final userName = state is Authenticated ? state.user.name : 'Admin';
        final userRole =
            state is Authenticated ? state.user.role.displayName : 'Administrator';

        return GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: theme.colorScheme.primary,
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(userName,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                        userRole,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      ListTile(
                        leading:
                            const Icon(Icons.logout, color: Colors.redAccent),
                        title: const Text('Sign Out',
                            style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold)),
                        onTap: () {
                          Navigator.pop(context);
                          context.read<AuthCubit>().signOut();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.secondary.withValues(alpha: 0.7),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: radius,
              backgroundColor: theme.colorScheme.secondary,
              child: Icon(
                Icons.admin_panel_settings_outlined,
                color: theme.colorScheme.primary,
                size: radius,
              ),
            ),
          ),
        );
      },
    );
  }
}
