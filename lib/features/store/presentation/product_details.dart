import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zim_herbs_repo/features/store/bloc/cart_cubit.dart';
import 'package:zim_herbs_repo/features/store/bloc/product_detail_cubit.dart';
import 'package:zim_herbs_repo/features/store/data/models/product_model.dart';
import 'package:zim_herbs_repo/features/store/data/repository/store_repository.dart';
import 'package:zim_herbs_repo/theme/spacing.dart';
import 'package:zim_herbs_repo/utils/responsive.dart';
import 'package:zim_herbs_repo/utils/responsive_sizes.dart';

class ProductDetailsPage extends StatefulWidget {
  final ProductModel product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final rs = ResponsiveSize(context);

    return BlocProvider(
      create:
          (context) => ProductDetailCubit(StoreRepository())
            ..loadProduct(widget.product.id, initialProduct: widget.product),
      child: BlocBuilder<ProductDetailCubit, ProductDetailState>(
        builder: (context, state) {
          if (state is ProductDetailLoading || state is ProductDetailInitial) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (state is ProductDetailError) {
            return Scaffold(
              appBar: AppBar(backgroundColor: colorScheme.primary),
              body: Center(child: Text(state.message)),
            );
          }

          if (state is ProductDetailLoaded) {
            final product = state.product;
            final quantity = state.quantity;

            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: CustomScrollView(
                slivers: [
                  // ================= App Bar =================
                  SliverAppBar(
                    centerTitle: true,
                    expandedHeight: Responsive.isMobile(context) ? 320 : null,
                    pinned: true,
                    backgroundColor: colorScheme.primary,
                    leading: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.black26,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: colorScheme.secondary,
                          size: rs.appBarIcon,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: true,
                      background:
                          Responsive.isMobile(context)
                              ? Hero(
                                tag: 'product-image-${product.name}',
                                child: Image.network(
                                  product.imageUrl,
                                  fit: BoxFit.cover,
                                ),
                              )
                              : null,
                    ),
                  ),

                  // ================= Content =================
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth:
                              Responsive.isMobile(context)
                                  ? double.infinity
                                  : Responsive.isTablet(context)
                                  ? 750
                                  : 800,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(defaultPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Mobile Name Badge
                              if (Responsive.isMobile(context)) ...[
                                _buildNameHeader(product.name, colorScheme, rs),
                                const SizedBox(height: 16),
                              ],

                              // Desktop/Tablet Image
                              if (!Responsive.isMobile(context)) ...[
                                Hero(
                                  tag: 'product-image-${product.name}',
                                  child: Container(
                                    height: 400,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          blurRadius: 10,
                                          color: Colors.black.withValues(
                                            alpha: 0.08,
                                          ),
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.network(
                                        product.imageUrl,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildNameHeader(product.name, colorScheme, rs),
                                const SizedBox(height: 24),
                              ],

                              // Product Info Section
                              _buildSectionCard(
                                icon: Icons.shopping_bag_outlined,
                                title: "Product Overview",
                                rs: rs,
                                content: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          product.price,
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w900,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              "4.8 (24 Reviews)",
                                              style: TextStyle(
                                                color:
                                                    colorScheme
                                                        .onSurfaceVariant,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "Description",
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "This high-quality ${product.name} is sourced directly from traditional growers in Zimbabwe. It is carefully processed to retain all its natural medicinal properties and nutrients. Perfect for daily use and traditional remedies.",
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                        height: 1.6,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Supplier Section
                              _buildSectionCard(
                                icon: Icons.verified_user_outlined,
                                title: "Supplier Details",
                                rs: rs,
                                accentColor: Colors.teal,
                                content: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.teal.withValues(
                                              alpha: 0.1,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.store_mall_directory_outlined,
                                            color: Colors.teal,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.supplierName,
                                              style: GoogleFonts.outfit(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.location_on_outlined,
                                                  size: 14,
                                                  color:
                                                      colorScheme
                                                          .onSurfaceVariant,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  product.supplierLocation,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color:
                                                        colorScheme
                                                            .onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.teal.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Text(
                                            "Verified",
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.teal,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "About the Supplier",
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "A trusted local partner specializing in sustainable harvesting and traditional processing methods in the ${product.supplierLocation.split(',')[0]} region.",
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                        height: 1.4,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Purchase Section
                              _buildSectionCard(
                                icon: Icons.add_shopping_cart,
                                title: "Purchase",
                                rs: rs,
                                content: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          "Quantity",
                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: colorScheme.outline
                                                  .withValues(alpha: 0.3),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              IconButton(
                                                onPressed:
                                                    () =>
                                                        context
                                                            .read<
                                                              ProductDetailCubit
                                                            >()
                                                            .decrementQuantity(),
                                                icon: const Icon(Icons.remove),
                                                color: colorScheme.primary,
                                              ),
                                              Text(
                                                quantity.toString(),
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: colorScheme.onSurface,
                                                ),
                                              ),
                                              IconButton(
                                                onPressed:
                                                    () =>
                                                        context
                                                            .read<
                                                              ProductDetailCubit
                                                            >()
                                                            .incrementQuantity(),
                                                icon: const Icon(Icons.add),
                                                color: colorScheme.primary,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 55,
                                      child: FilledButton(
                                        onPressed: () {
                                          context.read<CartCubit>().addToCart(
                                            product,
                                            quantity,
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "Added $quantity ${product.name} to cart",
                                              ),
                                              backgroundColor:
                                                  colorScheme.primary,
                                            ),
                                          );
                                        },
                                        style: FilledButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          backgroundColor: colorScheme.primary,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.shopping_cart_outlined,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              "Add to Cart",
                                              style: GoogleFonts.outfit(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 50),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget content,
    required ResponsiveSize rs,
    Color? accentColor,
  }) {
    final color = accentColor ?? Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            blurRadius: 15,
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: rs.titleFont,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          content,
        ],
      ),
    );
  }

  Widget _buildNameHeader(
    String name,
    ColorScheme colorScheme,
    ResponsiveSize rs,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: rs.titleFont,
          color: colorScheme.secondary,
        ),
      ),
    );
  }
}
