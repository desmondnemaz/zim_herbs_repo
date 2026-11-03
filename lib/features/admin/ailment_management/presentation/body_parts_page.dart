import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zim_herbs_repo/core/components/app_page_header.dart';
import 'package:zim_herbs_repo/core/utils/responsive.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/features/admin/ailment_management/presentation/components/add_edit_body_part_dialog.dart';
import 'package:zim_herbs_repo/features/repository/ailments/data/datasources/ailment_remote_datasource.dart';
import 'package:zim_herbs_repo/features/repository/ailments/data/models/body_part_model.dart';

/// Full-page management screen allowing admins and moderators to view, search,
/// add, edit, and delete registered anatomical body parts.
///
/// Organizes body parts alphabetically (A-Z):
/// - Desktop/Tablet: Multi-column cards under each alphabetical letter header.
/// - Mobile: Compact ListTiles under each alphabetical letter header.
class BodyPartsPage extends StatefulWidget {
  final VoidCallback? onBack;

  const BodyPartsPage({super.key, this.onBack});

  @override
  State<BodyPartsPage> createState() => _BodyPartsPageState();
}

class _BodyPartsPageState extends State<BodyPartsPage> {
  static const Color _accentTeal = Color(0xFF106F74);
  final TextEditingController _searchController = TextEditingController();

  List<BodyPartModel> _allBodyParts = [];
  List<BodyPartModel> _filteredBodyParts = [];
  String? _selectedLetter;
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
      final dataSource = AilmentRemoteDataSource(Supabase.instance.client);
      final list = await dataSource.getAllBodyParts();
      // Sort alphabetically by English name (case-insensitive)
      list.sort(
        (a, b) => a.nameEn.trim().toLowerCase().compareTo(
              b.nameEn.trim().toLowerCase(),
            ),
      );
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

  static String _letterOf(BodyPartModel bp) {
    final trimmed = bp.nameEn.trim();
    if (trimmed.isEmpty) return '#';
    final first = trimmed[0].toUpperCase();
    return RegExp(r'^[A-Z]$').hasMatch(first) ? first : '#';
  }

  void _applySearch() {
    final query = _searchController.text.trim().toLowerCase();
    final matched = _allBodyParts.where((bp) {
      if (_selectedLetter != null && _letterOf(bp) != _selectedLetter) {
        return false;
      }
      if (query.isEmpty) return true;
      final matchesEn = bp.nameEn.toLowerCase().contains(query);
      final matchesSn = bp.nameSn?.toLowerCase().contains(query) ?? false;
      final matchesNd = bp.nameNd?.toLowerCase().contains(query) ?? false;
      final matchesCode = bp.code?.toLowerCase().contains(query) ?? false;
      final matchesDesc =
          bp.description?.toLowerCase().contains(query) ?? false;
      return matchesEn || matchesSn || matchesNd || matchesCode || matchesDesc;
    }).toList();

    matched.sort(
      (a, b) => a.nameEn.trim().toLowerCase().compareTo(
            b.nameEn.trim().toLowerCase(),
          ),
    );
    _filteredBodyParts = matched;
  }

  /// Groups sorted body parts into an ordered map of `Letter -> List<BodyPartModel>`.
  Map<String, List<BodyPartModel>> _groupByAlphabet(
    List<BodyPartModel> items,
  ) {
    final grouped = <String, List<BodyPartModel>>{};
    for (final bp in items) {
      final letter = _letterOf(bp);
      grouped.putIfAbsent(letter, () => []).add(bp);
    }
    return grouped;
  }

