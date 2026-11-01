import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/core/components/app_page_header.dart';
import 'package:zim_herbs_repo/core/components/app_error_view.dart';
import 'package:zim_herbs_repo/core/errors/error_handler.dart';
import 'package:zim_herbs_repo/core/errors/failure.dart';
import 'package:zim_herbs_repo/core/utils/responsive.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_cubit.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_state.dart';
import 'package:zim_herbs_repo/features/auth/domain/user_model.dart';

/// User Profile screen displaying personal details, contact information,
/// and allowing users to apply or update practitioner and supplier certifications.
class ProfilePage extends StatefulWidget {
  final VoidCallback? onBack;

  const ProfilePage({super.key, this.onBack});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _practitionerStatus;
  String? _supplierStatus;
  Failure? _activeFailure;

  @override
  void initState() {
    super.initState();
    _loadApplicationStatuses();
  }

  Future<void> _loadApplicationStatuses() async {
    final authCubit = context.read<AuthCubit>();
    final state = authCubit.state;
    if (state is Authenticated) {
      final pStatus = await authCubit.getPractitionerApplicationStatus(state.user.id);
      final sStatus = await authCubit.getSupplierApplicationStatus(state.user.id);
      if (mounted) {
        setState(() {
          _practitionerStatus = pStatus;
          _supplierStatus = sStatus;
        });
      }
    }
  }

