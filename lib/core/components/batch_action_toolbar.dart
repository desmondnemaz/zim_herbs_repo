import 'package:flutter/material.dart';

/// A reusable batch selection toolbar for managing multi-select actions
/// across lists and grids (e.g. herbs, remedies, products, conditions, moderation).
///
/// Designed to sit right above a list or grid to provide clear, accessible
/// selection controls without cluttering the top navigation bar.
class BatchActionToolbar extends StatelessWidget {
  /// Whether selection / mark mode is currently active.
  final bool isSelectionMode;

  /// The total number of items or summary count (e.g. 25).
  final int totalCount;

  /// The label for items shown in normal mode (e.g. 'herbs', 'remedies', 'items').
  final String itemLabel;

  /// Number of currently selected / marked items.
  final int selectedCount;

  /// Whether all visible items are currently selected.
  final bool isAllSelected;

  /// Callback to enter selection mode when the user taps the mark/select toggle.
  final VoidCallback onEnterSelectionMode;

  /// Callback to exit selection mode when the user cancels.
  final VoidCallback onCancelSelection;

  /// Callback to toggle select all / deselect all.
  final VoidCallback? onToggleSelectAll;

  /// Primary delete action callback when items are marked.
  final VoidCallback? onDeleteSelected;

  /// Custom label for the mark toggle button (defaults to 'Mark / Select').
  final String markButtonText;

  /// Optional custom leading widget in normal mode.
  final Widget? customLeading;

  /// Optional additional action buttons when in selection mode (e.g. Verify, Export, Move).
  final List<Widget>? additionalSelectionActions;

  /// Optional padding around the toolbar.
  final EdgeInsetsGeometry? padding;

  const BatchActionToolbar({
    super.key,
    required this.isSelectionMode,
    required this.totalCount,
    this.itemLabel = 'items',
    required this.selectedCount,
    this.isAllSelected = false,
    required this.onEnterSelectionMode,
    required this.onCancelSelection,
    this.onToggleSelectAll,
    this.onDeleteSelected,
    this.markButtonText = 'Mark / Select',
    this.customLeading,
    this.additionalSelectionActions,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isSelectionMode) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              tooltip: 'Cancel selection',
              onPressed: onCancelSelection,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
            Text(
              '$selectedCount marked',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            if (onToggleSelectAll != null && totalCount > 0)
              TextButton.icon(
                onPressed: onToggleSelectAll,
                icon: Icon(
                  isAllSelected ? Icons.deselect : Icons.select_all,
                  size: 18,
                ),
                label: Text(
                  isAllSelected ? 'Deselect All' : 'Select All',
                  style: const TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            if (additionalSelectionActions != null) ...[
              const SizedBox(width: 4),
              ...additionalSelectionActions!,
            ],
            if (onDeleteSelected != null) ...[
              const SizedBox(width: 6),
              ElevatedButton.icon(
                onPressed: selectedCount == 0 ? null : onDeleteSelected,
                icon: const Icon(Icons.delete, size: 16),
                label: Text(
                  selectedCount > 0
                      ? 'Delete ($selectedCount)'
                      : 'Delete',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          customLeading ??
              Text(
                'Total: $totalCount $itemLabel',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary.withValues(alpha: 0.75),
                ),
              ),
          InkWell(
            onTap: onEnterSelectionMode,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.checklist_rtl_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    markButtonText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
