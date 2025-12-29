import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zim_herbs_repo/features/treatments/data/treatment_models.dart';
import 'package:zim_herbs_repo/features/treatments/presentation/treatment_details.dart';
import 'package:zim_herbs_repo/utils/enums.dart';
import 'package:zim_herbs_repo/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/core/presentation/widgets/zimbabwe_widgets.dart';

class DesktopTreatmentList extends StatefulWidget {
  final List<TreatmentModel> treatments;
  final ResponsiveSize rs;

  const DesktopTreatmentList({
    super.key,
    required this.treatments,
    required this.rs,
  });

  @override
  State<DesktopTreatmentList> createState() => _DesktopTreatmentListState();
}

class _DesktopTreatmentListState extends State<DesktopTreatmentList> {
  int? hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.all(widget.rs.defaultPadding),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 320,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.1,
      ),
      itemCount: widget.treatments.length,
      itemBuilder: (context, index) {
        final treatment = widget.treatments[index];
        final isHovered = hoveredIndex == index;

        return MouseRegion(
          onEnter: (_) => setState(() => hoveredIndex = index),
          onExit: (_) => setState(() => hoveredIndex = null),
          child: AnimatedScale(
            scale: isHovered ? 1.03 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            TreatmentDetailsPage(treatmentId: treatment.id),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Card(
                color: Theme.of(context).colorScheme.primary,
                elevation: isHovered ? 8 : 4,
                shadowColor: const Color(0xFFB8860B).withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: ZimbabweWorkBackground(
                  patternColor: Colors.white.withValues(alpha: 0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (treatment.condition != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFD4AF37,
                                    ).withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  treatment.condition!.name.toUpperCase(),
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            if (treatment.condition != null)
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: SvgPicture.asset(
                                  getBodySystemSvg(
                                    treatment.condition!.bodySystem,
                                  ),
                                  width: 22,
                                  height: 22,
                                  colorFilter: ColorFilter.mode(
                                    Theme.of(context).colorScheme.secondary,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Treatment Name
                        Expanded(
                          child: Text(
                            treatment.name,
                            style: GoogleFonts.philosopher(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              color: Theme.of(context).colorScheme.onPrimary,
                              height: 1.1,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const SizedBox(height: 12),
                        Divider(
                          color: Colors.white.withValues(alpha: 0.15),
                          thickness: 1,
                        ),
                        const SizedBox(height: 12),

                        // Metadata Footer
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${treatment.treatmentHerbs.length} Healing Herbs',
                              style: GoogleFonts.inter(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimary.withValues(alpha: 0.7),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Theme.of(
                                context,
                              ).colorScheme.secondary.withValues(alpha: 0.8),
                              size: 18,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
