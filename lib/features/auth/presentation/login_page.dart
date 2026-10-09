import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/core/components/app_error_view.dart';
import 'package:zim_herbs_repo/core/connection/bloc/connection_bloc.dart' as conn;
import 'package:zim_herbs_repo/core/errors/error_handler.dart';
import 'package:zim_herbs_repo/core/errors/failure.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_cubit.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_state.dart';

enum LoginPortalRole {
  customer,
  admin,
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  LoginPortalRole _selectedRole = LoginPortalRole.customer;
  bool _isSignUpMode = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  Failure? _activeFailure;

  static final RegExp _emailRegExp = RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
  );

  @override
  void initState() {
    super.initState();
    final currentAuthState = context.read<AuthCubit>().state;
    if (currentAuthState is AuthError) {
      _activeFailure = currentAuthState.failure ??
          ErrorHandler.handle(currentAuthState.message);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_activeFailure != null) {
      setState(() {
        _activeFailure = null;
      });
      context.read<AuthCubit>().clearError();
    }
  }

  conn.ConnectionBloc? _maybeGetConnectionBloc(BuildContext context) {
    try {
      return context.read<conn.ConnectionBloc>();
    } catch (_) {
      return null;
    }
  }

  void _onSubmit() {
    FocusScope.of(context).unfocus();

    // Check if offline before attempting network call
    final connBloc = _maybeGetConnectionBloc(context);
    if (connBloc != null &&
        connBloc.state.status == conn.ConnectionStatus.offline) {
      const failure = Failure(
        title: 'Login Unsuccessful',
        message:
            'You are currently offline. Please connect to Wi-Fi or mobile data to authenticate.',
        type: FailureType.noInternet,
      );
      setState(() {
        _activeFailure = failure;
      });
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _activeFailure = null;
      });
      if (_isSignUpMode && _selectedRole == LoginPortalRole.customer) {
        context.read<AuthCubit>().signUpWithCredentials(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              fullName: _nameController.text.trim(),
            );
      } else {
        context.read<AuthCubit>().signInWithCredentials(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              requireAdmin: _selectedRole == LoginPortalRole.admin,
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCustomer = _selectedRole == LoginPortalRole.customer;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isSmallScreen = screenWidth < 380;
    final cardPadding = isSmallScreen ? 16.0 : 28.0;
    final horizontalPadding = isSmallScreen ? 12.0 : 24.0;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            final failure = state.failure ?? ErrorHandler.handle(state.message);
            setState(() {
              _activeFailure = failure;
            });
          } else if (state is Authenticated || state is AuthLoading) {
            if (_activeFailure != null) {
              setState(() {
                _activeFailure = null;
              });
            }
          }
        },
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                elevation: 8,
                shadowColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: EdgeInsets.all(cardPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Role Selector Segmented Toggle: Customer vs Admin
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedRole = LoginPortalRole.customer;
                                    _activeFailure = null;
                                  });
                                  context.read<AuthCubit>().clearError();
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: isCustomer
                                        ? Colors.green.shade700
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.school_rounded,
                                        size: 16,
                                        color: isCustomer
                                            ? Colors.white
                                            : Colors.grey.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          isSmallScreen ? "Customer" : "Customer / Learn",
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontWeight: isCustomer
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            fontSize: isSmallScreen ? 12 : 13,
                                            color: isCustomer
                                                ? Colors.white
                                                : Colors.grey.shade800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedRole = LoginPortalRole.admin;
                                    _isSignUpMode = false;
                                    _activeFailure = null;
                                  });
                                  context.read<AuthCubit>().clearError();
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: !isCustomer
                                        ? theme.colorScheme.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.admin_panel_settings_rounded,
                                        size: 16,
                                        color: !isCustomer
                                            ? Colors.white
                                            : Colors.grey.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          isSmallScreen ? "Admin" : "Admin Console",
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontWeight: !isCustomer
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            fontSize: isSmallScreen ? 12 : 13,
                                            color: !isCustomer
                                                ? Colors.white
                                                : Colors.grey.shade800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Header Icon & Title
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isCustomer
                                ? Colors.green.shade50
                                : theme.colorScheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCustomer
                                ? Icons.grass_rounded
                                : Icons.admin_panel_settings_rounded,
                            size: 36,
                            color: isCustomer
                                ? Colors.green.shade800
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isCustomer ? 'Zim Herbs Learning' : 'Zim Herbs Admin',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isCustomer
                              ? Colors.green.shade900
                              : theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isCustomer
                            ? (_isSignUpMode
                                ? 'Create an account to explore traditional herbs & remedies'
                                : 'Sign in to explore traditional herbs, remedies & treatments')
                            : 'Sign in with your administrator credentials',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Sign In vs Sign Up toggle (only in customer mode)
                      if (isCustomer)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              ChoiceChip(
                                label: const Text("Sign In"),
                                selected: !_isSignUpMode,
                                onSelected: (sel) {
                                  if (sel) {
                                    setState(() {
                                      _isSignUpMode = false;
                                      _activeFailure = null;
                                    });
                                    context.read<AuthCubit>().clearError();
                                  }
                                },
                              ),
                              ChoiceChip(
                                label: const Text("Create Account"),
                                selected: _isSignUpMode,
                                onSelected: (sel) {
                                  if (sel) {
                                    setState(() {
                                      _isSignUpMode = true;
                                      _activeFailure = null;
                                    });
                                    context.read<AuthCubit>().clearError();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),

                      // Offline Connection Warning Banner (reactive to network status)
                      Builder(
                        builder: (context) {
                          conn.ConnectionStatus? status;
                          try {
                            status = context
                                .watch<conn.ConnectionBloc>()
                                .state
                                .status;
                          } catch (_) {
                            status = null;
                          }
                          if (status == conn.ConnectionStatus.offline) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFFDE68A),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.wifi_off_rounded,
                                    size: 16,
                                    color: Colors.amber.shade900,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'You appear to be offline. Internet connection is required to authenticate.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.amber.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                      // Form
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            if (isCustomer && _isSignUpMode) ...[
                              TextFormField(
                                controller: _nameController,
                                textCapitalization: TextCapitalization.words,
                                onChanged: (_) => _clearError(),
                                decoration: InputDecoration(
                                  labelText: 'Full Name',
                                  hintText: 'John Doe',
                                  prefixIcon: const Icon(Icons.person_outline),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator: (val) {
                                  final name = val?.trim() ?? '';
                                  if (name.isEmpty) {
                                    return 'Please enter your full name';
                                  }
                                  if (name.length < 2) {
                                    return 'Full name must be at least 2 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (_) => _clearError(),
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                hintText: isCustomer
                                    ? 'user@example.com'
                                    : 'admin@example.com',
                                prefixIcon: const Icon(Icons.email_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (val) {
                                final email = val?.trim() ?? '';
                                if (email.isEmpty) {
                                  return 'Please enter your email address';
                                }
                                if (!_emailRegExp.hasMatch(email)) {
                                  return 'Please enter a valid email address (e.g. name@example.com)';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              onChanged: (_) => _clearError(),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (val.length < 6) {
                                  return 'Password must be at least 6 characters long';
                                }
                                return null;
                              },
                            ),
                            if (isCustomer && _isSignUpMode) ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                onChanged: (_) => _clearError(),
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  prefixIcon: const Icon(Icons.lock_reset_outlined),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Please confirm your password';
                                  }
                                  if (val != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                            ],
                            if (_activeFailure != null) ...[
                              const SizedBox(height: 16),
                              AppErrorView.banner(
                                failure: _activeFailure,
                                onDismiss: () => setState(() => _activeFailure = null),
                                actionLabel: _activeFailure!.type ==
                                        FailureType.userAlreadyExists
                                    ? 'Switch to Sign In'
                                    : _activeFailure!.type == FailureType.accessDenied
                                        ? 'Switch to Customer'
                                        : (_activeFailure!.isNetworkError ||
                                                _activeFailure!.isServerError)
                                            ? 'Try Again'
                                            : null,
                                onAction: _activeFailure!.type ==
                                        FailureType.userAlreadyExists
                                    ? () {
                                        setState(() {
                                          _isSignUpMode = false;
                                          _activeFailure = null;
                                        });
                                        context.read<AuthCubit>().clearError();
                                      }
                                    : _activeFailure!.type ==
                                            FailureType.accessDenied
                                        ? () {
                                            setState(() {
                                              _selectedRole =
                                                  LoginPortalRole.customer;
                                              _activeFailure = null;
                                            });
                                            context.read<AuthCubit>().clearError();
                                          }
                                        : (_activeFailure!.isNetworkError ||
                                                _activeFailure!.isServerError)
                                            ? _onSubmit
                                            : null,
                              ),
                            ],
                            const SizedBox(height: 20),

                            BlocBuilder<AuthCubit, AuthState>(
                              builder: (context, state) {
                                final isLoading = state is AuthLoading;
                                final btnColor = isCustomer
                                    ? Colors.green.shade700
                                    : theme.colorScheme.primary;

                                return SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : _onSubmit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: btnColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
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
                                            isCustomer && _isSignUpMode
                                                ? 'Create Account'
                                                : (isCustomer
                                                    ? 'Sign In as Learner'
                                                    : 'Sign In as Administrator'),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
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
}