  String _extractInitials(String name, [String? email]) {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) {
      final parts = trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      } else if (parts.isNotEmpty && parts.first.isNotEmpty) {
        return parts.first[0].toUpperCase();
      }
    }
    if (email != null && email.trim().isNotEmpty) {
      final emailName = email.trim().split('@').first;
      if (emailName.isNotEmpty) {
        return emailName[0].toUpperCase();
      }
    }
    return 'U';
  }

  void _showEditProfileDialog(BuildContext context, UserModel user) {
    final nameController = TextEditingController(text: user.name);
    final usernameController = TextEditingController(text: user.username ?? '');
    final phoneController = TextEditingController(text: user.phoneNumber ?? '');
    final locationController = TextEditingController(text: user.location ?? '');
    final bioController = TextEditingController(text: user.bio ?? '');
    final selectedInterests = Set<String>.from(user.healthInterests);
    final formKey = GlobalKey<FormState>();

    const availableInterests = [
      'Immune Support',
      'Digestive & Gut Health',
      'Respiratory & Lungs',
      'Skin Care & Wounds',
      'Women\'s Wellness',
      'Chronic Care',
      'Stress & Sleep',
      'Pain & Inflammation',
      'Cardiovascular',
      'Detox & Cleanse',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final theme = Theme.of(dialogCtx);

            return AlertDialog(
              title: const Text('Edit Profile Details', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 500,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name *',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: usernameController,
                          decoration: InputDecoration(
                            labelText: 'Username Handle',
                            prefixIcon: const Icon(Icons.alternate_email),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: const Icon(Icons.phone_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: locationController,
                          decoration: InputDecoration(
                            labelText: 'Location / City',
                            prefixIcon: const Icon(Icons.location_on_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: bioController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Bio / Notes',
                            prefixIcon: const Icon(Icons.description_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Health Interests',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: availableInterests.map((interest) {
                            final isSel = selectedInterests.contains(interest);
                            return FilterChip(
                              label: Text(interest, style: const TextStyle(fontSize: 11)),
                              selected: isSel,
                              selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                              checkmarkColor: theme.colorScheme.primary,
                              onSelected: (val) {
                                setDialogState(() {
                                  if (val) {
                                    selectedInterests.add(interest);
                                  } else {
                                    selectedInterests.remove(interest);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.pop(ctx);
                      final updated = user.copyWith(
                        name: nameController.text.trim(),
                        username: usernameController.text.trim().toLowerCase(),
                        phoneNumber: phoneController.text.trim(),
                        location: locationController.text.trim(),
                        bio: bioController.text.trim(),
                        healthInterests: selectedInterests.toList(),
                      );
                      await context.read<AuthCubit>().updateProfile(updated);
                    }
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showApplyPractitionerDialog(BuildContext context, UserModel user) {
    final specController = TextEditingController(text: 'Traditional Herbalist');
    final yearsController = TextEditingController(text: '3');
    final locationController = TextEditingController(text: user.location ?? '');
    final phoneController = TextEditingController(text: user.phoneNumber ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.medical_services_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Practitioner Application', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber.shade900, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your credentials will be submitted to the Moderation Hub. Once validated by staff, your verified practitioner badge will be published.',
                              style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: specController,
                      decoration: InputDecoration(
                        labelText: 'Herbal Specialisation *',
                        hintText: 'e.g. Traditional Healer, Naturopath',
                        prefixIcon: const Icon(Icons.school_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Specialisation is required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: yearsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Years of Experience *',
                        hintText: 'e.g. 5',
                        prefixIcon: const Icon(Icons.history_edu_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Experience years required';
                        final n = int.tryParse(v.trim());
                        if (n == null || n < 0 || n > 75) return 'Enter a valid number of years';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: locationController,
                      decoration: InputDecoration(
                        labelText: 'Practice Location / Clinic Address *',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Location is required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Direct Consultation Phone *',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Phone number is required' : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(ctx);
                  final years = int.tryParse(yearsController.text.trim()) ?? 1;
                  final authCubit = context.read<AuthCubit>();
                  final messenger = ScaffoldMessenger.of(context);
                  await authCubit.applyForPractitioner(
                        specialisation: specController.text.trim(),
                        yearsOfExperience: years,
                        location: locationController.text.trim(),
                        phoneNumber: phoneController.text.trim(),
                      );
                  _loadApplicationStatuses();
                  if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Practitioner application submitted successfully! Under review.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              child: const Text('Submit Application'),
            ),
          ],
        );
      },
    );
  }

  void _showApplySupplierDialog(BuildContext context, UserModel user) {
    final businessNameController = TextEditingController();
    final categoriesController = TextEditingController(text: 'Raw Medicinal Herbs & Powders');
    final yearsController = TextEditingController(text: '2');
    final locationController = TextEditingController(text: user.location ?? '');
    final phoneController = TextEditingController(text: user.phoneNumber ?? '');
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.storefront_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Supplier Application', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber.shade900, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Supplier applications are queued for administrator review. Once verified and approved, your products and supplier badge will be published in the Marketplace.',
                              style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: businessNameController,
                      decoration: InputDecoration(
                        labelText: 'Business / Enterprise Name *',
                        hintText: 'e.g. Baobab Herbal Collective',
                        prefixIcon: const Icon(Icons.store_mall_directory_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Business name is required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: categoriesController,
                      decoration: InputDecoration(
                        labelText: 'Products / Categories Supplied *',
                        hintText: 'e.g. Raw Herbs, Herbal Teas, Essential Oils',
                        prefixIcon: const Icon(Icons.category_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Categories are required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: yearsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Years in Business / Operation *',
                        hintText: 'e.g. 3',
                        prefixIcon: const Icon(Icons.history_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Years in business required';
                        final n = int.tryParse(v.trim());
                        if (n == null || n < 0 || n > 75) return 'Enter a valid number of years';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: locationController,
                      decoration: InputDecoration(
                        labelText: 'Operating Facility / City *',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Location is required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Business Contact Phone *',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Phone number is required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Business Description (Optional)',
                        hintText: 'Tell us about your sourcing, harvesting, or traditional processing...',
                        prefixIcon: const Icon(Icons.description_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(ctx);
                  final bizName = businessNameController.text.trim();
                  final cats = categoriesController.text.trim();
                  final yrs = int.tryParse(yearsController.text.trim()) ?? 1;
                  final loc = locationController.text.trim();
                  final phone = phoneController.text.trim();
                  final desc = descriptionController.text.trim();
                  final fullDesc =
                      'Business: $bizName | Categories: $cats | Exp: $yrs yrs${desc.isNotEmpty ? '\n$desc' : ''}';
                  final authCubit = context.read<AuthCubit>();
                  final messenger = ScaffoldMessenger.of(context);

                  await authCubit.applyForSupplier(
                        businessName: bizName,
                        location: loc,
                        categories: cats,
                        yearsInOperation: yrs,
                        contactPhone: phone,
                        description: fullDesc,
                      );
                  if (mounted) {
                    setState(() {
                      _supplierStatus = 'pending';
                    });
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Supplier application submitted! Under review by administrator. Once approved, your products will be published.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              child: const Text('Submit Application'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);
    final theme = Theme.of(context);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F2),
      appBar: isDesktop
          ? null
          : AppPageAppBar(
              title: 'My Profile',
              onBack: widget.onBack ?? () => Navigator.pop(context),
            ),
      body: SafeArea(
        child: Column(
          children: [
            AppPageHeader(
              title: 'My Profile',
              subtitle: 'Manage your account, roles, and herbal accreditations',
              icon: Icons.person_rounded,
              onBack: widget.onBack ?? () => Navigator.pop(context),
            ),
            Expanded(
              child: BlocConsumer<AuthCubit, AuthState>(
                listener: (context, state) {
                  if (state is AuthError) {
                    setState(() {
                      _activeFailure = state.failure ?? ErrorHandler.handle(state.message);
                    });
                  }
                },
                builder: (context, state) {
                  if (state is! Authenticated) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final user = state.user;
                  final initials = _extractInitials(user.name, user.email);

                  return SingleChildScrollView(
                    padding: EdgeInsets.all(rs.defaultPadding),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 860),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_activeFailure != null) ...[
                            AppErrorView.banner(
                              failure: _activeFailure,
                              onDismiss: () => setState(() => _activeFailure = null),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // 1. Profile Overview Card
                          _buildProfileCard(theme, rs, user, initials),
                          const SizedBox(height: 20),

                          // 2. Practitioner Accreditation Section
                          _buildPractitionerCard(theme, rs, user),
                          const SizedBox(height: 20),

                          // 3. Supplier Accreditation Section
                          _buildSupplierCard(theme, rs, user),
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
    );
  }

  // ================= 1. PROFILE OVERVIEW CARD =================
  Widget _buildProfileCard(
    ThemeData theme,
    ResponsiveSize rs,
    UserModel user,
    String initials,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(rs.pick(mobile: 16.0, tablet: 20.0, desktop: 24.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: rs.pick(mobile: 32.0, tablet: 38.0, desktop: 44.0),
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: rs.pick(mobile: 22.0, tablet: 26.0, desktop: 30.0),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${user.displayUsername}',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildBadge(
                            label: user.role.displayName,
                            color: theme.colorScheme.primary,
                            icon: Icons.shield_outlined,
                          ),
                          if (user.isPractitioner)
                            _buildBadge(
                              label: 'Verified Practitioner',
                              color: const Color(0xFF2E7D32),
                              icon: Icons.verified_rounded,
                            ),
                          if (user.isSupplier)
                            _buildBadge(
                              label: 'Verified Supplier',
                              color: const Color(0xFF1565C0),
                              icon: Icons.storefront_rounded,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showEditProfileDialog(context, user),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const Divider(height: 28),

            // Details Grid
            _buildDetailRow(Icons.email_outlined, 'Email', user.email),
            const SizedBox(height: 10),
            _buildDetailRow(
              Icons.phone_outlined,
              'Phone',
              user.phoneNumber != null && user.phoneNumber!.isNotEmpty
                  ? user.phoneNumber!
                  : 'Not provided',
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              Icons.location_on_outlined,
              'Location',
              user.location != null && user.location!.isNotEmpty
                  ? user.location!
                  : 'Not specified',
            ),

            if (user.bio != null && user.bio!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDetailRow(Icons.description_outlined, 'Bio / Profile', user.bio!),
            ],

            if (user.healthInterests.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Health Interests',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: user.healthInterests.map((interest) {
                  return Chip(
                    label: Text(interest, style: const TextStyle(fontSize: 11)),
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    padding: EdgeInsets.zero,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 10),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildBadge({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  // ================= 2. PRACTITIONER ACCREDITATION CARD =================
  Widget _buildPractitionerCard(ThemeData theme, ResponsiveSize rs, UserModel user) {
    final isVerified = user.isPractitioner;
    final isPending = !isVerified && (_practitionerStatus == 'pending' || user.primaryRole == 'practitioner');
    final isRejected = !isVerified && _practitionerStatus == 'rejected';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(rs.pick(mobile: 16.0, tablet: 20.0, desktop: 24.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isVerified
                      ? Colors.green.shade50
                      : (isPending ? Colors.amber.shade50 : Colors.grey.shade100),
                  child: Icon(
                    Icons.medical_services_rounded,
                    color: isVerified
                        ? Colors.green.shade700
                        : (isPending ? Colors.amber.shade900 : Colors.grey.shade700),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Traditional Practitioner Certification',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isVerified
                            ? 'Approved & Published Practitioner'
                            : (isPending
                                ? 'Application Under Review by Moderator'
                                : (isRejected
                                    ? 'Application Needs Revision'
                                    : 'Not Certified')),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isVerified
                              ? Colors.green.shade700
                              : (isPending ? Colors.amber.shade900 : Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (isVerified) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your practitioner credentials are published! You can conduct consultations and submit verified clinical formulations.',
                        style: TextStyle(fontSize: 12, color: Colors.green.shade900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _showApplyPractitionerDialog(context, user),
                icon: const Icon(Icons.edit_note_rounded, size: 16),
                label: const Text('Update Practitioner Credentials'),
              ),
            ] else if (isPending) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.hourglass_top_rounded, color: Colors.amber.shade900, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your practitioner application has been queued in the Moderation Hub. An administrator or moderator will review and publish your credentials.',
                        style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _showApplyPractitionerDialog(context, user),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Update Pending Application'),
              ),
            ] else ...[
              Text(
                'Are you a licensed herbalist, naturopath, or traditional medical practitioner? Apply for accreditation to offer remote consultations and publish clinical remedies.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () => _showApplyPractitionerDialog(context, user),
                icon: const Icon(Icons.verified_user_outlined, size: 16),
                label: const Text('Apply for Practitioner Certification'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ================= 3. SUPPLIER ACCREDITATION CARD =================
  Widget _buildSupplierCard(ThemeData theme, ResponsiveSize rs, UserModel user) {
    final isVerified = user.isSupplier || _supplierStatus == 'verified';
    final isPending = !isVerified && (_supplierStatus == 'pending' || user.primaryRole == 'supplier');
    final isRejected = !isVerified && !isPending && _supplierStatus == 'rejected';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(rs.pick(mobile: 16.0, tablet: 20.0, desktop: 24.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isVerified
                      ? Colors.blue.shade50
                      : (isPending
                          ? Colors.amber.shade50
                          : (isRejected ? Colors.red.shade50 : Colors.grey.shade100)),
                  child: Icon(
                    Icons.storefront_rounded,
                    color: isVerified
                        ? Colors.blue.shade700
                        : (isPending
                            ? Colors.amber.shade900
                            : (isRejected ? Colors.red.shade700 : Colors.grey.shade700)),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Botanical Supplier Accreditation',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isVerified
                            ? 'Approved & Published Marketplace Supplier'
                            : (isPending
                                ? 'Application Under Review by Administrator'
                                : (isRejected
                                    ? 'Application Declined / Rejected'
                                    : 'Not a Supplier')),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isVerified
                              ? Colors.blue.shade700
                              : (isPending
                                  ? Colors.amber.shade900
                                  : (isRejected ? Colors.red.shade700 : Colors.grey.shade600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (isVerified) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your supplier account is active and published! You can supply authenticated herbs and wellness products in the Zim Herbs Store.',
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _showApplySupplierDialog(context, user),
                icon: const Icon(Icons.edit_note_rounded, size: 16),
                label: const Text('Update Supplier Business Profile'),
              ),
            ] else if (isPending) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.hourglass_top_rounded, color: Colors.amber.shade900, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your supplier application has been submitted and is awaiting administrator approval. Once approved, your supplier badge and products will be published.',
                        style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _showApplySupplierDialog(context, user),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Update Pending Supplier Application'),
              ),
            ] else if (isRejected) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cancel_outlined, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your supplier accreditation application was not approved. You may review your business information and re-apply.',
                        style: TextStyle(fontSize: 12, color: Colors.red.shade900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _showApplySupplierDialog(context, user),
                icon: const Icon(Icons.restart_alt_rounded, size: 16),
                label: const Text('Re-apply for Supplier Accreditation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ] else ...[
              Text(
                'Are you a grower, collector, or vendor of certified Zimbabwean indigenous medicinal herbs? Apply to list and supply authenticated botanical products through the Zim Herbs Store.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () => _showApplySupplierDialog(context, user),
                icon: const Icon(Icons.add_business_rounded, size: 16),
                label: const Text('Apply for Supplier Accreditation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
