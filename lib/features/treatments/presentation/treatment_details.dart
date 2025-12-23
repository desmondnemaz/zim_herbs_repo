import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/features/treatments/data/treatment_models.dart';
import 'package:zim_herbs_repo/features/treatments/data/treatment_repository.dart';
import 'package:zim_herbs_repo/theme/spacing.dart';
import 'package:zim_herbs_repo/utils/responsive.dart';
import 'package:zim_herbs_repo/utils/responsive_sizes.dart';

class TreatmentDetailsPage extends StatefulWidget {
  final String treatmentId;

  const TreatmentDetailsPage({super.key, required this.treatmentId});

  @override
  State<TreatmentDetailsPage> createState() => _TreatmentDetailsPageState();
}

class _TreatmentDetailsPageState extends State<TreatmentDetailsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TreatmentRepository _repository = TreatmentRepository();
  late Future<TreatmentModel?> _treatmentFuture;

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
    _treatmentFuture = _repository.getTreatmentById(widget.treatmentId);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);

    return FutureBuilder<TreatmentModel?>(
      future: _treatmentFuture,
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
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Center(
              child: Text(
                snapshot.hasError
                    ? 'Error: ${snapshot.error}'
                    : 'Treatment not found',
              ),
            ),
          );
        }

        final treatment = snapshot.data!;

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
                  title: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        treatment.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: rs.appBarTitleFont,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                  ),
                  background: Container(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    child: Center(
                      child: Opacity(
                        opacity: 0.2,
                        child: Icon(
                          Icons.medical_services_outlined,
                          size: 120,
                          color: Colors.white,
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
                                  : 800,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(defaultPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeaderChips(treatment, rs),
                              const SizedBox(height: 24),

                              // Herbs Section
                              if (treatment.treatmentHerbs.isNotEmpty)
                                _buildSectionCard(
                                  icon: Icons.spa_outlined,
                                  title: "Herbs & Ingredients",
                                  content: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children:
                                        treatment.treatmentHerbs
                                            .map((th) => _buildHerbItem(th, rs))
                                            .toList(),
                                  ),
                                  rs: rs,
                                  accentColor:
                                      Theme.of(context).colorScheme.primary,
                                ),

                              const SizedBox(height: 24),

                              // Preparation Section
                              _buildSectionCard(
                                icon: Icons.science_outlined,
                                title: "Preparation",
                                content: Text(
                                  treatment.preparation,
                                  style: TextStyle(
                                    fontSize: rs.bodyFont,
                                    height: 1.5,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                rs: rs,
                              ),

                              const SizedBox(height: 24),

                              // Method of Use Section
                              _buildSectionCard(
                                icon: Icons.local_hospital_outlined,
                                title: "Method of Use",
                                content: Text(
                                  treatment.methodOfUse,
                                  style: TextStyle(
                                    fontSize: rs.bodyFont,
                                    height: 1.5,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                rs: rs,
                              ),

                              const SizedBox(height: 24),

                              // Dosage Section
                              if (treatment.dosageAdults != null ||
                                  treatment.dosageInfants != null)
                                _buildSectionCard(
                                  icon: Icons.medication_outlined,
                                  title: "Dosage Information",
                                  content: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (treatment.dosageAdults != null) ...[
                                        _buildInfoRow(
                                          "Adults",
                                          treatment.dosageAdults!,
                                          rs,
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                      if (treatment.dosageInfants != null)
                                        _buildInfoRow(
                                          "Infants",
                                          treatment.dosageInfants!,
                                          rs,
                                        ),
                                    ],
                                  ),
                                  rs: rs,
                                  accentColor: Colors.blue,
                                ),

                              const SizedBox(height: 24),

                              // Frequency & Duration
                              if (treatment.frequency != null ||
                                  treatment.duration != null)
                                _buildSectionCard(
                                  icon: Icons.schedule_outlined,
                                  title: "Schedule",
                                  content: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (treatment.frequency != null) ...[
                                        _buildInfoRow(
                                          "Frequency",
                                          treatment.frequency!,
                                          rs,
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                      if (treatment.duration != null)
                                        _buildInfoRow(
                                          "Duration",
                                          treatment.duration!,
                                          rs,
                                        ),
                                    ],
                                  ),
                                  rs: rs,
                                  accentColor: Colors.teal,
                                ),

                              const SizedBox(height: 24),

                              // Precautions Section
                              if (treatment.precautions != null &&
                                  treatment.precautions!.isNotEmpty)
                                _buildSectionCard(
                                  icon: Icons.warning_amber_rounded,
                                  title: "Precautions",
                                  content: Text(
                                    treatment.precautions!,
                                    style: TextStyle(
                                      fontSize: rs.bodyFont,
                                      height: 1.5,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                    ),
                                  ),
                                  rs: rs,
                                  accentColor: Colors.orange,
                                ),

                              const SizedBox(height: 24),

                              // Side Effects Section
                              if (treatment.sideEffects != null &&
                                  treatment.sideEffects!.isNotEmpty)
                                _buildSectionCard(
                                  icon: Icons.error_outline,
                                  title: "Possible Side Effects",
                                  content: Text(
                                    treatment.sideEffects!,
                                    style: TextStyle(
                                      fontSize: rs.bodyFont,
                                      height: 1.5,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                    ),
                                  ),
                                  rs: rs,
                                  accentColor: Colors.red,
                                ),

                              const SizedBox(height: 24),

                              // Notes Section
                              if (treatment.notes != null &&
                                  treatment.notes!.isNotEmpty)
                                _buildSectionCard(
                                  icon: Icons.note_outlined,
                                  title: "Additional Notes",
                                  content: Text(
                                    treatment.notes!,
                                    style: TextStyle(
                                      fontSize: rs.bodyFont,
                                      height: 1.5,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
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

  Widget _buildHeaderChips(TreatmentModel treatment, ResponsiveSize rs) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (treatment.condition != null)
          Chip(
            avatar: const Icon(
              Icons.health_and_safety,
              size: 16,
              color: Colors.white,
            ),
            label: Text(
              treatment.condition!.name,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: rs.labelFont,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        Chip(
          avatar: const Icon(
            Icons.local_florist,
            size: 16,
            color: Colors.white,
          ),
          label: Text(
            "${treatment.treatmentHerbs.length} Herb${treatment.treatmentHerbs.length != 1 ? 's' : ''}",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: rs.labelFont,
            ),
          ),
          backgroundColor: Colors.green,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ],
    );
  }

  Widget _buildHerbItem(TreatmentHerbModel th, ResponsiveSize rs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 4,
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
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
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.spa,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  th.herb?.nameEn ?? 'Unknown Herb',
                  style: TextStyle(
                    fontSize: rs.subtitleFont,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          if (th.quantity != null ||
              th.unit != null ||
              th.preparation != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (th.quantity != null && th.unit != null)
                    Row(
                      children: [
                        Icon(
                          Icons.scale_outlined,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Quantity: ",
                          style: TextStyle(
                            fontSize: rs.bodyFont,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          "${th.quantity} ${th.unit}",
                          style: TextStyle(
                            fontSize: rs.bodyFont,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  if (th.quantity != null &&
                      th.unit != null &&
                      th.preparation != null)
                    const SizedBox(height: 8),
                  if (th.preparation != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.cut_outlined,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Preparation: ",
                          style: TextStyle(
                            fontSize: rs.bodyFont,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            th.preparation!,
                            style: TextStyle(
                              fontSize: rs.bodyFont,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSmallChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ResponsiveSize rs) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            "$label:",
            style: TextStyle(
              fontSize: rs.bodyFont,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: rs.bodyFont,
              color: Theme.of(context).colorScheme.onSurface,
            ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary,
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
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: rs.titleFont,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
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
