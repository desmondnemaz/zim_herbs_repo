import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/features/dashboard/bloc/dashboard_cubit.dart';
import 'package:zim_herbs_repo/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/features/dashboard/presentation/components/dashboard_screen.dart';
import 'package:zim_herbs_repo/features/dashboard/presentation/components/drawer_sidebar.dart';
import 'package:zim_herbs_repo/core/connection/bloc/connection_bloc.dart'
    as conn;
import 'package:zim_herbs_repo/utils/responsive.dart';

import 'package:zim_herbs_repo/features/dashboard/bloc/recommendations_bloc.dart';
import 'package:zim_herbs_repo/features/herbs/data/herb_repository.dart';
import 'package:zim_herbs_repo/features/store/data/repository/store_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Dashboard Drawer toggling
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);
    final isDesktop = Responsive.isDesktop(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => DashboardCubit()),
        BlocProvider(
          create:
              (context) => RecommendationsBloc(
                herbRepository: HerbRepository(),
                storeRepository: StoreRepository(),
              )..add(FetchRecommendations()),
        ),
      ],
      child: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          return Scaffold(
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
                      elevation: 0,
                      title: const _BrandLogo(),
                      centerTitle: false,
                      shape: Border(
                        bottom: BorderSide(
                          width: 2,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      actions: const [
                        _OfflineBadge(),
                      ],
                      iconTheme: IconThemeData(
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: rs.appBarIcon,
                      ),
                    )
                    : null,

            body: SafeArea(
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
                        border: Border(
                          bottom: BorderSide(
                            width: 2,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Brand & Menu Toggle
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  context
                                      .read<DashboardCubit>()
                                      .toggleSidebar();
                                },
                                child: Icon(
                                  Icons.menu,
                                  size: rs.appBarIcon,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                              SizedBox(width: rs.defaultPadding),
                              const _BrandLogo(),
                            ],
                          ),
                          const Spacer(),

                          const _OfflineBadge(),
                        ],
                      ),
                    ),

                  // ================= Main Layout (Sidebar + Content) =================
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isDesktop && state.isSidebarVisible)
                          const Expanded(flex: 1, child: DrawerSideBar()),

                        // Dashboard Main
                        Expanded(
                          flex: 5,
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            "ZIM Herbal Pharmacy",
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: rs.appBarTitleFont,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Icon(
          Icons.grass,
          size: rs.appBarIcon,
          color: Theme.of(context).colorScheme.secondary,
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
