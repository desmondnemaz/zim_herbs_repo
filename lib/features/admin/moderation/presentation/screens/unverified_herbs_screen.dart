import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:zim_herbs_repo/features/auth/bloc/auth_cubit.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_state.dart';
import 'package:zim_herbs_repo/core/components/app_error_view.dart';
import 'package:zim_herbs_repo/core/errors/error_handler.dart';
import 'package:zim_herbs_repo/core/errors/failure.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/features/admin/herb_management/presentation/add_edit_herb_page.dart';
import 'package:zim_herbs_repo/features/repository/herbs/data/datasources/herb_remote_datasource.dart';
import 'package:zim_herbs_repo/features/repository/herbs/data/models/herb_model.dart';
import 'package:zim_herbs_repo/core/components/app_page_app_bar.dart';

/// Dedicated View for Unverified Herbs where moderators can inspect, update, and verify herbs.
class UnverifiedHerbsScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const UnverifiedHerbsScreen({super.key, this.onBack});

  @override
  State<UnverifiedHerbsScreen> createState() => _UnverifiedHerbsScreenState();
}

class _UnverifiedHerbsScreenState extends State<UnverifiedHerbsScreen> {
  late final HerbRemoteDataSource _datasource;
  List<HerbModel> _unverifiedHerbs = [];
  bool _isLoading = true;
  Failure? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _datasource = HerbRemoteDataSource(Supabase.instance.client);
    _loadUnverifiedHerbs();
  }

  Future<void> _loadUnverifiedHerbs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _datasource.getUnverifiedHerbs();
      if (mounted) {
        setState(() {
          _unverifiedHerbs = results;
          _isLoading = false;
        });
      }
    } catch (e, st) {
      if (mounted) {
        setState(() {
          _error = ErrorHandler.handle(e, st);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyHerb(HerbModel herb) async {
    try {
      final authState = context.read<AuthCubit>().state;
      final currentUserId = authState is Authenticated
          ? authState.user.id
          : Supabase.instance.client.auth.currentUser?.id;
      await _datasource.updateHerbVerification(
        herb.id,
        true,
        verifiedBy: currentUserId,
      );
      if (mounted) {
        setState(() {
          _unverifiedHerbs.removeWhere((h) => h.id == herb.id);
        });
        showAppErrorSnackBar(
          context,
          title: 'Herb Verified',
          message: '${herb.nameEn} has been verified and published.',
          type: FailureType.validation,
        );
      }
    } catch (e, st) {
      if (mounted) {
        showAppErrorSnackBar(
          context,
          failure: ErrorHandler.handle(e, st),
        );
      }
    }
  }

  Future<void> _openEditHerb(HerbModel herb) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditHerbPage(herb: herb),
      ),
    );

    if (result == true || result != null) {
      _loadUnverifiedHerbs();
    }
  }

  Future<void> _deleteHerb(HerbModel herb) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Herb Submission'),
        content: Text(
          'Are you sure you want to permanently delete "${herb.nameEn}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _datasource.deleteHerb(herb.id);
        setState(() {
          _unverifiedHerbs.removeWhere((h) => h.id == herb.id);
        });
        if (!mounted) return;
        showAppErrorSnackBar(
          context,
          title: 'Herb Deleted',
          message: '${herb.nameEn} has been deleted.',
          type: FailureType.validation,
        );
      } catch (e, st) {
        if (mounted) {
          showAppErrorSnackBar(
            context,
            failure: ErrorHandler.handle(e, st),
          );
        }
      }
    }
  }

  void _showHerbDetails(HerbModel herb) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          image: herb.primaryImageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(herb.primaryImageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: herb.primaryImageUrl == null
                            ? Icon(Icons.local_florist,
                                size: 36, color: Colors.green.shade700)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              herb.nameEn,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.amber.shade600),
                              ),
                              child: Text(
                                'Pending Moderator Review',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (herb.nameSn != null || herb.nameNd != null) ...[
                    const Text('Indigenous Dialect Names:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (herb.nameSn != null)
                          Chip(
                            label: Text('Shona: ${herb.nameSn}'),
                            backgroundColor: Colors.green.shade50,
                          ),
                        if (herb.nameNd != null)
                          Chip(
                            label: Text('Ndebele: ${herb.nameNd}'),
                            backgroundColor: Colors.blue.shade50,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  const Text('Description:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    (herb.description != null && herb.description!.isNotEmpty)
                        ? herb.description!
                        : 'No description provided.',
                    style: TextStyle(color: Colors.grey.shade800, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  if (herb.remedies.isNotEmpty) ...[
                    Text('Associated Remedies (${herb.remedies.length}):',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    ...herb.remedies.map(
                      (r) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.healing,
                            size: 18, color: Colors.teal),
                        title: Text(r.name),
                        subtitle: r.condition != null
                            ? Text('Condition: ${r.condition!.name}')
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (herb.images.isNotEmpty) ...[
                    Text('Images (${herb.images.length}):',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 90,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: herb.images.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (ctx2, i) => ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            herb.images[i].imageUrl,
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.edit_note_rounded),
                          label: const Text('Update Herb'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _openEditHerb(herb);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.verified_rounded),
                          label: const Text('Verify Herb'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _verifyHerb(herb);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text('Reject / Delete Submission',
                        style: TextStyle(color: Colors.red)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _deleteHerb(herb);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);
    final theme = Theme.of(context);

    final filtered = _unverifiedHerbs.where((h) {
      final q = _searchQuery.toLowerCase();
      return h.nameEn.toLowerCase().contains(q) ||
          (h.nameSn?.toLowerCase().contains(q) ?? false) ||
          (h.nameNd?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Scaffold(
      appBar: AppPageAppBar(
        onBack: widget.onBack,
        titleWidget: Row(
          children: [
            const Icon(Icons.pending_actions_rounded, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Unverified Herbs',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 10),
            if (!_isLoading)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber.shade900,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_unverifiedHerbs.length} Pending',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh unverified herbs',
            onPressed: _loadUnverifiedHerbs,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: EdgeInsets.all(rs.defaultPadding),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search unverified herbs (English, Shona, Ndebele)...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? AppErrorView(
                          failure: _error,
                          onRetry: _loadUnverifiedHerbs,
                        )
                      : filtered.isEmpty
                          ? _buildEmptyView()
                          : RefreshIndicator(
                              onRefresh: _loadUnverifiedHerbs,
                              child: ListView.separated(
                                padding: EdgeInsets.all(rs.defaultPadding),
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final herb = filtered[index];
                                  return _buildHerbCard(herb, theme);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHerbCard(HerbModel herb, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.amber.shade400, width: 1.4),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showHerbDetails(herb),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Herb image
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      image: herb.primaryImageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(herb.primaryImageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: herb.primaryImageUrl == null
                        ? Icon(Icons.local_florist,
                            color: Colors.green.shade700)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                herb.nameEn,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Colors.amber.shade600),
                              ),
                              child: Text(
                                'Pending Review',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (herb.nameSn != null || herb.nameNd != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            [
                              if (herb.nameSn != null) 'SN: ${herb.nameSn}',
                              if (herb.nameNd != null) 'ND: ${herb.nameNd}',
                            ].join(' | '),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                        if (herb.description != null &&
                            herb.description!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            herb.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('Inspect'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => _showHerbDetails(herb),
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit_note_rounded, size: 18),
                    label: const Text('Update'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _openEditHerb(herb),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    icon: const Icon(Icons.verified_rounded, size: 16),
                    label: const Text('Verify Herb'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _verifyHerb(herb),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.task_alt_rounded,
                size: 64,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'All Herbs Verified!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No unverified herbs found matching "$_searchQuery".'
                  : 'There are currently no unverified herbs pending moderator review.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
