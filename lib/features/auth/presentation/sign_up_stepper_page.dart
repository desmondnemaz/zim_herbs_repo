import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/core/components/app_error_view.dart';
import 'package:zim_herbs_repo/core/components/app_page_app_bar.dart';
import 'package:zim_herbs_repo/core/connection/bloc/connection_bloc.dart' as conn;
import 'package:zim_herbs_repo/core/errors/error_handler.dart';
import 'package:zim_herbs_repo/core/errors/failure.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_cubit.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_state.dart';

/// A guided multi-step registration flow satisfying all `user_profiles`
/// and `herbalist_profiles` database constraints.
class SignUpStepperPage extends StatefulWidget {
  const SignUpStepperPage({super.key});

  @override
  State<SignUpStepperPage> createState() => _SignUpStepperPageState();
}

class _SignUpStepperPageState extends State<SignUpStepperPage> {
  int _currentStep = 0;

  // Form Keys
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();
  final _step4Key = GlobalKey<FormState>();

  // Step 1 Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Step 2 Controllers
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();

  // Step 3 Controllers & State
  String _selectedRole = 'household'; // 'household', 'practitioner', 'supplier'
  final Set<String> _selectedHealthInterests = <String>{};
  final _bioController = TextEditingController();

  // Step 4 Controllers (Practitioner accreditation)
  final _specialisationController = TextEditingController(text: 'Traditional Herbalist');
  final _yearsExperienceController = TextEditingController(text: '3');

  // Step 4 Controllers (Supplier accreditation)
  final _businessNameController = TextEditingController();
  final _supplierCategoryController = TextEditingController(text: 'Raw Medicinal Herbs & Extracts');
  final _supplierYearsController = TextEditingController(text: '2');

  Failure? _activeFailure;

  static const List<String> _availableHealthInterests = [
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

  static const List<String> _popularLocations = [
    'Harare',
    'Bulawayo',
    'Chitungwiza',
    'Mutare',
    'Gweru',
    'Kwekwe',
    'Masvingo',
    'Victoria Falls',
    'Hwange',
    'Marondera',
    'Bindura',
    'Zvishavane',
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _specialisationController.dispose();
    _yearsExperienceController.dispose();
    _businessNameController.dispose();
    _supplierCategoryController.dispose();
    _supplierYearsController.dispose();
    super.dispose();
  }

  bool get _needsAccreditationStep =>
      _selectedRole == 'practitioner' || _selectedRole == 'supplier';

  int get _totalSteps => _needsAccreditationStep ? 4 : 3;

  void _nextStep() {
    FocusScope.of(context).unfocus();
    setState(() => _activeFailure = null);

    bool isValid = false;
    if (_currentStep == 0) {
      isValid = _step1Key.currentState?.validate() ?? false;
    } else if (_currentStep == 1) {
      isValid = _step2Key.currentState?.validate() ?? false;
    } else if (_currentStep == 2) {
      isValid = _step3Key.currentState?.validate() ?? false;
    } else if (_currentStep == 3) {
      isValid = _step4Key.currentState?.validate() ?? false;
    }

    if (!isValid) return;

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _submitRegistration();
    }
  }

