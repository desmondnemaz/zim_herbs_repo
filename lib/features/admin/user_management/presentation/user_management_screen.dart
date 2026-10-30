import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zim_herbs_repo/core/components/app_error_view.dart';
import 'package:zim_herbs_repo/core/errors/error_handler.dart';
import 'package:zim_herbs_repo/core/errors/failure.dart';
import 'package:zim_herbs_repo/core/services/user_export_service.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  Failure? _errorFailure;
  String _searchQuery = '';
  String _selectedRoleFilter = 'all'; // 'all', 'admin', 'moderator', 'supplier'
  bool _isExporting = false;

  // Table sorting & pagination state
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  int _rowsPerPage = 10;
  int _currentPage = 0;
  bool _isTableView = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorFailure = null;
    });

    try {
      final response = await _client
          .from('user_profiles')
          .select()
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(response as List);
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() {
          _errorFailure = ErrorHandler.handle(e, stackTrace);
          _isLoading = false;
        });
      }
    }
  }

  void _sort<T>(
    Comparable<T>? Function(Map<String, dynamic> user) getField,
    int columnIndex,
    bool ascending,
  ) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _currentPage = 0;
      _users.sort((a, b) {
        final aValue = getField(a);
        final bValue = getField(b);
        if (aValue == null && bValue == null) return 0;
        if (aValue == null) return ascending ? -1 : 1;
        if (bValue == null) return ascending ? 1 : -1;
        return ascending
            ? Comparable.compare(aValue, bValue)
            : Comparable.compare(bValue, aValue);
      });
    });
  }

  Future<void> _toggleAdminRole(String userId, bool currentStatus) async {
    final newStatus = !currentStatus;
    try {
      final updateData = <String, dynamic>{'is_admin': newStatus};
      if (newStatus) {
        updateData['is_moderator'] = true;
      }
      await _client
          .from('user_profiles')
          .update(updateData)
          .eq('id', userId);

      if (mounted) {
        setState(() {
          final index = _users.indexWhere((u) => u['id'] == userId);
          if (index != -1) {
            _users[index]['is_admin'] = newStatus;
            if (newStatus) {
              _users[index]['is_moderator'] = true;
            }
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? 'User promoted to Administrator'
                  : 'Administrator role revoked',
            ),
            backgroundColor: newStatus ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e, stackTrace) {
      if (mounted) {
        showAppErrorSnackBar(
          context,
          failure: ErrorHandler.handle(e, stackTrace),
        );
      }
    }
  }

  Future<void> _toggleModeratorRole(String userId, bool currentStatus) async {
    final newStatus = !currentStatus;
    try {
      await _client
          .from('user_profiles')
          .update({'is_moderator': newStatus})
          .eq('id', userId);

      if (mounted) {
        setState(() {
          final index = _users.indexWhere((u) => u['id'] == userId);
          if (index != -1) {
            _users[index]['is_moderator'] = newStatus;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? 'User assigned Moderator privileges'
                  : 'Moderator role revoked',
            ),
            backgroundColor: newStatus ? Colors.indigo : Colors.orange,
          ),
        );
      }
    } catch (e, stackTrace) {
      if (mounted) {
        showAppErrorSnackBar(
          context,
          failure: ErrorHandler.handle(e, stackTrace),
        );
      }
    }
  }

  Future<void> _toggleSupplierRole(String userId, bool currentStatus) async {
    final newStatus = !currentStatus;
    try {
      await _client
          .from('user_profiles')
          .update({'is_supplier': newStatus})
          .eq('id', userId);

      if (mounted) {
        setState(() {
          final index = _users.indexWhere((u) => u['id'] == userId);
          if (index != -1) {
            _users[index]['is_supplier'] = newStatus;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? 'User granted Supplier privileges'
                  : 'Supplier role revoked',
            ),
            backgroundColor: newStatus ? Colors.orange : Colors.grey,
          ),
        );
      }
    } catch (e, stackTrace) {
      if (mounted) {
        showAppErrorSnackBar(
          context,
          failure: ErrorHandler.handle(e, stackTrace),
        );
      }
    }
  }

  Future<void> _updateUserRights({
    required String userId,
    required bool isAdmin,
    required bool isModerator,
    required bool isSupplier,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'is_admin': isAdmin,
        'is_moderator': isAdmin ? true : isModerator,
        'is_supplier': isSupplier,
      };

      await _client
          .from('user_profiles')
          .update(updateData)
          .eq('id', userId);

      if (mounted) {
        setState(() {
          final index = _users.indexWhere((u) => u['id'] == userId);
          if (index != -1) {
            _users[index]['is_admin'] = isAdmin;
            _users[index]['is_moderator'] = isAdmin ? true : isModerator;
            _users[index]['is_supplier'] = isSupplier;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User rights updated successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      if (mounted) {
        showAppErrorSnackBar(
          context,
          failure: ErrorHandler.handle(e, stackTrace),
        );
      }
    }
  }

  Future<void> _showManageRightsDialog(
    BuildContext context,
    Map<String, dynamic> user,
  ) async {
    final theme = Theme.of(context);
    bool isAdmin = user['is_admin'] as bool? ?? false;
    bool isModerator = user['is_moderator'] as bool? ?? false;
    bool isSupplier = user['is_supplier'] as bool? ?? false;
    final fullName = (user['full_name'] as String?)?.trim() ?? '';
    final email = user['email'] as String? ?? '';
    final userId = user['id'] as String;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.admin_panel_settings_outlined,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Manage User Rights',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          fullName.isNotEmpty ? fullName : email,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Administrator',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'Full system control, user rights, and analytics',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      activeThumbColor: theme.colorScheme.primary,
                      value: isAdmin,
                      onChanged: (val) {
                        setDialogState(() {
                          isAdmin = val;
                          if (val) isModerator = true;
                        });
                      },
                    ),
                    const Divider(height: 1, thickness: 0.5, color: Color(0xFFE2E8F0)),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Moderator',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'Review, verify, and approve/reject herbal submissions',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      activeThumbColor: Colors.indigo,
                      value: isModerator,
                      onChanged: isAdmin
                          ? null
                          : (val) {
                              setDialogState(() => isModerator = val);
                            },
                    ),
                    const Divider(height: 1, thickness: 0.5, color: Color(0xFFE2E8F0)),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Supplier / Vendor',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'Can list herbal products and process store orders',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      activeThumbColor: Colors.orange,
                      value: isSupplier,
                      onChanged: (val) {
                        setDialogState(() => isSupplier = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _updateUserRights(
                      userId: userId,
                      isAdmin: isAdmin,
                      isModerator: isModerator,
                      isSupplier: isSupplier,
                    );
                  },
                  child: const Text('Save Rights'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  Future<void> _exportPdf(List<Map<String, dynamic>> filteredUsers) async {
    if (filteredUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No users available to export.')),
      );
      return;
    }
    setState(() => _isExporting = true);
    try {
      await UserExportService.exportToPdf(
        context: context,
        users: filteredUsers,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
    } catch (e, st) {
      if (mounted) {
        showAppErrorSnackBar(context, failure: ErrorHandler.handle(e, st));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportCsv(List<Map<String, dynamic>> filteredUsers) async {
    if (filteredUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No users available to export.')),
      );
      return;
    }
    setState(() => _isExporting = true);
    try {
      await UserExportService.exportToCsv(
        context: context,
        users: filteredUsers,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User spreadsheet exported successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, st) {
      if (mounted) {
        showAppErrorSnackBar(context, failure: ErrorHandler.handle(e, st));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rs = ResponsiveSize(context);

    // Apply role filter and search query
    final filteredUsers = _users.where((user) {
      if (_selectedRoleFilter == 'admin' && user['is_admin'] != true) {
        return false;
      }
      if (_selectedRoleFilter == 'moderator' && user['is_moderator'] != true) {
        return false;
      }
      if (_selectedRoleFilter == 'supplier' && user['is_supplier'] != true) {
        return false;
      }

      final email = (user['email'] ?? '').toString().toLowerCase();
      final name = (user['full_name'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      return email.contains(q) || name.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F2),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(rs.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header & Actions ───────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User Management',
                          style: TextStyle(
                            fontSize: rs.titleFont * 1.2,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage client accounts, roles, and administrative privileges for Zim Herbs',
                          style: TextStyle(
                            fontSize: rs.bodyFont * 0.9,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // View Mode Toggle (Table / Card)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(9),
                              ),
                              onTap: () {
                                if (!_isTableView) {
                                  setState(() => _isTableView = true);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _isTableView
                                      ? theme.colorScheme.primary.withValues(alpha: 0.15)
                                      : Colors.transparent,
                                  borderRadius: const BorderRadius.horizontal(
                                    left: Radius.circular(9),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.table_chart_outlined,
                                      size: 16,
                                      color: _isTableView
                                          ? theme.colorScheme.primary
                                          : Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Table',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: _isTableView
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: _isTableView
                                            ? theme.colorScheme.primary
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 20,
                              color: Colors.grey.shade300,
                            ),
                            InkWell(
                              borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(9),
                              ),
                              onTap: () {
                                if (_isTableView) {
                                  setState(() => _isTableView = false);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: !_isTableView
                                      ? theme.colorScheme.primary.withValues(alpha: 0.15)
                                      : Colors.transparent,
                                  borderRadius: const BorderRadius.horizontal(
                                    right: Radius.circular(9),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.view_agenda_outlined,
                                      size: 16,
                                      color: !_isTableView
                                          ? theme.colorScheme.primary
                                          : Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Cards',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: !_isTableView
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: !_isTableView
                                            ? theme.colorScheme.primary
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Export Menu
                      PopupMenuButton<String>(
                        tooltip: 'Export users',
                        icon: _isExporting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.download_rounded),
                        onSelected: (val) {
                          if (val == 'pdf') {
                            _exportPdf(filteredUsers);
                          } else if (val == 'excel') {
                            _exportCsv(filteredUsers);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'pdf',
                            child: Row(
                              children: [
                                Icon(Icons.picture_as_pdf,
                                    color: Colors.red, size: 20),
                                SizedBox(width: 10),
                                Text('Export PDF Report'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'excel',
                            child: Row(
                              children: [
                                Icon(Icons.table_view_rounded,
                                    color: Colors.green, size: 20),
                                SizedBox(width: 10),
                                Text('Export Excel (CSV)'),
                              ],
                            ),
                          ),
                        ],
                      ),

                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh Users',
                        onPressed: _loadUsers,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ─── Search & Role Filters ───────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by name or email...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () =>
                                    setState(() => _searchQuery = ''),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(rs.borderRadius),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(rs.borderRadius),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (val) => setState(() {
                        _searchQuery = val;
                        _currentPage = 0;
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All Users', 'all', _users.length),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Administrators',
                      'admin',
                      _users.where((u) => u['is_admin'] == true).length,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Moderators',
                      'moderator',
                      _users.where((u) => u['is_moderator'] == true).length,
                      color: Colors.indigo,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Suppliers',
                      'supplier',
                      _users.where((u) => u['is_supplier'] == true).length,
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ─── Content Body (Table or Cards) ───────────────────────────────
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorFailure != null
                        ? AppErrorView(
                            failure: _errorFailure,
                            onRetry: _loadUsers,
                          )
                        : filteredUsers.isEmpty
                            ? Center(
                                child: Text(
                                  _searchQuery.isEmpty
                                      ? 'No registered users found'
                                      : 'No users matching "$_searchQuery"',
                                  style: TextStyle(fontSize: rs.bodyFont),
                                ),
                              )
                            : AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                switchInCurve: Curves.easeInOut,
                                switchOutCurve: Curves.easeInOut,
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                },
                                child: _isTableView
                                    ? KeyedSubtree(
                                        key: const ValueKey('table_view'),
                                        child: _buildDataTable(
                                            context, filteredUsers),
                                      )
                                    : KeyedSubtree(
                                        key: const ValueKey('card_view'),
                                        child: _buildCardList(
                                            context, filteredUsers),
                                      ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    int count, {
    Color? color,
  }) {
    final isSelected = _selectedRoleFilter == value;
    final theme = Theme.of(context);
    final activeColor = color ?? theme.colorScheme.primary;

    return FilterChip(
      selected: isSelected,
      label: Text('$label ($count)'),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : Colors.grey.shade800,
      ),
      backgroundColor: Colors.white,
      selectedColor: activeColor,
      side: BorderSide(
        color: isSelected ? activeColor : Colors.grey.shade300,
      ),
      checkmarkColor: Colors.white,
      onSelected: (_) => setState(() {
        _selectedRoleFilter = value;
        _currentPage = 0;
      }),
    );
  }

  // ─── Sticky Header Full-Width Table (No Row Dividing Lines) ──────────────────
  Widget _buildDataTable(
    BuildContext context,
    List<Map<String, dynamic>> users,
  ) {
    final theme = Theme.of(context);
    final totalUsers = users.length;
    final startIndex = (_currentPage * _rowsPerPage).clamp(0, totalUsers);
    final endIndex = (startIndex + _rowsPerPage).clamp(0, totalUsers);
    final pagedUsers = users.sublist(startIndex, endIndex);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 750;

          Widget header = Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
              ),
            ),
            child: Row(
              children: [
                // User Column
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: () => _sort(
                      (u) => ((u['full_name'] as String?)?.isNotEmpty == true
                              ? u['full_name']
                              : u['email'] ?? '')
                          .toString()
                          .toLowerCase(),
                      0,
                      _sortColumnIndex == 0 ? !_sortAscending : true,
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'User',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF334155),
                          ),
                        ),
                        if (_sortColumnIndex == 0) ...[
                          const SizedBox(width: 4),
                          Icon(
                            _sortAscending
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Email Column
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: () => _sort(
                      (u) => (u['email'] ?? '').toString().toLowerCase(),
                      1,
                      _sortColumnIndex == 1 ? !_sortAscending : true,
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Email',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF334155),
                          ),
                        ),
                        if (_sortColumnIndex == 1) ...[
                          const SizedBox(width: 4),
                          Icon(
                            _sortAscending
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Roles & Privileges Column
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Roles & Privileges',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),

                // Joined Date Column
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: () => _sort(
                      (u) => u['created_at'] != null
                          ? DateTime.tryParse(u['created_at'].toString())
                          : null,
                      3,
                      _sortColumnIndex == 3 ? !_sortAscending : true,
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Joined Date',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF334155),
                          ),
                        ),
                        if (_sortColumnIndex == 3) ...[
                          const SizedBox(width: 4),
                          Icon(
                            _sortAscending
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Actions Column
                const SizedBox(
                  width: 60,
                  child: Text(
                    'Actions',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          );

          Widget rows = pagedUsers.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'No users found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: false,
                  physics: const BouncingScrollPhysics(),
                  itemCount: pagedUsers.length,
                  itemBuilder: (context, index) {
                    return _buildTableRow(context, pagedUsers[index]);
                  },
                );

          Widget footer = Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(
                top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Rows per page: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    DropdownButton<int>(
                      value: _rowsPerPage,
                      underline: const SizedBox(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                      items: const [10, 25, 50, 100]
                          .map(
                            (n) => DropdownMenuItem(
                              value: n,
                              child: Text('$n'),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _rowsPerPage = val;
                            _currentPage = 0;
                          });
                        }
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      totalUsers == 0
                          ? '0 of 0'
                          : '${startIndex + 1}-$endIndex of $totalUsers',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 20),
                      tooltip: 'Previous page',
                      onPressed: _currentPage > 0
                          ? () => setState(() => _currentPage--)
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 20),
                      tooltip: 'Next page',
                      onPressed: endIndex < totalUsers
                          ? () => setState(() => _currentPage++)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          );

          if (isNarrow) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 750,
                child: Column(
                  children: [
                    header,
                    Expanded(child: rows),
                    footer,
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              header,
              Expanded(child: rows),
              footer,
            ],
          );
        },
      ),
    );
  }

  // ─── Modern Pleasing Card List Implementation ────────────────────────────────
  Widget _buildCardList(
    BuildContext context,
    List<Map<String, dynamic>> users,
  ) {
    final theme = Theme.of(context);

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: users.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = users[index];
        final isAdmin = user['is_admin'] as bool? ?? false;
        final isModerator = user['is_moderator'] as bool? ?? false;
        final isSupplier = user['is_supplier'] as bool? ?? false;
        final fullName = (user['full_name'] as String?)?.trim();
        final email = user['email'] as String? ?? 'No email';
        final avatarUrl = user['avatar_url'] as String?;

        String formattedDate = 'N/A';
        if (user['created_at'] != null) {
          try {
            final dt = DateTime.parse(user['created_at'].toString());
            formattedDate =
                '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
          } catch (_) {}
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isAdmin
                  ? theme.colorScheme.primary.withValues(alpha: 0.3)
                  : (isModerator
                      ? Colors.indigo.shade200
                      : Colors.grey.shade200),
              width: isAdmin ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar with role indicator ring
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: isAdmin
                        ? theme.colorScheme.primary
                        : (isModerator
                            ? Colors.indigo
                            : (isSupplier
                                ? Colors.orange
                                : Colors.grey.shade300)),
                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl == null || avatarUrl.isEmpty
                        ? Text(
                            (fullName?.isNotEmpty == true
                                    ? fullName![0]
                                    : email[0])
                                .toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  // Name and Email
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName != null && fullName.isNotEmpty
                              ? fullName
                              : 'Unnamed User',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Actions menu
                  _buildUserActionMenu(
                    user: user,
                    isAdmin: isAdmin,
                    isModerator: isModerator,
                    isSupplier: isSupplier,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Badges & Joined Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (isAdmin)
                        _buildBadge('ADMIN', theme.colorScheme.primary),
                      if (isModerator && !isAdmin)
                        _buildBadge('MODERATOR', Colors.indigo),
                      if (isSupplier)
                        _buildBadge('SUPPLIER', Colors.orange),
                      if (!isAdmin && !isModerator && !isSupplier)
                        _buildBadge('LEARNER', Colors.blueGrey),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, thickness: 0.5, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 8),
              // Direct "Manage Rights" quick action bar
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.admin_panel_settings_outlined,
                        size: 18),
                    label: const Text(
                      'Manage Rights',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () => _showManageRightsDialog(context, user),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildUserActionMenu({
    required Map<String, dynamic> user,
    required bool isAdmin,
    required bool isModerator,
    required bool isSupplier,
  }) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'Options',
      onSelected: (action) {
        if (action == 'manage_rights') {
          _showManageRightsDialog(context, user);
        } else if (action == 'toggle_admin') {
          _toggleAdminRole(user['id'] as String, isAdmin);
        } else if (action == 'toggle_moderator') {
          _toggleModeratorRole(user['id'] as String, isModerator);
        } else if (action == 'toggle_supplier') {
          _toggleSupplierRole(user['id'] as String, isSupplier);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'manage_rights',
          child: Row(
            children: [
              Icon(
                Icons.admin_panel_settings_outlined,
                color: Color(0xFF2E7D32),
                size: 20,
              ),
              SizedBox(width: 8),
              Text('Manage Rights...'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'toggle_admin',
          child: Row(
            children: [
              Icon(
                isAdmin ? Icons.remove_moderator : Icons.admin_panel_settings,
                color: isAdmin ? Colors.red : Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(isAdmin ? 'Revoke Admin' : 'Make Admin'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'toggle_moderator',
          child: Row(
            children: [
              Icon(
                isModerator
                    ? Icons.verified_user_outlined
                    : Icons.verified_user,
                color: isModerator ? Colors.orange : Colors.indigo,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(isModerator ? 'Revoke Moderator' : 'Make Moderator'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'toggle_supplier',
          child: Row(
            children: [
              Icon(
                isSupplier
                    ? Icons.storefront_outlined
                    : Icons.storefront,
                color: isSupplier ? Colors.grey : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(isSupplier ? 'Revoke Supplier' : 'Make Supplier'),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildTableRow(BuildContext context, Map<String, dynamic> user) {
    final theme = Theme.of(context);
    final isAdmin = user['is_admin'] as bool? ?? false;
    final isModerator = user['is_moderator'] as bool? ?? false;
    final isSupplier = user['is_supplier'] as bool? ?? false;
    final fullName = (user['full_name'] as String?)?.trim();
    final email = user['email'] as String? ?? 'No email';
    final avatarUrl = user['avatar_url'] as String?;

    String formattedDate = 'N/A';
    if (user['created_at'] != null) {
      try {
        final dt = DateTime.parse(user['created_at'].toString());
        formattedDate =
            '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      child: Row(
        children: [
          // User + Avatar
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: isAdmin
                      ? theme.colorScheme.primary
                      : (isModerator
                          ? Colors.indigo
                          : (isSupplier
                              ? Colors.orange
                              : const Color(0xFFE2E8F0))),
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? Text(
                          (fullName?.isNotEmpty == true
                                  ? fullName![0]
                                  : email[0])
                              .toUpperCase(),
                          style: TextStyle(
                            color: (isAdmin || isModerator || isSupplier)
                                ? Colors.white
                                : const Color(0xFF475569),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    fullName?.isNotEmpty == true ? fullName! : 'Unnamed User',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Email
          Expanded(
            flex: 3,
            child: Text(
              email,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ),

          // Roles & Privileges
          Expanded(
            flex: 2,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                if (isAdmin)
                  _chip('ADMIN', theme.colorScheme.primary)
                else if (isModerator)
                  _chip('MODERATOR', Colors.indigo),
                if (isSupplier) _chip('SUPPLIER', Colors.orange),
                if (!isAdmin && !isModerator && !isSupplier)
                  _chip('LEARNER', Colors.blueGrey),
              ],
            ),
          ),

          // Joined Date
          Expanded(
            flex: 2,
            child: Text(
              formattedDate,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),

          // Actions
          SizedBox(
            width: 60,
            child: Center(
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                tooltip: 'User options',
                onSelected: (action) {
                  if (action == 'manage_rights') {
                    _showManageRightsDialog(context, user);
                  } else if (action == 'toggle_admin') {
                    _toggleAdminRole(user['id'] as String, isAdmin);
                  } else if (action == 'toggle_moderator') {
                    _toggleModeratorRole(user['id'] as String, isModerator);
                  } else if (action == 'toggle_supplier') {
                    _toggleSupplierRole(user['id'] as String, isSupplier);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'manage_rights',
                    child: Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings_outlined,
                          color: Color(0xFF2E7D32),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text('Manage Rights...'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'toggle_admin',
                    child: Row(
                      children: [
                        Icon(
                          isAdmin
                              ? Icons.remove_moderator
                              : Icons.admin_panel_settings,
                          color: isAdmin ? Colors.red : Colors.green,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(isAdmin ? 'Revoke Admin' : 'Make Admin'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle_moderator',
                    child: Row(
                      children: [
                        Icon(
                          isModerator
                              ? Icons.verified_user_outlined
                              : Icons.verified_user,
                          color: isModerator ? Colors.orange : Colors.indigo,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(isModerator ? 'Revoke Moderator' : 'Make Moderator'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle_supplier',
                    child: Row(
                      children: [
                        Icon(
                          isSupplier
                              ? Icons.storefront_outlined
                              : Icons.storefront,
                          color: isSupplier ? Colors.grey : Colors.orange,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(isSupplier ? 'Revoke Supplier' : 'Make Supplier'),
                      ],
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

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
