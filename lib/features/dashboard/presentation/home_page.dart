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


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Dashboard Drawer toggling
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
            drawer: !isDesktop ? const DrawerSideBar() : null,

            // ================= AppBar for Mobile/Tablet =================
            appBar:
                !isDesktop
                    ? AppBar(
                      toolbarHeight: rs.appBarHeight,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      elevation: 4,
                      shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                      title: const _BrandLogo(),
                      centerTitle: false,
                      actions: const [
                        _OfflineBadge(),
                        SizedBox(width: 4),
                        _ProfileAvatar(),
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
                  DrawerSideBar(
                    isExpanded: state.isSidebarVisible,
                    onToggle: () {
                      context.read<DashboardCubit>().toggleSidebar();
                    },
                  ),
                Expanded(
                  child: Column(
                    children: [
                      // ================= Persistant Global Header (Desktop Only) =================
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
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Spacer(),
                              _OfflineBadge(),
                              SizedBox(width: 12),
                              _ProfileAvatar(),
                              SizedBox(width: 4),
                            ],
                          ),
                        ),

                      // ================= Main Layout (Dashboard Content) =================
                      Expanded(
                        child: DashboardScreen(
                          toogleDashbordSideBar: () {
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

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);
    final theme = Theme.of(context);
    final double radius = rs.pick(mobile: 17, tablet: 19, desktop: 21);

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final userName = state is Authenticated ? state.user.name : 'User';
        final userRole = state is Authenticated ? state.user.role.displayName : 'Customer';

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
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        userRole,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.redAccent),
                        title: const Text(
                          'Sign Out',
                          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                        ),
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
                Icons.person_outline,
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

