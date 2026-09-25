import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:zim_herbs_repo/features/repository/remedies/domain/entities/remedy.dart';
import 'package:zim_herbs_repo/features/repository/remedies/presentation/cubit/remedy_cubit.dart';
import 'package:zim_herbs_repo/features/repository/remedies/presentation/pages/remedy_details.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';

class MobileRemedyList extends StatelessWidget {
  final List<Remedy> remedies;
  final ResponsiveSize rs;

  const MobileRemedyList({
    super.key,
    required this.remedies,
    required this.rs,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.all(rs.defaultPadding),
      itemCount: remedies.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final remedy = remedies[index];
        return Card(
          color: Theme.of(context).colorScheme.primary,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: remedy.isApproved
                  ? const Color(0xFFD4AF37).withValues(alpha: 0.3)
                  : Colors.amber.withValues(alpha: 0.7),
              width: remedy.isApproved ? 1 : 2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: remedy.conditionBodySystem != null
                ? Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: SvgPicture.asset(
                      getBodySystemSvg(remedy.conditionBodySystem!),
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.secondary,
                        BlendMode.srcIn,
                      ),
                    ),
                  )
                : null,
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    remedy.displayName,
                    style: GoogleFonts.philosopher(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: remedy.isApproved
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.amber.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: remedy.isApproved ? Colors.green : Colors.amber,
                    ),
                  ),
                  child: Text(
                    remedy.isApproved ? 'LIVE' : 'PENDING',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color:
                          remedy.isApproved ? Colors.greenAccent : Colors.amber,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (remedy.conditionName != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color:
                                const Color(0xFFD4AF37).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          remedy.conditionName!.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Icon(
                      Icons.auto_awesome,
                      size: 12,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${remedy.remedyHerbs.length} Herbs',
                      style: GoogleFonts.inter(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withValues(alpha: 0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white70),
              onSelected: (action) {
                if (action == 'toggle_approval') {
                  context.read<RemedyCubit>().approveRemedy(
                        remedy.id,
                        approved: !remedy.isApproved,
                      );
                } else if (action == 'delete') {
                  context.read<RemedyCubit>().deleteRemedy(remedy.id);
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
                        color: remedy.isApproved ? Colors.amber : Colors.green,
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
                      Icon(Icons.delete_outline, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
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
          ),
        );
      },
    );
  }
}
