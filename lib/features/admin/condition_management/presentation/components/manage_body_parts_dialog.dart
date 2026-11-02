import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/features/repository/conditions/data/datasources/condition_remote_datasource.dart';
import 'package:zim_herbs_repo/features/repository/conditions/data/models/body_part_model.dart';
import 'add_edit_body_part_dialog.dart';

/// Comprehensive management dialog allowing admins to view, search,
/// add, and edit registered anatomical body parts.
class ManageBodyPartsDialog extends StatefulWidget {
  const ManageBodyPartsDialog({super.key});

  @override
  State<ManageBodyPartsDialog> createState() => _ManageBodyPartsDialogState();
}

class _ManageBodyPartsDialogState extends State<ManageBodyPartsDialog> {
  static const Color _conditionBlue = Color(0xFF106F74);
  final TextEditingController _searchController = TextEditingController();

  List<BodyPartModel> _allBodyParts = [];
  List<BodyPartModel> _filteredBodyParts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchBodyParts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchBodyParts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dataSource = ConditionRemoteDataSource(Supabase.instance.client);
      final list = await dataSource.getAllBodyParts();
      if (mounted) {
        setState(() {
          _allBodyParts = list;
          _isLoading = false;
          _applySearch();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _applySearch() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      _filteredBodyParts = List.from(_allBodyParts);
    } else {
      _filteredBodyParts = _allBodyParts.where((bp) {
        final matchesEn = bp.nameEn.toLowerCase().contains(query);
        final matchesSn = bp.nameSn?.toLowerCase().contains(query) ?? false;
        final matchesNd = bp.nameNd?.toLowerCase().contains(query) ?? false;
        final matchesCode = bp.code?.toLowerCase().contains(query) ?? false;
        return matchesEn || matchesSn || matchesNd || matchesCode;
      }).toList();
    }
  }

  Future<void> _openAddEditDialog([BodyPartModel? bodyPart]) async {
    final result = await showDialog<BodyPartModel>(
      context: context,
      builder: (_) => AddEditBodyPartDialog(bodyPart: bodyPart),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            bodyPart == null
                ? 'Added "${result.nameEn}" successfully'
                : 'Updated "${result.nameEn}" successfully',
          ),
          backgroundColor: _conditionBlue,
        ),
      );
      _fetchBodyParts();
    }
  }

  Future<void> _confirmDelete(BodyPartModel bp) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Body Part'),
        content: Text(
          'Are you sure you want to delete "${bp.nameEn}"? This may unlink it from associated conditions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final dataSource = ConditionRemoteDataSource(Supabase.instance.client);
        await dataSource.deleteBodyPart(bp.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleted "${bp.nameEn}"')),
          );
          _fetchBodyParts();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 680,
          maxHeight: 650,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _conditionBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.accessibility_new_rounded,
                      color: _conditionBlue,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Anatomical Body Parts',
                          style: TextStyle(
                            fontSize: rs.titleFont * 1.15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'View, manage, and register body parts linked to medical conditions',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search & Add Bar
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(_applySearch),
                      decoration: InputDecoration(
                        hintText: 'Search by English, Shona, Ndebele, or code...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(_applySearch);
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: () => _openAddEditDialog(),
                    style: FilledButton.styleFrom(
                      backgroundColor: _conditionBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Body Part'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Count pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_filteredBodyParts.length} ${_filteredBodyParts.length == 1 ? "body part" : "body parts"} registered',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (_isLoading)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const Divider(height: 16),

              // List of Body Parts
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 36, color: Colors.red),
                                const SizedBox(height: 8),
                                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                                const SizedBox(height: 8),
                                OutlinedButton(
                                  onPressed: _fetchBodyParts,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : _filteredBodyParts.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off_rounded,
                                      size: 48,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      _searchController.text.isNotEmpty
                                          ? 'No body parts match "${_searchController.text}"'
                                          : 'No body parts found in database.',
                                      style: TextStyle(color: Colors.grey.shade600),
                                    ),
                                    const SizedBox(height: 12),
                                    FilledButton.tonalIcon(
                                      onPressed: () => _openAddEditDialog(),
                                      icon: const Icon(Icons.add, size: 18),
                                      label: const Text('Add First Body Part'),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                itemCount: _filteredBodyParts.length,
                                separatorBuilder: (_, _) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final bp = _filteredBodyParts[index];
                                  final vernacularParts = <String>[
                                    if (bp.nameSn != null && bp.nameSn!.isNotEmpty) 'Shona: ${bp.nameSn}',
                                    if (bp.nameNd != null && bp.nameNd!.isNotEmpty) 'Ndebele: ${bp.nameNd}',
                                  ];

                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: _conditionBlue.withValues(alpha: 0.12),
                                      child: Text(
                                        bp.nameEn.isNotEmpty
                                            ? bp.nameEn[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: _conditionBlue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Text(
                                          bp.nameEn,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (bp.code != null && bp.code!.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.surfaceContainerHighest,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              bp.code!,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (vernacularParts.isNotEmpty)
                                          Text(
                                            vernacularParts.join(' • '),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                            ),
                                          ),
                                        if (bp.description != null && bp.description!.isNotEmpty)
                                          Text(
                                            bp.description!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontStyle: FontStyle.italic,
                                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, size: 20),
                                          tooltip: 'Edit',
                                          color: _conditionBlue,
                                          onPressed: () => _openAddEditDialog(bp),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 20),
                                          tooltip: 'Delete',
                                          color: Colors.red.shade400,
                                          onPressed: () => _confirmDelete(bp),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
              ),

              // Bottom Dismiss
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
