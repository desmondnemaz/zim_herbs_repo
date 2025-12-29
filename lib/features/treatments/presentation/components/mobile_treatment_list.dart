import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zim_herbs_repo/features/treatments/data/treatment_models.dart';
import 'package:zim_herbs_repo/features/treatments/presentation/treatment_details.dart';
import 'package:zim_herbs_repo/utils/enums.dart';
import 'package:zim_herbs_repo/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/core/presentation/widgets/zimbabwe_widgets.dart';

class MobileTreatmentList extends StatelessWidget {
  final List<TreatmentModel> treatments;
  final ResponsiveSize rs;

  const MobileTreatmentList({
    super.key,
    required this.treatments,
    required this.rs,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.all(rs.defaultPadding),
      itemCount: treatments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final treatment = treatments[index];
        return Card(
          color: Theme.of(context).colorScheme.primary,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: const Color(
                0xFFD4AF37,
              ).withValues(alpha: 0.3), // Gold border
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: ZimbabweWorkBackground(
            patternColor: Colors.white.withValues(alpha: 0.05),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              leading:
                  treatment.condition != null
                      ? Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: SvgPicture.asset(
                          getBodySystemSvg(treatment.condition!.bodySystem),
                          width: 24,
                          height: 24,
                          colorFilter: ColorFilter.mode(
                            Theme.of(context).colorScheme.secondary,
                            BlendMode.srcIn,
                          ),
                        ),
                      )
                      : null,
              title: Text(
                treatment.name,
                style: GoogleFonts.philosopher(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  if (treatment.condition != null)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(
                                0xFFD4AF37,
                              ).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            treatment.condition!.name.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.auto_awesome,
                          size: 12,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${treatment.treatmentHerbs.length} Herbs',
                          style: GoogleFonts.inter(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimary.withValues(alpha: 0.6),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Theme.of(
                  context,
                ).colorScheme.onPrimary.withValues(alpha: 0.4),
              ),
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
            ),
          ),
        );
      },
    );
  }
}
