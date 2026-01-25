import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/features/store/presentation/product_details.dart';
import 'package:zim_herbs_repo/features/store/bloc/store_bloc.dart';
import 'package:zim_herbs_repo/features/store/bloc/store_state.dart';
import 'package:zim_herbs_repo/features/store/bloc/store_event.dart';
import 'package:zim_herbs_repo/features/store/bloc/cart_cubit.dart';
import 'package:zim_herbs_repo/features/store/bloc/cart_state.dart';
import 'package:zim_herbs_repo/features/store/data/models/product_model.dart';

class StorePage extends StatelessWidget {
  const StorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // ================= App Bar =================
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 140.0,
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.secondary,
            centerTitle: true,
            title: Text(
              'Herbal Marketplace',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: colorScheme.secondary,
              ),
            ),
            actions: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: BlocBuilder<CartCubit, CartState>(
                  builder: (context, state) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                            // TODO: Show cart summary
                          },
                          icon: const Icon(
                            Icons.shopping_cart_outlined,
                            size: 28,
                          ),
                        ),
                        if (state.items.isNotEmpty)
                          Positioned(
                            right: 4,
                            top: 10,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: colorScheme.secondary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                state.items.length.toString(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: colorScheme.surface,
                child: BlocBuilder<StoreBloc, StoreState>(
                  builder: (context, state) {
                    final selectedCategory =
                        (state is StoreLoaded)
                            ? state.selectedCategory ?? 'All'
                            : 'All';
                    return ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _CategoryChip(
                          label: 'All',
                          isSelected: selectedCategory == 'All',
                        ),
                        _CategoryChip(
                          label: 'Dried Herbs',
                          isSelected: selectedCategory == 'Dried Herbs',
                        ),
                        _CategoryChip(
                          label: 'Tinctures',
                          isSelected: selectedCategory == 'Tinctures',
                        ),
                        _CategoryChip(
                          label: 'Essential Oils',
                          isSelected: selectedCategory == 'Essential Oils',
                        ),
                        _CategoryChip(
                          label: 'Supplements',
                          isSelected: selectedCategory == 'Supplements',
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),

          // ================= Product Grid =================
          BlocBuilder<StoreBloc, StoreState>(
            builder: (context, state) {
              if (state is StoreLoading) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              } else if (state is StoreError) {
                return SliverFillRemaining(
                  child: Center(child: Text(state.message)),
                );
              } else if (state is StoreLoaded) {
                return SliverPadding(
                  padding: const EdgeInsets.all(12),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return _ProductCard(product: state.products[index]);
                    }, childCount: state.products.length),
                  ),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),

          // ================= Footer Space =================
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _CategoryChip({required this.label, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          if (val) {
            context.read<StoreBloc>().add(FetchProducts(category: label));
          }
        },
        backgroundColor: colorScheme.surface,
        selectedColor: colorScheme.secondary.withValues(alpha: 0.3),
        checkmarkColor: colorScheme.primary,
        labelStyle: TextStyle(
          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color:
                isSelected
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsPage(product: product),
          ),
        );
      },
      child: Card(
        color: colorScheme.primary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Hero(
                  tag: 'product-image-${product.name}',
                  child: Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: colorScheme.onPrimary.withValues(alpha: 0.2),
                        child: Center(
                          child: Icon(
                            Icons.eco_outlined,
                            size: 40,
                            color: colorScheme.onPrimary.withValues(alpha: 0.5),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.price,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: colorScheme.secondary,
                          fontSize: 14,
                        ),
                      ),
                      Icon(
                        Icons.add_shopping_cart,
                        size: 16,
                        color: colorScheme.secondary,
                      ),
                    ],
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