  void _prevStep() {
    FocusScope.of(context).unfocus();
    if (_currentStep > 0) {
      setState(() {
        _activeFailure = null;
        _currentStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _submitRegistration() {
    // Check offline connectivity
    try {
      final connBloc = context.read<conn.ConnectionBloc>();
      if (connBloc.state.status == conn.ConnectionStatus.offline) {
        setState(() {
          _activeFailure = const Failure(
            title: 'No Internet Connection',
            message:
                'You are currently offline. Please connect to Wi-Fi or mobile data to register.',
            type: FailureType.noInternet,
          );
        });
        return;
      }
    } catch (_) {}

    final yearsExp = int.tryParse(_yearsExperienceController.text.trim()) ?? 1;
    final supplierYrs =
        int.tryParse(_supplierYearsController.text.trim()) ?? 1;

    String? effectiveBio = _bioController.text.trim();
    if (_selectedRole == 'supplier') {
      final bizName = _businessNameController.text.trim();
      final cat = _supplierCategoryController.text.trim();
      final yrs = _supplierYearsController.text.trim();
      final bizHeader =
          'Business: $bizName | Products: $cat | Experience: $yrs yrs';
      effectiveBio =
          effectiveBio.isNotEmpty ? '$bizHeader\n$effectiveBio' : bizHeader;
    }

    context.read<AuthCubit>().signUpWithCredentials(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _fullNameController.text.trim(),
          username: _usernameController.text.trim().toLowerCase(),
          phoneNumber: _phoneController.text.trim(),
          location: _locationController.text.trim(),
          primaryRole: _selectedRole,
          healthInterests: _selectedHealthInterests.toList(),
          bio: effectiveBio,
          practitionerSpecialisation: _selectedRole == 'practitioner'
              ? _specialisationController.text.trim()
              : null,
          practitionerYearsOfExperience:
              _selectedRole == 'practitioner' ? yearsExp : null,
          supplierName: _selectedRole == 'supplier'
              ? _businessNameController.text.trim()
              : null,
          supplierLocation: _selectedRole == 'supplier'
              ? _locationController.text.trim()
              : null,
          supplierCategories: _selectedRole == 'supplier'
              ? _supplierCategoryController.text.trim()
              : null,
          supplierYearsInOperation:
              _selectedRole == 'supplier' ? supplierYrs : null,
          applySupplier: false,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rs = ResponsiveSize(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppPageAppBar(
        title: 'Create Account',
        onBack: _prevStep,
      ),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            setState(() {
              _activeFailure = state.failure ?? ErrorHandler.handle(state.message);
            });
          } else if (state is Authenticated) {
            // Successfully signed in with new profile
            Navigator.pop(context);
          }
        },
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: rs.pick(mobile: 16.0, tablet: 24.0, desktop: 32.0),
              vertical: 20.0,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(
                    rs.pick(mobile: 18.0, tablet: 24.0, desktop: 28.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Step Progress Header
                      _buildStepProgressIndicator(theme),
                      const SizedBox(height: 24),

                      // Error banner if any
                      if (_activeFailure != null) ...[
                        AppErrorView.banner(
                          failure: _activeFailure,
                          onDismiss: () => setState(() => _activeFailure = null),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Active Step Form Content
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _buildCurrentStepContent(theme, rs),
                      ),
                      const SizedBox(height: 28),

                      // Navigation Buttons
                      _buildNavigationRow(theme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepProgressIndicator(ThemeData theme) {
    final titles = [
      'Account',
      'Personal',
      'Interests',
      if (_needsAccreditationStep) 'Accreditation',
    ];

    return Column(
      children: [
        Row(
          children: List.generate(_totalSteps * 2 - 1, (index) {
            if (index.isOdd) {
              final stepBefore = index ~/ 2;
              final isDone = _currentStep > stepBefore;
              return Expanded(
                child: Container(
                  height: 3,
                  color: isDone
                      ? theme.colorScheme.primary
                      : Colors.grey.shade300,
                ),
              );
            }
            final stepIndex = index ~/ 2;
            final isDone = _currentStep > stepIndex;
            final isCurrent = _currentStep == stepIndex;

            return CircleAvatar(
              radius: 14,
              backgroundColor: isDone || isCurrent
                  ? theme.colorScheme.primary
                  : Colors.grey.shade300,
              child: isDone
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : Text(
                      '${stepIndex + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isCurrent ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_totalSteps, (index) {
            final isCurrent = _currentStep == index;
            return Text(
              titles[index],
              style: TextStyle(
                fontSize: 11,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                color: isCurrent ? theme.colorScheme.primary : Colors.grey.shade600,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCurrentStepContent(ThemeData theme, ResponsiveSize rs) {
    switch (_currentStep) {
      case 0:
        return _buildStep1Account(theme);
      case 1:
        return _buildStep2Personal(theme);
      case 2:
        return _buildStep3Interests(theme);
      case 3:
        return _buildStep4Accreditation(theme);
      default:
        return const SizedBox.shrink();
    }
  }

  // ================= STEP 1: ACCOUNT CREDENTIALS =================
  Widget _buildStep1Account(ThemeData theme) {
    return Form(
      key: _step1Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Credentials',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter your email, handle, and choose a secure password.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),

          // Email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address *',
              hintText: 'e.g. tatenda@gmail.com',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email address';
              }
              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
              if (!emailRegex.hasMatch(value.trim())) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Username Handle
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Username Handle *',
              hintText: 'e.g. chipo_herbalist',
              prefixIcon: const Icon(Icons.alternate_email_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a username';
              }
              if (value.trim().length < 3) {
                return 'Username must be at least 3 characters';
              }
              if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
                return 'Use letters, numbers, and underscores only';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password *',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Confirm Password
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirm Password *',
              prefixIcon: const Icon(Icons.lock_reset_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  // ================= STEP 2: PERSONAL & CONTACT =================
  Widget _buildStep2Personal(ThemeData theme) {
    return Form(
      key: _step2Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Provide your legal or preferred name and contact details.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),

          // Full Name
          TextFormField(
            controller: _fullNameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Full Name *',
              hintText: 'e.g. Dr. Tapiwa Moyo',
              prefixIcon: const Icon(Icons.badge_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your full name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Phone Number
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number *',
              hintText: 'e.g. +263 77 123 4567',
              prefixIcon: const Icon(Icons.phone_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your phone number';
              }
              if (value.trim().length < 6) {
                return 'Please enter a valid phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Location
          TextFormField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: 'Location / City *',
              hintText: 'e.g. Harare, Zimbabwe',
              prefixIcon: const Icon(Icons.location_on_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your city or region';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Quick City chips
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _popularLocations.map((city) {
              return ActionChip(
                label: Text(city, style: const TextStyle(fontSize: 11)),
                onPressed: () {
                  setState(() {
                    _locationController.text = city;
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ================= STEP 3: PERSONA, INTERESTS & BIO =================
  Widget _buildStep3Interests(ThemeData theme) {
    return Form(
      key: _step3Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Persona & Health Interests',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose your primary portal role and topics of interest.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),

          // Role selection cards
          RadioGroup<String>(
            groupValue: _selectedRole,
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedRole = val);
              }
            },
            child: Column(
              children: [
                _buildRoleCard(
                  theme: theme,
                  roleId: 'household',
                  title: 'Household / Learner',
                  subtitle: 'Explore botanical catalog, remedies, and wellness remedies',
                  icon: Icons.local_florist_rounded,
                ),
                const SizedBox(height: 10),
                _buildRoleCard(
                  theme: theme,
                  roleId: 'practitioner',
                  title: 'Traditional Practitioner',
                  subtitle: 'Offer consultations, share formulations & verify treatments',
                  icon: Icons.medical_services_outlined,
                ),
                const SizedBox(height: 10),
                _buildRoleCard(
                  theme: theme,
                  roleId: 'supplier',
                  title: 'Botanical Supplier / Vendor',
                  subtitle: 'Supply authentic packaged herbs, oils, and remedies to store',
                  icon: Icons.storefront_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Health Interests
          Text(
            'Health Interests (Select topics to personalize)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _availableHealthInterests.map((interest) {
              final isSelected = _selectedHealthInterests.contains(interest);
              return FilterChip(
                label: Text(interest),
                selected: isSelected,
                selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                checkmarkColor: theme.colorScheme.primary,
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.grey.shade800,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedHealthInterests.add(interest);
                    } else {
                      _selectedHealthInterests.remove(interest);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Short Bio
          TextFormField(
            controller: _bioController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Short Bio (Optional)',
              hintText: 'Share a brief introduction or herbal background...',
              prefixIcon: const Icon(Icons.description_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required ThemeData theme,
    required String roleId,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == roleId;
    final primary = theme.colorScheme.primary;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedRole = roleId;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? primary.withValues(alpha: 0.05) : Colors.white,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: isSelected
                  ? primary
                  : Colors.grey.shade100,
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSelected ? primary : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: roleId,
              activeColor: primary,
            ),
          ],
        ),
      ),
    );
  }

  // ================= STEP 4: ACCREDITATION APPLICATION =================
  Widget _buildStep4Accreditation(ThemeData theme) {
    final isPractitioner = _selectedRole == 'practitioner';

    return Form(
      key: _step4Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPractitioner
                    ? Icons.verified_user_outlined
                    : Icons.storefront_rounded,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                isPractitioner
                    ? 'Practitioner Verification'
                    : 'Supplier Registration',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isPractitioner
                        ? 'Your submission will be queued in the Moderation Hub for administrator verification. You can also update details from your Profile anytime.'
                        : 'Your supplier application will be queued for administrator review. Once approved and verified, your business profile and products will be published in the Marketplace.',
                    style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (isPractitioner) ...[
            TextFormField(
              controller: _specialisationController,
              decoration: InputDecoration(
                labelText: 'Specialisation *',
                hintText: 'e.g. Traditional Herbalist, Naturopath',
                prefixIcon: const Icon(Icons.school_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please specify your herbal specialisation';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _yearsExperienceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Years of Experience *',
                hintText: 'e.g. 5',
                prefixIcon: const Icon(Icons.history_edu_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter years of practice';
                }
                final num = int.tryParse(val.trim());
                if (num == null || num < 0 || num > 75) {
                  return 'Please enter a valid number of years';
                }
                return null;
              },
            ),
          ] else ...[
            TextFormField(
              controller: _businessNameController,
              decoration: InputDecoration(
                labelText: 'Business / Enterprise Name *',
                hintText: 'e.g. Baobab Herbal Collective',
                prefixIcon: const Icon(Icons.storefront_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter your business or store name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _supplierCategoryController,
              decoration: InputDecoration(
                labelText: 'Herbal Categories / Products Supplied *',
                hintText: 'e.g. Raw Herbs, Herbal Teas, Essential Oils, Powders',
                prefixIcon: const Icon(Icons.category_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please specify the herbal products you supply';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _supplierYearsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Years in Business / Operation *',
                hintText: 'e.g. 3',
                prefixIcon: const Icon(Icons.history_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter years in business';
                }
                final num = int.tryParse(val.trim());
                if (num == null || num < 0 || num > 75) {
                  return 'Please enter a valid number of years';
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  // ================= NAVIGATION ROW =================
  Widget _buildNavigationRow(ThemeData theme) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Row(
          children: [
            if (_currentStep > 0)
              OutlinedButton.icon(
                onPressed: isLoading ? null : _prevStep,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: isLoading ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _currentStep == _totalSteps - 1
                            ? 'Complete Registration'
                            : 'Continue',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}
