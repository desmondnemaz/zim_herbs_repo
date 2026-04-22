import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/features/conditions/presentation/condition_list.dart';
import 'package:zim_herbs_repo/features/dashboard/bloc/recommendations_bloc.dart';
import 'package:zim_herbs_repo/features/dashboard/presentation/components/recommendation_widgets.dart';
import 'package:zim_herbs_repo/features/dashboard/presentation/coming_soon.dart';
import 'package:zim_herbs_repo/features/dashboard/presentation/components/menu_section.dart';
import 'package:zim_herbs_repo/features/herbs/presentation/herbs_list.dart';
import 'package:zim_herbs_repo/features/store/presentation/store_page.dart';
import 'package:zim_herbs_repo/features/telemedicine/presentation/telemedicine_page.dart';
import 'package:zim_herbs_repo/features/treatments/presentation/treatments_list.dart';
import 'package:zim_herbs_repo/theme/spacing.dart';
import 'package:zim_herbs_repo/features/dashboard/presentation/components/hero_header.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback toogleDashbordSideBar;

  const DashboardScreen({super.key, required this.toogleDashbordSideBar});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> dashboardCards = [
      {
        'icon': Icons.local_florist,
        'title': 'Herbs',
        'subtitle': '(A - Z)',
        'page': const HerbsList(),
      },
      {
        'icon': Icons.healing,
        'title': 'Treatments',
        'subtitle': '(By condition)',
        'page': const TreatmentsList(),
      },
      {
        'icon': Icons.sick_outlined,
        'title': 'Diseases',
        'subtitle': '(A - Z)',
        'page': const ConditionsListPage(),
      },
      {
        'icon': Icons.groups,
        'title': 'Practioneers',
        'subtitle': '(Licensed by MoHCC)',
        'page': const ComingSoonPage(),
      },
      {
        'icon': Icons.psychology_alt,
        'title': 'Knowledge',
        'subtitle': '(Resources)',
        'page': const ComingSoonPage(),
      },
      {
        'icon': Icons.lightbulb_outline,
        'title': 'Innovation',
        'subtitle': '(Contributions)',
        'page': const ComingSoonPage(),
      },
      {
        'icon': Icons.smart_toy_outlined,
        'title': 'AI Chatbot',
        'subtitle': '(Coming Soon)',
        'page': const ComingSoonPage(),
      },
      {
        'icon': Icons.storefront_outlined,
        'title': 'Herbal Store',
        'subtitle': '(Traditonal Products)',
        'page': const StorePage(),
      },
      {
        'icon': Icons.medical_services_outlined,
        'title': 'Telemedicine',
        'subtitle': '(Consultation)',
        'page': const TelemedicinePage(),
      },
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Search/Greeting Hero Section
              const HeroHeader(),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // ====== Recommendations Sections ======
                    BlocBuilder<RecommendationsBloc, RecommendationsState>(
                      builder: (context, state) {
                        if (state is RecommendationsLoading) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        } else if (state is RecommendationsLoaded) {
                          return Column(
                            children: [
                              // 2. Featured Herbs
                              SectionHeader(
                                title: "Featured Herbs",
                                onSeeAll: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const HerbsList(),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(
                                height: 220,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: state.trendingHerbs.length,
                                  itemBuilder: (context, index) {
                                    return HerbHighlightCard(
                                      herb: state.trendingHerbs[index],
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),

                              // 3. Featured Store Products
                              SectionHeader(
                                title: "Featured Store Products",
                                onSeeAll: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const StorePage(),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(
                                height: 220,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: state.newStoreProducts.length,
                                  itemBuilder: (context, index) {
                                    return ProductHighlightCard(
                                      product: state.newStoreProducts[index],
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          );
                        } else if (state is RecommendationsError) {
                          return Center(
                            child: Text(
                              "Error loading highlights: ${state.message}",
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    // 5. Menu Grid
                    const SizedBox(height: 10),
                    MenuSection(dashboardCards: dashboardCards),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
