import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleAdminRole(String userId, bool currentStatus) async {
    final newStatus = !currentStatus;
    try {
      await _client
          .from('user_profiles')
          .update({'is_admin': newStatus})
          .eq('id', userId);

      if (mounted) {
        setState(() {
          final index = _users.indexWhere((u) => u['id'] == userId);
          if (index != -1) {
            _users[index]['is_admin'] = newStatus;
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update role: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rs = ResponsiveSize(context);

    final filteredUsers = _users.where((user) {
      final email = (user['email'] ?? '').toString().toLowerCase();
      final name = (user['full_name'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      return email.contains(q) || name.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(rs.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
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
                        'Manage client accounts and administrators for HerbCircle & Zim Herbs',
                        style: TextStyle(
                          fontSize: rs.bodyFont * 0.9,
                          color: Colors.grey.shade600,
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
              const SizedBox(height: 16),

              // Search Bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(rs.borderRadius),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 16),

              // Content List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline,
                                    size: 48, color: Colors.red),
                                const SizedBox(height: 12),
                                Text('Error loading users: $_errorMessage'),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _loadUsers,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
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
                            : ListView.separated(
                                itemCount: filteredUsers.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final user = filteredUsers[index];
                                  final isAdmin =
                                      user['is_admin'] as bool? ?? false;
                                  final isSupplier =
                                      user['is_supplier'] as bool? ?? false;
                                  final fullName =
                                      (user['full_name'] as String?)?.trim();
                                  final email =
                                      user['email'] as String? ?? 'No email';
                                  final avatarUrl =
                                      user['avatar_url'] as String?;

                                  return Card(
                                    elevation: 1,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          rs.borderRadius),
                                      side: BorderSide(
                                        color: isAdmin
                                            ? theme.colorScheme.primary
                                                .withValues(alpha: 0.3)
                                            : Colors.grey.shade200,
                                      ),
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: isAdmin
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.secondary,
                                        backgroundImage: avatarUrl != null &&
                                                avatarUrl.isNotEmpty
                                            ? NetworkImage(avatarUrl)
                                            : null,
                                        child: avatarUrl == null ||
                                                avatarUrl.isEmpty
                                            ? Text(
                                                (fullName?.isNotEmpty == true
                                                        ? fullName![0]
                                                        : email[0])
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              )
                                            : null,
                                      ),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              fullName != null &&
                                                      fullName.isNotEmpty
                                                  ? fullName
                                                  : email,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          if (isAdmin)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.primary
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                    color: theme
                                                        .colorScheme.primary),
                                              ),
                                              child: Text(
                                                'ADMIN',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      theme.colorScheme.primary,
                                                ),
                                              ),
                                            ),
                                          if (isSupplier) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.orange
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                    color: Colors.orange),
                                              ),
                                              child: const Text(
                                                'SUPPLIER',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.orange,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      subtitle: Text(email),
                                      trailing: PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert),
                                        onSelected: (action) {
                                          if (action == 'toggle_admin') {
                                            _toggleAdminRole(
                                                user['id'] as String, isAdmin);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: 'toggle_admin',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  isAdmin
                                                      ? Icons.remove_moderator
                                                      : Icons
                                                          .admin_panel_settings,
                                                  color: isAdmin
                                                      ? Colors.red
                                                      : Colors.green,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(isAdmin
                                                    ? 'Revoke Admin'
                                                    : 'Make Admin'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
