import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/features/dashboard/presentation/components/dashboard_screen.dart';
import 'package:zim_herbs_repo/features/dashboard/presentation/components/drawer_sidebar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/core/connection/bloc/connection_bloc.dart'
    as conn;
import 'package:zim_herbs_repo/utils/responsive.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Dashboard Drawer toggling
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSideBarVisible = true;

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);
    final isDesktop = Responsive.isDesktop(context);

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
                actions: [
                  const _OfflineBadge(),
                  if (Responsive.isTablet(context))
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: _ProfileSection(rs: rs),
                    ),
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
                            setState(() {
                              _isSideBarVisible = !_isSideBarVisible;
                            });
                          },
                          child: Icon(
                            Icons.menu,
                            size: rs.appBarIcon,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        SizedBox(width: rs.defaultPadding),
                        const _BrandLogo(),
                      ],
                    ),
                    const Spacer(),

                    const _OfflineBadge(),
                    const SizedBox(width: 16),

                    // Profile section (Desktop)
                    _ProfileSection(rs: rs),
                  ],
                ),
              ),

            // ================= Main Layout (Sidebar + Content) =================
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isDesktop && _isSideBarVisible)
                    const Expanded(flex: 1, child: DrawerSideBar()),

                  // Dashboard Main
                  Expanded(
                    flex: 5,
                    child: DashboardScreen(
                      toogleDashbordSideBar: () {
                        if (isDesktop) {
                          setState(() {
                            _isSideBarVisible = !_isSideBarVisible;
                          });
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

class _ProfileSection extends StatelessWidget {
  final ResponsiveSize rs;
  const _ProfileSection({required this.rs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(10),
          topLeft: Radius.circular(10),
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person,
            size: rs.appBarIcon * 0.8,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            "Desmond",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
              fontSize: rs.appBarSubtitleFont,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down,
            color: Theme.of(context).colorScheme.primary,
            size: rs.appBarIcon * 0.8,
          ),
        ],
      ),
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
