import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:zim_herbs_repo/features/repository/remedies/domain/entities/remedy.dart';
import 'package:zim_herbs_repo/features/repository/remedies/presentation/cubit/remedy_cubit.dart';
import 'package:zim_herbs_repo/features/repository/remedies/presentation/pages/remedy_details.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';

class DesktopRemedyList extends StatefulWidget {
  final List<Remedy> remedies;
  final ResponsiveSize rs;

  const DesktopRemedyList({
    super.key,
    required this.remedies,
    required this.rs,
  });

  @override
  State<DesktopRemedyList> createState() => _DesktopRemedyListState();
}

class _DesktopRemedyListState extends State<DesktopRemedyList> {
  int? hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.all(widget.rs.defaultPadding),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 340,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.05,
      ),
      itemCount: widget.remedies.length,
      itemBuilder: (context, index) {
        final remedy = widget.remedies[index];
        final isHovered = hoveredIndex == index;

        return MouseRegion(
          onEnter: (_) => setState(() => hoveredIndex = index),
          onExit: (_) => setState(() => hoveredIndex = null),
          child: AnimatedScale(
            scale: isHovered ? 1.02 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Card(
              color: Theme.of(context).colorScheme.primary,
              elevation: isHovered ? 8 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: remedy.isApproved
                      ? const Color(0xFFD4AF37).withValues(alpha: 0.4)
                      : Colors.amber.withValues(alpha: 0.7),
                  width: remedy.isApproved ? 1 : 2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  final cubit = context.read<RemedyCubit>();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlocProvider.value(
                        value: cubit,
                        child: RemedyDetailsPage(remedyId: remedy.id),
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (remedy.conditionName != null)
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFD4AF37)
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  remedy.conditionName!.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),

                          // Moderation Badge & Action Menu
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: remedy.isApproved
                                      ? Colors.green.withValues(alpha: 0.2)
                                      : Colors.amber.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: remedy.isApproved
                                        ? Colors.green
                                        : Colors.amber,
                                  ),
                                ),
                                child: Text(
                                  remedy.isApproved ? 'LIVE' : 'PENDING',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: remedy.isApproved
                                        ? Colors.greenAccent
                                        : Colors.amber,
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.more_vert,
                                    size: 18, color: Colors.white70),
                                onSelected: (action) {
                                  if (action == 'toggle_approval') {
                                    context.read<RemedyCubit>().approveRemedy(
                                          remedy.id,
                                          approved: !remedy.isApproved,
                                        );
                                  } else if (action == 'delete') {
                                    context
                                        .read<RemedyCubit>()
                                        .deleteRemedy(remedy.id);
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'toggle_approval',
                                    child: Row(
                                      children: [
                                        Icon(
                                          remedy.isApproved
                                              ? Icons.close
                                              : Icons.check_circle_outline,
                                          color: remedy.isApproved
                                              ? Colors.amber
                                              : Colors.green,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(remedy.isApproved
                                            ? 'Unapprove'
                                            : 'Approve for HerbCircle'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline,
                                            color: Colors.red, size: 18),
                                        SizedBox(width: 8),
                                        Text('Delete',
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Remedy Name
                      Expanded(
                        child: Text(
                          remedy.displayName,
                          style: GoogleFonts.philosopher(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Theme.of(context).colorScheme.onPrimary,
                            height: 1.15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(height: 10),
                      Divider(
                        color: Colors.white.withValues(alpha: 0.15),
                        thickness: 1,
                      ),
                      const SizedBox(height: 8),

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
                            '${remedy.remedyHerbs.length} Healing Herbs',
                            style: GoogleFonts.inter(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimary
                                  .withValues(alpha: 0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          if (remedy.conditionBodySystem != null)
                            SvgPicture.asset(
                              getBodySystemSvg(remedy.conditionBodySystem!),
                              width: 18,
                              height: 18,
                              colorFilter: ColorFilter.mode(
                                Theme.of(context).colorScheme.secondary,
                                BlendMode.srcIn,
                              ),
                            ),
                        ],
                      ),
                    ],
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
