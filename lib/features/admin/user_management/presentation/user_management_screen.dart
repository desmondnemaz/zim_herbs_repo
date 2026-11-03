import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zim_herbs_repo/core/components/app_error_view.dart';
import 'package:zim_herbs_repo/core/errors/error_handler.dart';
import 'package:zim_herbs_repo/core/errors/failure.dart';
import 'package:zim_herbs_repo/core/services/user_export_service.dart';
import 'package:zim_herbs_repo/core/components/app_page_header.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/features/admin/user_management/domain/role_update_rules.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_cubit.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_state.dart';

class UserManagementScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const UserManagementScreen({super.key, this.onBack});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _currentUserId {
    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is Authenticated) {
        return authState.user.id;
      }
    } catch (_) {}
    return _client.auth.currentUser?.id;
  }

  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  Failure? _errorFailure;
  String _searchQuery = '';
  String _selectedRoleFilter =
      'all'; // 'all', 'admin', 'moderator', 'practitioner', 'supplier', 'deactivated'
  bool _isExporting = false;

  // Table sorting & pagination state
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  int _rowsPerPage = 10;
  int _currentPage = 0;
  bool _isTableView = true;

  RealtimeChannel? _usersRealtimeChannel;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _subscribeToUserRealtimeChanges();
  }

  void _subscribeToUserRealtimeChanges() {
    _usersRealtimeChannel = _client
        .channel('admin_user_profiles_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_profiles',
          callback: (payload) {
            final eventType = payload.eventType;
            final newRecord = payload.newRecord;
            final oldRecord = payload.oldRecord;

            if (!mounted) return;

            setState(() {
              if (eventType == PostgresChangeEvent.insert && newRecord.isNotEmpty) {
                final exists = _users.any((u) => u['id'] == newRecord['id']);
                if (!exists) {
                  _users.insert(0, Map<String, dynamic>.from(newRecord));
                }
              } else if (eventType == PostgresChangeEvent.update && newRecord.isNotEmpty) {
                final index = _users.indexWhere((u) => u['id'] == newRecord['id']);
                if (index != -1) {
                  _users[index] = Map<String, dynamic>.from(newRecord);
                } else {
                  _users.insert(0, Map<String, dynamic>.from(newRecord));
                }
              } else if (eventType == PostgresChangeEvent.delete && oldRecord.isNotEmpty) {
                _users.removeWhere((u) => u['id'] == oldRecord['id']);
              }
            });
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    final channel = _usersRealtimeChannel;
    _usersRealtimeChannel = null;
    if (channel != null) {
      _client.removeChannel(channel);
    }
    super.dispose();
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

  /// Writes [data] to the user's `user_profiles` row and returns the row the
  /// database actually stored.
  ///
  /// Supabase returns no error when row-level security filters out an UPDATE
  /// (0 rows affected), so `.select()` is used to confirm the write landed.
  Future<Map<String, dynamic>> _persistProfileUpdate(
    String userId,
    Map<String, dynamic> data,
  ) async {
    final rows = await _client
        .from('user_profiles')
        .update(data)
        .eq('id', userId)
        .select();
    if (rows.isEmpty) {
      throw const Failure(
        title: 'Update Not Saved',
        message:
            'The database did not accept this change. You may not have permission to modify this user.',
        type: FailureType.accessDenied,
      );
    }
    return Map<String, dynamic>.from(rows.first);
  }

  /// Replaces the cached row for [updatedRow]'s id with the server's version.
  void _replaceCachedUser(Map<String, dynamic> updatedRow) {
    final index = _users.indexWhere((u) => u['id'] == updatedRow['id']);
    if (index != -1) {
      _users[index] = updatedRow;
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

  Future<bool> _confirmActionDialog({
    required String title,
    required String message,
    required String confirmLabel,
    Color confirmColor = const Color(0xFF2E7D32),
    IconData icon = Icons.security_rounded,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: confirmColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: confirmColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF334155),
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _toggleAdminRole(Map<String, dynamic> user) async {
    final userId = user['id'] as String;
    if (userId == _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.shield_outlined, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text('You cannot change administrator privileges on your own account.'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final currentStatus = user['is_admin'] as bool? ?? false;
    final newStatus = !currentStatus;
    final userName = (user['full_name'] as String?)?.trim().isNotEmpty == true
        ? user['full_name'] as String
        : (user['email'] as String? ?? 'User');

    final confirmed = await _confirmActionDialog(
      title: newStatus ? 'Grant Administrator Role' : 'Revoke Administrator Role',
      message: newStatus
          ? 'Are you sure you want to promote "$userName" to Administrator?\n\n'
              '• "user_profiles.is_admin" will be set to TRUE.\n'
              '• "user_profiles.primary_role" will be updated to "admin".\n'
              '• Unrestricted access to user management, moderation, and settings.\n'
              '• The separate Moderator role is not changed.\n\n'
              'Confirm updating and persisting to the database?'
          : 'Are you sure you want to revoke Administrator privileges from "$userName"?\n\n'
              '• "user_profiles.is_admin" will be set to FALSE.\n'
              '• The user will lose access to administrative consoles.\n'
              '• The separate Moderator role is not changed.',
      confirmLabel: newStatus ? 'Confirm & Grant Role' : 'Confirm & Revoke Role',
      confirmColor: newStatus ? const Color(0xFF2E7D32) : Colors.red.shade700,
      icon: Icons.admin_panel_settings_rounded,
    );

    if (!confirmed) return;

    try {
      final updatedRow = await _persistProfileUpdate(
        userId,
        RoleUpdateRules.adminToggle(
          user: user,
          grant: newStatus,
          now: DateTime.now(),
        ),
      );

      if (mounted) {
        setState(() => _replaceCachedUser(updatedRow));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    newStatus
                        ? 'Administrator privileges granted to $userName and persisted to database.'
                        : 'Administrator privileges revoked from $userName and updated in database.',
                  ),
                ),
              ],
            ),
            backgroundColor:
                newStatus ? const Color(0xFF2E7D32) : Colors.orange.shade800,
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

  Future<void> _toggleModeratorRole(Map<String, dynamic> user) async {
    final userId = user['id'] as String;
    if (userId == _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.shield_outlined, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text('You cannot change moderator privileges on your own account.'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final currentStatus = user['is_moderator'] as bool? ?? false;
    final newStatus = !currentStatus;
    final userName = (user['full_name'] as String?)?.trim().isNotEmpty == true
        ? user['full_name'] as String
        : (user['email'] as String? ?? 'User');

    final confirmed = await _confirmActionDialog(
      title: newStatus ? 'Grant Moderator Role' : 'Revoke Moderator Role',
      message: newStatus
          ? 'Are you sure you want to assign Moderator privileges to "$userName"?\n\n'
              '• "user_profiles.is_moderator" will be set to TRUE.\n'
              '• The user can review, verify, approve, and reject botanical submissions.\n\n'
              'Confirm updating and persisting to the database?'
          : 'Are you sure you want to revoke Moderator privileges from "$userName"?\n\n'
              '• "user_profiles.is_moderator" will be set to FALSE.\n'
              '• The user will lose access to the Moderation Hub.',
      confirmLabel: newStatus ? 'Confirm & Grant Role' : 'Confirm & Revoke Role',
      confirmColor: newStatus ? Colors.indigo.shade700 : Colors.orange.shade800,
      icon: Icons.verified_user_rounded,
    );

    if (!confirmed) return;

    try {
      final updatedRow = await _persistProfileUpdate(
        userId,
        RoleUpdateRules.moderatorToggle(
          user: user,
          grant: newStatus,
          now: DateTime.now(),
        ),
      );

      if (mounted) {
        setState(() => _replaceCachedUser(updatedRow));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    newStatus
                        ? 'Moderator privileges granted to $userName and persisted to database.'
                        : 'Moderator privileges revoked from $userName and updated in database.',
                  ),
                ),
              ],
            ),
            backgroundColor: newStatus ? Colors.indigo : Colors.orange.shade800,
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

  Future<void> _togglePractitionerRole(Map<String, dynamic> user) async {
    final userId = user['id'] as String;
    if (userId == _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.shield_outlined, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text('You cannot change practitioner role on your own account.'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final currentStatus = user['is_practitioner'] as bool? ?? false;
    final newStatus = !currentStatus;
    final userName = (user['full_name'] as String?)?.trim().isNotEmpty == true
        ? user['full_name'] as String
        : (user['email'] as String? ?? 'User');

    final confirmed = await _confirmActionDialog(
      title: newStatus ? 'Grant Practitioner Role' : 'Revoke Practitioner Role',
      message: newStatus
          ? 'Are you sure you want to verify and grant Practitioner privileges to "$userName"?\n\n'
              '• "user_profiles.is_practitioner" will be set to TRUE.\n'
              '• "herbalist_profiles.verification_status" will be persisted as VERIFIED.\n'
              '• Telemedicine consultation booking will be enabled.\n\n'
              'Confirm updating and persisting to the database?'
          : 'Are you sure you want to revoke Practitioner privileges from "$userName"?\n\n'
              '• "user_profiles.is_practitioner" will be set to FALSE.\n'
              '• "herbalist_profiles.verification_status" will be set to REJECTED.',
      confirmLabel: newStatus ? 'Confirm & Grant Role' : 'Confirm & Revoke Role',
      confirmColor: newStatus ? Colors.teal.shade700 : Colors.red.shade700,
      icon: Icons.medical_services_rounded,
    );

    if (!confirmed) return;

    try {
      final updateData = <String, dynamic>{
        'is_practitioner': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (newStatus &&
          (user['is_admin'] != true) &&
          (user['is_moderator'] != true)) {
        updateData['primary_role'] = 'practitioner';
      }
      await _client
          .from('user_profiles')
          .update(updateData)
          .eq('id', userId);

      // Synchronize herbalist_profiles verification_status
      try {
        await _client.from('herbalist_profiles').update({
          'verification_status': newStatus ? 'verified' : 'rejected',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', userId);
      } catch (_) {}

      if (mounted) {
        setState(() {
          final index = _users.indexWhere((u) => u['id'] == userId);
          if (index != -1) {
            _users[index]['is_practitioner'] = newStatus;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    newStatus
                        ? 'Practitioner privileges granted to $userName and persisted to database.'
                        : 'Practitioner privileges revoked from $userName and updated in database.',
                  ),
                ),
              ],
            ),
            backgroundColor:
                newStatus ? Colors.teal.shade700 : Colors.grey.shade700,
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

  Future<void> _toggleSupplierRole(Map<String, dynamic> user) async {
    final userId = user['id'] as String;
    if (userId == _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.shield_outlined, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text('You cannot change supplier role on your own account.'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final currentStatus = user['is_supplier'] as bool? ?? false;
    final newStatus = !currentStatus;
    final userName = (user['full_name'] as String?)?.trim().isNotEmpty == true
        ? user['full_name'] as String
        : (user['email'] as String? ?? 'User');

    final confirmed = await _confirmActionDialog(
      title: newStatus ? 'Grant Supplier Role' : 'Revoke Supplier Role',
      message: newStatus
          ? 'Are you sure you want to grant Supplier privileges to "$userName"?\n\n'
              '• "user_profiles.is_supplier" will be set to TRUE.\n'
              '• "supplier_profiles.verification_status" will be persisted as VERIFIED.\n'
              '• Marketplace product catalog publishing will be enabled.\n\n'
              'Confirm updating and persisting to the database?'
          : 'Are you sure you want to revoke Supplier privileges from "$userName"?\n\n'
              '• "user_profiles.is_supplier" will be set to FALSE.\n'
              '• "supplier_profiles.verification_status" will be set to REJECTED.',
      confirmLabel: newStatus ? 'Confirm & Grant Role' : 'Confirm & Revoke Role',
      confirmColor: newStatus ? Colors.orange.shade800 : Colors.grey.shade700,
      icon: Icons.storefront_rounded,
    );

    if (!confirmed) return;

    try {
      final updateData = <String, dynamic>{
        'is_supplier': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (newStatus &&
          (user['is_admin'] != true) &&
          (user['is_moderator'] != true)) {
        updateData['primary_role'] = 'supplier';
      }
      await _client
          .from('user_profiles')
          .update(updateData)
          .eq('id', userId);

      // Synchronize supplier_profiles verification_status if record exists
      try {
        await _client.from('supplier_profiles').update({
          'verification_status': newStatus ? 'verified' : 'rejected',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', userId);
      } catch (_) {}

      if (mounted) {
        setState(() {
          final index = _users.indexWhere((u) => u['id'] == userId);
          if (index != -1) {
            _users[index]['is_supplier'] = newStatus;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    newStatus
                        ? 'Supplier privileges granted to $userName and persisted to database.'
                        : 'Supplier privileges revoked from $userName and updated in database.',
                  ),
                ),
              ],
            ),
            backgroundColor:
                newStatus ? Colors.orange.shade800 : Colors.grey.shade700,
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

  Future<void> _toggleUserActiveStatus(Map<String, dynamic> user) async {
    final userId = user['id'] as String;
    if (userId == _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.shield_outlined, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text('You cannot deactivate your own account.'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final currentActive = (user['is_active'] as bool?) ?? true;
    final newActive = !currentActive;
    final userName = (user['full_name'] as String?)?.trim().isNotEmpty == true
        ? user['full_name'] as String
        : (user['email'] as String? ?? 'User');

    final confirmed = await _confirmActionDialog(
      title: newActive ? 'Reactivate User Account' : 'Deactivate User Account',
      message: newActive
          ? 'Are you sure you want to restore and reactivate the account for "$userName"?\n\n'
              '• "user_profiles.is_active" will be persisted as TRUE.\n'
              '• The user will regain normal access to app services and portals.'
          : 'Are you sure you want to deactivate "$userName"?\n\n'
              '• "user_profiles.is_active" will be persisted as FALSE.\n'
              '• The user will be immediately locked out of all repository, consultation, and store features.\n'
              '• Upon next access or app resume, they will see the Account Deactivated screen.',
      confirmLabel: newActive ? 'Confirm & Reactivate' : 'Confirm & Deactivate',
      confirmColor: newActive ? const Color(0xFF2E7D32) : Colors.red.shade700,
      icon: newActive ? Icons.person_add_rounded : Icons.person_off_rounded,
    );

    if (!confirmed) return;

    try {
      await _client.from('user_profiles').update({
        'is_active': newActive,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      if (mounted) {
        setState(() {
          final index = _users.indexWhere((u) => u['id'] == userId);
          if (index != -1) {
            _users[index]['is_active'] = newActive;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  newActive ? Icons.check_circle_outline : Icons.block_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    newActive
                        ? 'Account for $userName reactivated successfully.'
                        : 'Account for $userName deactivated and locked out.',
                  ),
                ),
              ],
            ),
            backgroundColor:
                newActive ? const Color(0xFF2E7D32) : Colors.red.shade800,
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
    required String userName,
    required bool isAdmin,
    required bool isModerator,
    required bool isPractitioner,
    required bool isSupplier,
    String? currentPrimaryRole,
    bool isActive = true,
  }) async {
    if (userId == _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.shield_outlined, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text('You cannot modify roles or status for your own account.'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final confirmed = await _confirmActionDialog(
      title: 'Confirm Updated Roles & Privileges',
      message: 'Are you sure you want to update permissions for "$userName"?\n\n'
          '• Account Status: ${isActive ? "ACTIVE" : "DEACTIVATED"}\n'
          '• Administrator: ${isAdmin ? "GRANTED" : "REVOKED"}\n'
          '• Moderator: ${isModerator ? "GRANTED" : "REVOKED"}'
          '${isAdmin && !isModerator ? " (can still moderate as Administrator)" : ""}\n'
          '• Practitioner: ${isPractitioner ? "GRANTED" : "REVOKED"}\n'
          '• Supplier / Vendor: ${isSupplier ? "GRANTED" : "REVOKED"}\n\n'
          'All updates will be written directly and persisted to the database.',
      confirmLabel: 'Confirm & Persist to DB',
      confirmColor: const Color(0xFF2E7D32),
      icon: Icons.verified_user_rounded,
    );

    if (!confirmed) return;

    try {
      final updatedRow = await _persistProfileUpdate(
        userId,
        RoleUpdateRules.rightsUpdate(
          currentPrimaryRole: currentPrimaryRole,
          isAdmin: isAdmin,
          isModerator: isModerator,
          isPractitioner: isPractitioner,
          isSupplier: isSupplier,
          isActive: isActive,
          now: DateTime.now(),
        ),
      );

      // Synchronize related profile statuses
      try {
        await _client.from('supplier_profiles').update({
          'verification_status': isSupplier ? 'verified' : 'rejected',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', userId);
      } catch (_) {}

      try {
        await _client.from('herbalist_profiles').update({
          'verification_status': isPractitioner ? 'verified' : 'rejected',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', userId);
      } catch (_) {}

      if (mounted) {
        setState(() => _replaceCachedUser(updatedRow));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('User rights for $userName persisted to database successfully.'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
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
    final userId = user['id'] as String;
    if (userId == _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.shield_outlined, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text('Self-management restricted: You cannot modify roles or status for your own account.'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final theme = Theme.of(context);
    bool isAdmin = user['is_admin'] as bool? ?? false;
    bool isModerator = user['is_moderator'] as bool? ?? false;
    bool isPractitioner = user['is_practitioner'] as bool? ?? false;
    bool isSupplier = user['is_supplier'] as bool? ?? false;
    bool isActive = (user['is_active'] as bool?) ?? true;
    final fullName = (user['full_name'] as String?)?.trim() ?? '';
    final email = user['email'] as String? ?? '';

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
                        setDialogState(() => isAdmin = val);
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
                        isAdmin
                            ? 'Separate moderation role. Administrators can already moderate.'
                            : 'Review, verify, and approve/reject herbal submissions',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      activeThumbColor: Colors.indigo,
                      value: isModerator,
                      onChanged: (val) {
                        setDialogState(() => isModerator = val);
                      },
                    ),
                    const Divider(height: 1, thickness: 0.5, color: Color(0xFFE2E8F0)),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Traditional Practitioner',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'Can conduct telemedicine consultations and publish clinical profile',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      activeThumbColor: Colors.teal,
                      value: isPractitioner,
                      onChanged: (val) {
                        setDialogState(() => isPractitioner = val);
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
                    const Divider(height: 1, thickness: 0.5, color: Color(0xFFE2E8F0)),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Account Active',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'When deactivated, the user is locked out from accessing the app',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      activeThumbColor: const Color(0xFF2E7D32),
                      value: isActive,
                      onChanged: (val) {
                        setDialogState(() => isActive = val);
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
                      userName: fullName.isNotEmpty ? fullName : email,
                      isAdmin: isAdmin,
                      isModerator: isModerator,
                      isPractitioner: isPractitioner,
                      isSupplier: isSupplier,
                      currentPrimaryRole: user['primary_role'] as String?,
                      isActive: isActive,
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
      if (_selectedRoleFilter == 'practitioner' &&
          user['is_practitioner'] != true) {
        return false;
      }
      if (_selectedRoleFilter == 'supplier' && user['is_supplier'] != true) {
        return false;
      }
      if (_selectedRoleFilter == 'deactivated' && user['is_active'] != false) {
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
              AppPageHeader(
                title: 'User Management',
                subtitle: 'Manage accounts, roles & privileges',
                icon: Icons.manage_accounts_rounded,
                onBack: widget.onBack,
                padding: EdgeInsets.zero,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                              Icon(Icons.download_rounded,
                                  color: Color(0xFF2E7D32), size: 20),
                              SizedBox(width: 10),
                              Text('Excel (CSV)'),
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
              ),
              const SizedBox(height: 16),

              // ─── Search & View Mode (Inline) ───────────────────────────────────
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
                  const SizedBox(width: 10),
                  _buildViewModeToggle(theme),
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
                      'Practitioners',
                      'practitioner',
                      _users.where((u) => u['is_practitioner'] == true).length,
                      color: Colors.teal,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Suppliers',
                      'supplier',
                      _users.where((u) => u['is_supplier'] == true).length,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Deactivated',
                      'deactivated',
                      _users.where((u) => u['is_active'] == false).length,
                      color: Colors.red.shade700,
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

  Widget _buildViewModeToggle(ThemeData theme) {
    return Container(
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
                vertical: 7,
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
                vertical: 7,
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
        final isCurrentUser =
            _currentUserId != null && user['id'] == _currentUserId;
        final isAdmin = user['is_admin'] as bool? ?? false;
        final isModerator = user['is_moderator'] as bool? ?? false;
        final isPractitioner = user['is_practitioner'] as bool? ?? false;
        final isSupplier = user['is_supplier'] as bool? ?? false;
        final isActive = (user['is_active'] as bool?) ?? true;
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
              color: !isActive
                  ? Colors.red.shade300
                  : (isAdmin
                      ? theme.colorScheme.primary.withValues(alpha: 0.3)
                      : (isModerator
                          ? Colors.indigo.shade200
                          : Colors.grey.shade200)),
              width: (!isActive || isAdmin) ? 1.5 : 1.0,
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
                    backgroundColor: !isActive
                        ? Colors.red.shade400
                        : (isAdmin
                            ? theme.colorScheme.primary
                            : (isModerator
                                ? Colors.indigo
                                : (isPractitioner
                                    ? Colors.teal
                                    : (isSupplier
                                        ? Colors.orange
                                        : Colors.grey.shade300)))),
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
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                fullName != null && fullName.isNotEmpty
                                    ? fullName
                                    : 'Unnamed User',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: !isActive
                                      ? Colors.grey.shade600
                                      : const Color(0xFF1E293B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCurrentUser) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.3),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  'YOU',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
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
                    isPractitioner: isPractitioner,
                    isSupplier: isSupplier,
                    isActive: isActive,
                    isCurrentUser: isCurrentUser,
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
                      if (!isActive)
                        _buildBadge('DEACTIVATED', Colors.red.shade700),
                      if (isAdmin)
                        _buildBadge('ADMIN', theme.colorScheme.primary),
                      if (isModerator && !isAdmin)
                        _buildBadge('MODERATOR', Colors.indigo),
                      if (isPractitioner)
                        _buildBadge('PRACTITIONER', Colors.teal),
                      if (isSupplier)
                        _buildBadge('SUPPLIER', Colors.orange),
                      if (!isAdmin &&
                          !isModerator &&
                          !isPractitioner &&
                          !isSupplier &&
                          isActive)
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
                  if (isCurrentUser) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 14,
                            color: Colors.amber.shade900,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Protected (Logged-in Account)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
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
    required bool isPractitioner,
    required bool isSupplier,
    required bool isActive,
    bool isCurrentUser = false,
  }) {
    if (isCurrentUser) {
      return PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        tooltip: 'Protected Account',
        itemBuilder: (context) => [
          const PopupMenuItem(
            enabled: false,
            child: Row(
              children: [
                Icon(Icons.lock_outline_rounded, color: Colors.grey, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Self-management restricted',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'Options',
      onSelected: (action) {
        if (action == 'manage_rights') {
          _showManageRightsDialog(context, user);
        } else if (action == 'toggle_admin') {
          _toggleAdminRole(user);
        } else if (action == 'toggle_moderator') {
          _toggleModeratorRole(user);
        } else if (action == 'toggle_practitioner') {
          _togglePractitionerRole(user);
        } else if (action == 'toggle_supplier') {
          _toggleSupplierRole(user);
        } else if (action == 'toggle_active') {
          _toggleUserActiveStatus(user);
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
          value: 'toggle_practitioner',
          child: Row(
            children: [
              Icon(
                isPractitioner
                    ? Icons.medical_services_outlined
                    : Icons.medical_services_rounded,
                color: isPractitioner ? Colors.grey : Colors.teal,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(isPractitioner ? 'Revoke Practitioner' : 'Make Practitioner'),
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
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'toggle_active',
          child: Row(
            children: [
              Icon(
                isActive ? Icons.block_outlined : Icons.check_circle_outline,
                color: isActive ? Colors.red.shade700 : const Color(0xFF2E7D32),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isActive ? 'Deactivate Account' : 'Reactivate Account',
                style: TextStyle(
                  color: isActive ? Colors.red.shade700 : const Color(0xFF2E7D32),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableRow(BuildContext context, Map<String, dynamic> user) {
    final theme = Theme.of(context);
    final isCurrentUser =
        _currentUserId != null && user['id'] == _currentUserId;
    final isAdmin = user['is_admin'] as bool? ?? false;
    final isModerator = user['is_moderator'] as bool? ?? false;
    final isPractitioner = user['is_practitioner'] as bool? ?? false;
    final isSupplier = user['is_supplier'] as bool? ?? false;
    final isActive = (user['is_active'] as bool?) ?? true;
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
                  backgroundColor: !isActive
                      ? Colors.red.shade400
                      : (isAdmin
                          ? theme.colorScheme.primary
                          : (isModerator
                              ? Colors.indigo
                              : (isPractitioner
                                  ? Colors.teal
                                  : (isSupplier
                                      ? Colors.orange
                                      : const Color(0xFFE2E8F0))))),
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
                            color: (isAdmin ||
                                    isModerator ||
                                    isPractitioner ||
                                    isSupplier)
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          fullName?.isNotEmpty == true ? fullName! : 'Unnamed User',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: !isActive
                                ? Colors.grey.shade600
                                : const Color(0xFF1E293B),
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.3),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            'YOU',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
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
                if (!isActive)
                  _chip('DEACTIVATED', Colors.red.shade700),
                if (isAdmin)
                  _chip('ADMIN', theme.colorScheme.primary)
                else if (isModerator)
                  _chip('MODERATOR', Colors.indigo),
                if (isPractitioner) _chip('PRACTITIONER', Colors.teal),
                if (isSupplier) _chip('SUPPLIER', Colors.orange),
                if (!isAdmin &&
                    !isModerator &&
                    !isPractitioner &&
                    !isSupplier &&
                    isActive)
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
              child: _buildUserActionMenu(
                user: user,
                isAdmin: isAdmin,
                isModerator: isModerator,
                isPractitioner: isPractitioner,
                isSupplier: isSupplier,
                isActive: isActive,
                isCurrentUser: isCurrentUser,
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
