import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/theme/light_mode.dart';
import 'package:zim_herbs_repo/theme/spacing.dart';
import 'package:zim_herbs_repo/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/features/herbs/data/herb_repository.dart';
import 'package:zim_herbs_repo/features/herbs/data/models.dart';
import 'package:zim_herbs_repo/utils/responsive.dart';

class HerbDetailsPage extends StatefulWidget {
  final String herbId;

  const HerbDetailsPage({super.key, required this.herbId});

  @override
  State<HerbDetailsPage> createState() => _HerbDetailsPageState();
}

class _HerbDetailsPageState extends State<HerbDetailsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final HerbRepository _repository = HerbRepository();
  late Future<HerbModel?> _herbFuture;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
    _herbFuture = _repository.getHerbById(widget.herbId);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);

    return FutureBuilder<HerbModel?>(
      future: _herbFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: pharmacyTheme.colorScheme.primary,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Center(
              child: Text(
                snapshot.hasError
                    ? 'Error: ${snapshot.error}'
                    : 'Herb not found',
              ),
            ),
          );
        }

        final herb = snapshot.data!;

        return Scaffold(
          backgroundColor: pharmacyTheme.scaffoldBackgroundColor,
          body: CustomScrollView(
            slivers: [
              // Collapsible App Bar
              SliverAppBar(
                centerTitle: true,
                expandedHeight: Responsive.isMobile(context) ? 280 : null,
                pinned: true,
                backgroundColor: pharmacyTheme.colorScheme.primary,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: rs.appBarIcon,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: pharmacyTheme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          herb.nameEn,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: Responsive.isMobile(context) ? 16 : 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  background:
                      Responsive.isMobile(context)
                          ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Hero(
                                tag: 'herb-image-${herb.nameEn}',
                                child:
                                    herb.primaryImageUrl != null
                                        ? Image.network(
                                          herb.primaryImageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                                    color: Colors.grey,
                                                    child: const Icon(
                                                      Icons.spa,
                                                      color: Colors.white,
                                                      size: 50,
                                                    ),
                                                  ),
                                        )
                                        : Container(
                                          color: Colors.grey.withValues(
                                            alpha: 0.3,
                                          ),
                                          child: Icon(
                                            Icons.spa,
                                            color:
                                                pharmacyTheme
                                                    .colorScheme
                                                    .primary,
                                            size: 50,
                                          ),
                                        ),
                              ),
                              // Gradient overlay for better text visibility
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.7),
                                    ],
                                    stops: const [0.5, 1.0],
                                  ),
                                ),
                              ),
                            ],
                          )
                          : null,
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
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
                              // Desktop/Tablet Hero Image (Constrained to card width)
                              if (!Responsive.isMobile(context)) ...[
                                Hero(
                                  tag: 'herb-image-${herb.nameEn}',
                                  child: Container(
                                    height: 350,
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
                                      child:
                                          herb.primaryImageUrl != null
                                              ? Image.network(
                                                herb.primaryImageUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (context, e, s) =>
                                                        Container(
                                                          color: Colors.grey,
                                                          child: const Icon(
                                                            Icons.spa,
                                                            color: Colors.white,
                                                            size: 60,
                                                          ),
                                                        ),
                                              )
                                              : Container(
                                                color: Colors.grey.withValues(
                                                  alpha: 0.3,
                                                ),
                                                child: Icon(
                                                  Icons.spa,
                                                  color:
                                                      pharmacyTheme
                                                          .colorScheme
                                                          .primary,
                                                  size: 60,
                                                ),
                                              ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],

                              // Category & Scientific Name Chips
                              _buildHeaderChips(herb, rs),
                              const SizedBox(height: 20),

                              // Description Section
                              if (herb.description != null &&
                                  herb.description!.isNotEmpty)
                                _buildSectionCard(
                                  icon: Icons.description_outlined,
                                  title: "About",
                                  content: Text(
                                    herb.description!,
                                    style: TextStyle(
                                      fontSize: rs.subtitleFont,
                                      height: 1.5,
                                      color:
                                          pharmacyTheme.colorScheme.onSurface,
                                    ),
                                  ),
                                  rs: rs,
                                ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderChips(HerbModel herb, ResponsiveSize rs) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: pharmacyTheme.colorScheme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  "English: ${herb.nameEn}",
                  style: TextStyle(
                    fontSize: rs.subtitleFont - 2,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (herb.nameSn != null && herb.nameSn!.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: pharmacyTheme.colorScheme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.translate, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    "Shona: ${herb.nameSn!}",
                    style: TextStyle(
                      fontSize: rs.subtitleFont - 2,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        if (herb.nameNd != null && herb.nameNd!.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: pharmacyTheme.colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: pharmacyTheme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.translate,
                  size: 16,
                  color: pharmacyTheme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    "Ndebele: ${herb.nameNd!}",
                    style: TextStyle(
                      fontSize: rs.subtitleFont - 2,
                      color: pharmacyTheme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget content,
    required ResponsiveSize rs,
    Color? accentColor,
  }) {
    final color = accentColor ?? pharmacyTheme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pharmacyTheme.colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: rs.subtitleFont + 2,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }
}
