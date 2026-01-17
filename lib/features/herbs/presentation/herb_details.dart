import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/theme/spacing.dart';
import 'package:zim_herbs_repo/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/features/herbs/data/herb_repository.dart';
import 'package:zim_herbs_repo/features/herbs/data/models.dart';
import 'package:zim_herbs_repo/utils/responsive.dart';
import 'package:zim_herbs_repo/features/treatments/data/treatment_repository.dart';
import 'package:zim_herbs_repo/features/treatments/data/treatment_models.dart';
import 'package:zim_herbs_repo/features/treatments/presentation/treatments_list.dart';

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
  final TreatmentRepository _treatmentRepository = TreatmentRepository();
  late Future<List<TreatmentModel>> _treatmentsFuture;
  
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

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
    _treatmentsFuture = _treatmentRepository.getTreatmentsByHerbId(widget.herbId);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
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
              backgroundColor: Theme.of(context).colorScheme.primary,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).colorScheme.secondary,
                ),
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
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: CustomScrollView(
            slivers: [
              // Collapsible App Bar
              SliverAppBar(
                centerTitle: true,
                expandedHeight: Responsive.isMobile(context) ? 320 : null,
                pinned: true,
                backgroundColor: Theme.of(context).colorScheme.primary,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black26,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      color: Theme.of(context).colorScheme.secondary,
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
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          herb.nameEn,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: rs.appBarTitleFont,
                            color: Theme.of(context).colorScheme.secondary,
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
                              if (herb.images.isNotEmpty)
                                PageView.builder(
                                  controller: _pageController,
                                  onPageChanged: (index) {
                                    setState(() {
                                      _currentImageIndex = index;
                                    });
                                  },
                                  itemCount: herb.images.length,
                                  itemBuilder: (context, index) {
                                    return Hero(
                                      tag:
                                          index == 0
                                              ? 'herb-image-${herb.nameEn}'
                                              : 'herb-image-${herb.nameEn}-$index',
                                      child: Image.network(
                                        herb.images[index].imageUrl,
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
                                      ),
                                    );
                                  },
                                )
                              else
                                Container(
                                  color: Colors.grey.withValues(alpha: 0.3),
                                  child: Icon(
                                    Icons.spa,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 50,
                                  ),
                                ),
                              // Gradient overlay
                              IgnorePointer(
                                child: Container(
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
                              ),
                              // Image Count Indicator
                              if (herb.images.length > 1)
                                Positioned(
                                  bottom: 60,
                                  right: 16,
                                  child: IgnorePointer(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black45,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${_currentImageIndex + 1} / ${herb.images.length}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: rs.captionFont,
                                        ),
                                      ),
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
                                Column(
                                  children: [
                                    Hero(
                                      tag: 'herb-image-${herb.nameEn}',
                                      child: Container(
                                        height: 350,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
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
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          child:
                                              herb.images.isNotEmpty
                                                  ? Image.network(
                                                    herb
                                                        .images[_currentImageIndex]
                                                        .imageUrl,
                                                    fit: BoxFit.cover,
                                                  )
                                                  : Container(
                                                    color: Colors.grey
                                                        .withValues(alpha: 0.3),
                                                    child: const Icon(
                                                      Icons.spa,
                                                      size: 60,
                                                    ),
                                                  ),
                                        ),
                                      ),
                                    ),
                                    if (herb.images.length > 1) ...[
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        height: 60,
                                        child: ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: herb.images.length,
                                          separatorBuilder:
                                              (_, __) =>
                                                  const SizedBox(width: 8),
                                          itemBuilder: (context, index) {
                                            final isSelected =
                                                _currentImageIndex == index;
                                            return GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _currentImageIndex = index;
                                                });
                                              },
                                              child: Container(
                                                width: 60,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color:
                                                        isSelected
                                                            ? Theme.of(context)
                                                                .colorScheme
                                                                .primary
                                                            : Colors
                                                                .transparent,
                                                    width: 2,
                                                  ),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  child: Image.network(
                                                    herb.images[index].imageUrl,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 24),
                              ],

                              // Category & Scientific Name Chips
                              _buildNamesSection(herb, rs),
                              const SizedBox(height: 24),

                              // Description Section
                              if (herb.description != null &&
                                  herb.description!.isNotEmpty)
                                _buildSectionCard(
                                  icon: Icons.info_outline_rounded,
                                  title: "About this Herb",
                                  content: Text(
                                    herb.description!,
                                    style: TextStyle(
                                      fontSize: rs.bodyFont,
                                      height: 1.6, // Better reading height
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurface.withValues(alpha: 0.8),
                                    ),
                                  ),
                                  rs: rs,
                                ),
                              const SizedBox(height: 32),

                              // Treatable Conditions Section
                              FutureBuilder<List<TreatmentModel>>(
                                future: _treatmentsFuture,
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    return const SizedBox.shrink();
                                  }

                                  final treatments = snapshot.data!;
                                  final uniqueConditions =
                                      treatments
                                          .map((t) => t.condition)
                                          .where((c) => c != null)
                                          .toSet()
                                          .toList();

                                  if (uniqueConditions.isEmpty) {
                                    return const SizedBox.shrink();
                                  }

                                  return Column(
                                    children: [
                                      _buildSectionCard(
                                        icon: Icons.medical_services_rounded, // Rounded icon
                                        title: "Treatable Conditions",
                                        content: Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children:
                                              uniqueConditions.map((condition) {
                                                return _ConditionBadge(
                                                  name: condition!.name,
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (context) =>
                                                                TreatmentsList(
                                                                  initialConditionId:
                                                                      condition
                                                                          .id,
                                                                ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              }).toList(),
                                        ),
                                        rs: rs,
                                        accentColor:
                                            Theme.of(
                                              context,
                                            ).colorScheme.secondary,
                                      ),
                                      const SizedBox(height: 100), // Bottom padding
                                    ],
                                  );
                                },
                              ),
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

  Widget _buildNamesSection(HerbModel herb, ResponsiveSize rs) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
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
                    fontSize: rs.labelFont,
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
              color: Theme.of(context).colorScheme.primary,
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
                      fontSize: rs.labelFont,
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
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.translate, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    "Ndebele: ${herb.nameNd!}",
                    style: TextStyle(
                      fontSize: rs.labelFont,
                      color: Colors.white,
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
    final color = accentColor ?? Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(20), // More rounded
        boxShadow: [
          BoxShadow(
            blurRadius: 15, // Softer shadow
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
                  fontWeight: FontWeight.w800, // Extra bold for headers
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
}

class _ConditionBadge extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const _ConditionBadge({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.teal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.teal.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.healing_rounded,
                size: 16,
                color: Colors.teal,
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
