import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zim_herbs_repo/features/repository/conditions/data/datasources/condition_remote_datasource.dart';
import 'package:zim_herbs_repo/features/repository/conditions/data/repositories/condition_repository_impl.dart';
import 'package:zim_herbs_repo/features/repository/conditions/domain/entities/condition.dart';
import 'package:zim_herbs_repo/features/repository/conditions/presentation/cubit/condition_detail_cubit.dart';
import 'package:zim_herbs_repo/core/theme/spacing.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
import 'package:zim_herbs_repo/core/utils/responsive.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';

class ConditionDetailsPage extends StatefulWidget {
  final String conditionId;

  const ConditionDetailsPage({super.key, required this.conditionId});

  @override
  State<ConditionDetailsPage> createState() => _ConditionDetailsPageState();
}

class _ConditionDetailsPageState extends State<ConditionDetailsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);

    return BlocProvider(
      create: (context) {
        final client = Supabase.instance.client;
        final dataSource = ConditionRemoteDataSource(client);
        final repository = ConditionRepositoryImpl(dataSource);
        return ConditionDetailCubit(repository)
          ..loadCondition(widget.conditionId);
      },
      child: BlocBuilder<ConditionDetailCubit, ConditionDetailState>(
        builder: (context, state) {
          if (state is ConditionDetailLoading ||
              state is ConditionDetailInitial) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (state is ConditionDetailError) {
            return Scaffold(
              appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: Center(child: Text(state.message)),
            );
          }

          if (state is ConditionDetailLoaded) {
            final condition = state.condition;
            final systemColor = getBodySystemColor(condition.bodySystem);

            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    centerTitle: true,
                    expandedHeight: Responsive.isMobile(context) ? 200 : 250,
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
                              condition.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: rs.appBarTitleFont,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      background: Container(
                        color: Theme.of(context).colorScheme.primary,
                        child: Center(
                          child: CircleAvatar(
                            radius: rs.icon * 1.5,
                            backgroundColor: systemColor.withValues(alpha: 0.15),
                            child: SvgPicture.asset(
                              getBodySystemSvg(condition.bodySystem),
                              width: rs.icon * 1.8,
                              height: rs.icon * 1.8,
                              colorFilter: ColorFilter.mode(
                                systemColor,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
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
                                  _buildHeaderChips(condition, rs),
                                  const SizedBox(height: 24),
                                  if (condition.description != null &&
                                      condition.description!.isNotEmpty) ...[
                                    _buildSectionCard(
                                      icon: Icons.info_outline_rounded,
                                      title: 'Description',
                                      content: Text(
                                        condition.description!,
                                        style: TextStyle(
                                          fontSize: rs.bodyFont,
                                          height: 1.6,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.8),
                                        ),
                                      ),
                                      rs: rs,
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                  if (condition.symptoms.isNotEmpty) ...[
                                    _buildSectionCard(
                                      icon: Icons.warning_amber_rounded,
                                      title: 'Common Symptoms',
                                      content: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children:
                                            condition.symptoms
                                                .map(
                                                  (s) => _buildBulletPoint(
                                                    s,
                                                    rs,
                                                    context,
                                                  ),
                                                )
                                                .toList(),
                                      ),
                                      rs: rs,
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                  if (condition.precautions.isNotEmpty) ...[
                                    _buildSectionCard(
                                      icon: Icons.health_and_safety_outlined,
                                      title: 'Precautions & Care',
                                      content: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children:
                                            condition.precautions
                                                .map(
                                                  (p) => _buildBulletPoint(
                                                    p,
                                                    rs,
                                                    context,
                                                  ),
                                                )
                                                .toList(),
                                      ),
                                      rs: rs,
                                    ),
                                    const SizedBox(height: 20),
                                  ],
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
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHeaderChips(Condition condition, ResponsiveSize rs) {
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
              Icon(
                Icons.category_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                bodySystemLabel(condition.bodySystem),
                style: TextStyle(
                  fontSize: rs.labelFont,
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.w500,
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
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(rs.defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(rs.borderRadius),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: rs.titleFont * 1.2,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: rs.titleFont,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
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

  Widget _buildBulletPoint(
    String text,
    ResponsiveSize rs,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: rs.bodyFont,
                height: 1.4,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
