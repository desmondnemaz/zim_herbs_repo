import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/core/components/public_remedy_card.dart';
import 'package:zim_herbs_repo/core/components/remedy_review_card.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/features/repository/remedies/domain/entities/remedy.dart';
import 'package:zim_herbs_repo/features/repository/remedies/presentation/cubit/remedy_cubit.dart';
import 'package:zim_herbs_repo/features/repository/remedies/presentation/pages/remedy_details.dart';

class MobileRemedyList extends StatelessWidget {
  final List<Remedy> remedies;
  final ResponsiveSize rs;
  final bool isSelectionMode;
  final Set<String> selectedRemedyIds;
  final ValueChanged<Remedy>? onToggleSelect;
  final ValueChanged<Remedy>? onLongPress;
  final Function(Remedy)? onToggleApproval;
  final Function(Remedy)? onReject;
  final Function(Remedy)? onEdit;
  final Function(Remedy)? onDelete;
  final bool showStatusChip;
  final String? currentUserId;
  final bool isPublicView;

  const MobileRemedyList({
    super.key,
    required this.remedies,
    required this.rs,
    this.isSelectionMode = false,
    this.selectedRemedyIds = const {},
    this.onToggleSelect,
    this.onLongPress,
    this.onToggleApproval,
    this.onReject,
    this.onEdit,
    this.onDelete,
    this.showStatusChip = true,
    this.currentUserId,
    this.isPublicView = false,
  });

  @override
  Widget build(BuildContext context) {
    if (remedies.isEmpty) {
      return const Center(child: Text('No remedies found'));
    }

    return ListView.separated(
      padding: EdgeInsets.all(rs.defaultPadding),
      itemCount: remedies.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final remedy = remedies[index];

        if (isPublicView) {
          return PublicRemedyCard(
            remedy: remedy,
            onTap: () {
              final cubit = context.read<RemedyCubit>();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider.value(
                    value: cubit,
                    child: RemedyDetailsPage(
                      remedyId: remedy.id,
                      isPublicView: isPublicView,
                    ),
                  ),
                ),
              );
            },
          );
        }

        final isSelected = selectedRemedyIds.contains(remedy.id);

        return RemedyReviewCard(
          remedy: remedy,
          actionLabel: 'View Details',
          actionIcon: Icons.visibility_outlined,
          isSelected: isSelected,
          isSelectionMode: isSelectionMode,
          currentUserId: currentUserId,
          showStatusChip: showStatusChip,
          onToggleSelect: onToggleSelect != null
              ? (_) => onToggleSelect!(remedy)
              : null,
          onLongPress: onLongPress != null
              ? () => onLongPress!(remedy)
              : null,
          onTap: () {
            if (isSelectionMode && onToggleSelect != null) {
              onToggleSelect!(remedy);
              return;
            }
            final cubit = context.read<RemedyCubit>();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BlocProvider.value(
                  value: cubit,
                  child: RemedyDetailsPage(
                      remedyId: remedy.id,
                      isPublicView: isPublicView,
                    ),
                ),
              ),
            );
          },
          onToggleApproval: onToggleApproval != null
              ? () => onToggleApproval!(remedy)
              : null,
          onReject: onReject != null
              ? () => onReject!(remedy)
              : null,
          onEdit: onEdit != null
              ? () => onEdit!(remedy)
              : null,
          onDelete: onDelete != null
              ? () => onDelete!(remedy)
              : null,
        );
      },
    );
  }
}
