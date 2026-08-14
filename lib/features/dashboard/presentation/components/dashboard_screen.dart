import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/features/dashboard/bloc/recommendations_bloc.dart';
import 'package:zim_herbs_repo/features/dashboard/presentation/components/recommendation_widgets.dart';
import 'package:zim_herbs_repo/features/dashboard/presentation/components/menu_section.dart';
import 'package:zim_herbs_repo/features/repository/herbs/presentation/herbs_list.dart';
import 'package:zim_herbs_repo/features/marketplace/store/presentation/store_page.dart';
import 'package:zim_herbs_repo/core/theme/spacing.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback toogleDashbordSideBar;

  const DashboardScreen({super.key, required this.toogleDashbordSideBar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              
              // 1. Menu Grid (Advanced Layout)
              const MenuSection(),
              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                              const SizedBox(height: 40),
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
