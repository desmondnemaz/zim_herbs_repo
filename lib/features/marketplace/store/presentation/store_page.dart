import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/features/marketplace/store/presentation/product_details.dart';
import 'package:zim_herbs_repo/features/marketplace/store/bloc/store_bloc.dart';
import 'package:zim_herbs_repo/features/marketplace/store/bloc/store_state.dart';
import 'package:zim_herbs_repo/features/marketplace/store/bloc/store_event.dart';
import 'package:zim_herbs_repo/features/marketplace/store/bloc/cart_cubit.dart';
import 'package:zim_herbs_repo/features/marketplace/store/bloc/cart_state.dart';
import 'package:zim_herbs_repo/features/marketplace/store/data/models/product_model.dart';
import 'package:zim_herbs_repo/core/components/app_error_view.dart';
import 'package:zim_herbs_repo/features/marketplace/store/presentation/components/cart_summary_sheet.dart';

import 'package:zim_herbs_repo/core/components/app_page_header.dart';
import 'package:zim_herbs_repo/core/utils/responsive.dart';

class StorePage extends StatelessWidget {
  final VoidCallback? onBack;
  const StorePage({super.key, this.onBack});

  Widget _buildCartButton(BuildContext context, ColorScheme colorScheme) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const CartSummarySheet(),
                );
              },
              icon: const Icon(
                Icons.shopping_cart_outlined,
                size: 24,
              ),
              tooltip: 'Shopping Cart',
            ),
            if (state.items.isNotEmpty)
              Positioned(
                right: 4,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    state.items.length.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: isDesktop
          ? null
          : AppPageAppBar(
              title: 'Marketplace',
              onBack: onBack,
              actions: [
                _buildCartButton(context, colorScheme),
                const SizedBox(width: 8),
              ],
            ),
      body: SafeArea(
        child: Column(
          children: [
            // Body Surface Header (domain standard)
            AppPageHeader(
              title: 'Marketplace',
              subtitle:
                  'Explore authentic traditional herbal remedies, supplements, and wellness formulations',
              icon: Icons.storefront_rounded,
              iconColor: const Color(0xFFA85B18),
              onBack: onBack,
              trailing: _buildCartButton(context, colorScheme),
            ),

            // Category Filter Chips
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: colorScheme.surface,
              child: BlocBuilder<StoreBloc, StoreState>(
                builder: (context, state) {
                  final selectedCategory = (state is StoreLoaded)
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

            // Informative Notice Banner
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFA85B18).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFA85B18).withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA85B18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "COMING SOON",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Store preview — products, prices, and stock listings currently display demonstration sample data.",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Products Grid
            Expanded(
              child: BlocBuilder<StoreBloc, StoreState>(
                builder: (context, state) {
                  if (state is StoreLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is StoreError) {
                    return AppErrorView(
                      failure: state.failure,
                      message: state.message,
                      onRetry: () =>
                          context.read<StoreBloc>().add(FetchProducts()),
                    );
                  } else if (state is StoreLoaded) {
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 220,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: state.products.length,
                      itemBuilder: (context, index) {
                        return _ProductCard(product: state.products[index]);
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
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