  /// Available letters across all loaded body parts for the A-Z filter bar.
  List<String> _availableLetters() {
    final letters = _allBodyParts.map(_letterOf).toSet().toList()..sort();
    return letters;
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
          backgroundColor: _accentTeal,
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
          'Are you sure you want to delete "${bp.nameEn}"? This may unlink it from associated ailments.',
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
        final dataSource = AilmentRemoteDataSource(Supabase.instance.client);
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
    final isDesktop = Responsive.isDesktop(context);
    final isMobile = Responsive.isMobile(context);
    final theme = Theme.of(context);
    final availableLetters = _availableLetters();
    final grouped = _groupByAlphabet(_filteredBodyParts);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: isDesktop
          ? null
          : AppPageAppBar(
              title: 'Body Parts',
              onBack: widget.onBack,
            ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Body Part',
        onPressed: () => _openAddEditDialog(),
        backgroundColor: theme.colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: theme.colorScheme.secondary,
            width: 4,
          ),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            AppPageHeader(
              title: 'Anatomical Body Parts',
              subtitle:
                  'Alphabetical directory of body parts linked to medical ailments',
              icon: Icons.accessibility_new_rounded,
              iconColor: _accentTeal,
              onBack: widget.onBack,
            ),

            // Search bar & A-Z filter strip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Showing: ${_filteredBodyParts.length} (A–Z)',
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        'Total Registered: ${_allBodyParts.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _accentTeal.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(_applySearch),
                    decoration: InputDecoration(
                      hintText:
                          'Search body parts by English, Shona, Ndebele, or code...',
                      filled: true,
                      fillColor: theme.colorScheme.onPrimary,
                      prefixIcon: const Icon(
                        Icons.search,
                        color: _accentTeal,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(_applySearch);
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (availableLetters.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _AlphabetChip(
                            label: 'All',
                            isSelected: _selectedLetter == null,
                            onTap: () {
                              setState(() {
                                _selectedLetter = null;
                                _applySearch();
                              });
                            },
                          ),
                          ...availableLetters.map(
                            (letter) => Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: _AlphabetChip(
                                label: letter,
                                isSelected: _selectedLetter == letter,
                                onTap: () {
                                  setState(() {
                                    _selectedLetter =
                                        _selectedLetter == letter
                                            ? null
                                            : letter;
                                    _applySearch();
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Body Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _filteredBodyParts.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _fetchBodyParts,
                              child: isMobile
                                  ? _buildMobileAlphabeticalListTiles(
                                      grouped,
                                      rs,
                                    )
                                  : _buildDesktopAlphabeticalCards(
                                      grouped,
                                      rs,
                                    ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // DESKTOP / TABLET: ALPHABETICAL SECTIONS WITH CARDS
  // ===========================================================================

  Widget _buildDesktopAlphabeticalCards(
    Map<String, List<BodyPartModel>> grouped,
    ResponsiveSize rs,
  ) {
    final entries = grouped.entries.toList();

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        rs.defaultPadding,
        8,
        rs.defaultPadding,
        80,
      ),
      itemCount: entries.length,
      itemBuilder: (context, sectionIndex) {
        final letter = entries[sectionIndex].key;
        final items = entries[sectionIndex].value;

        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AlphabetSectionHeader(letter: letter, count: items.length),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 380,
                  mainAxisExtent: 156,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: items.length,
                itemBuilder: (context, idx) {
                  final bp = items[idx];
                  return _DesktopBodyPartCard(
                    bodyPart: bp,
                    onEdit: () => _openAddEditDialog(bp),
                    onDelete: () => _confirmDelete(bp),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // MOBILE: ALPHABETICAL SECTIONS WITH LIST TILES
  // ===========================================================================

  Widget _buildMobileAlphabeticalListTiles(
    Map<String, List<BodyPartModel>> grouped,
    ResponsiveSize rs,
  ) {
    final entries = grouped.entries.toList();

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        rs.defaultPadding,
        8,
        rs.defaultPadding,
        80,
      ),
      itemCount: entries.length,
      itemBuilder: (context, sectionIndex) {
        final letter = entries[sectionIndex].key;
        final items = entries[sectionIndex].value;

        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AlphabetSectionHeader(letter: letter, count: items.length),
              const SizedBox(height: 8),
              Material(
                color: Colors.white,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, idx) {
                    final bp = items[idx];
                    final vernacularParts = <String>[
                      if (bp.nameSn != null && bp.nameSn!.isNotEmpty)
                        'Shona: ${bp.nameSn}',
                      if (bp.nameNd != null && bp.nameNd!.isNotEmpty)
                        'Ndebele: ${bp.nameNd}',
                    ];

                    return ListTile(
                      onTap: () => _openAddEditDialog(bp),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: _accentTeal.withValues(alpha: 0.12),
                        child: Text(
                          letter,
                          style: const TextStyle(
                            color: _accentTeal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              bp.nameEn,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          if (bp.code != null && bp.code!.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                bp.code!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF475569),
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF475569),
                              ),
                            ),
                          if (bp.description != null &&
                              bp.description!.isNotEmpty)
                            Text(
                              bp.description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFF64748B),
                              ),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 19),
                            color: _accentTeal,
                            tooltip: 'Edit',
                            onPressed: () => _openAddEditDialog(bp),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 19),
                            color: Colors.red.shade400,
                            tooltip: 'Delete',
                            onPressed: () => _confirmDelete(bp),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _fetchBodyParts,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              _searchController.text.isNotEmpty || _selectedLetter != null
                  ? 'No body parts match the current filter.'
                  : 'No body parts registered yet.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 14),
            if (_selectedLetter != null || _searchController.text.isNotEmpty)
              OutlinedButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _selectedLetter = null;
                    _applySearch();
                  });
                },
                child: const Text('Clear Filters'),
              )
            else
              FilledButton.tonalIcon(
                onPressed: () => _openAddEditDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Body Part'),
              ),
          ],
        ),
      ),
    );
  }
}

class _AlphabetChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AlphabetChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accentTeal = Color(0xFF106F74);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? accentTeal : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? accentTeal : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}

class _AlphabetSectionHeader extends StatelessWidget {
  final String letter;
  final int count;

  const _AlphabetSectionHeader({
    required this.letter,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    const accentTeal = Color(0xFF106F74);
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: accentTeal,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            letter,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$count ${count == 1 ? "body part" : "body parts"}',
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
        ),
      ],
    );
  }
}

class _DesktopBodyPartCard extends StatelessWidget {
  final BodyPartModel bodyPart;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DesktopBodyPartCard({
    required this.bodyPart,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const accentTeal = Color(0xFF106F74);
    final vernacular = <String>[
      if (bodyPart.nameSn != null && bodyPart.nameSn!.isNotEmpty)
        'Shona: ${bodyPart.nameSn}',
      if (bodyPart.nameNd != null && bodyPart.nameNd!.isNotEmpty)
        'Ndebele: ${bodyPart.nameNd}',
    ];

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: avatar + name + code + actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accentTeal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.accessibility_new_rounded,
                      color: accentTeal,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bodyPart.nameEn,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        if (bodyPart.code != null &&
                            bodyPart.code!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              bodyPart.code!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    color: accentTeal,
                    tooltip: 'Edit Body Part',
                    onPressed: onEdit,
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: Colors.red.shade400,
                    tooltip: 'Delete Body Part',
                    onPressed: onDelete,
                  ),
                ],
              ),
              const Spacer(),
              if (vernacular.isNotEmpty)
                Text(
                  vernacular.join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF334155),
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                (bodyPart.description != null &&
                        bodyPart.description!.isNotEmpty)
                    ? bodyPart.description!
                    : 'No physiological description provided.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: (bodyPart.description == null ||
                          bodyPart.description!.isEmpty)
                      ? FontStyle.italic
                      : FontStyle.normal,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
