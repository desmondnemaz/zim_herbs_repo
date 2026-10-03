import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/app.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_cubit.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_state.dart';
import 'package:zim_herbs_repo/features/auth/presentation/login_page.dart';
import 'package:zim_herbs_repo/features/auth/presentation/portal_selection_page.dart';
import 'package:zim_herbs_repo/features/dashboard/presentation/home_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isFirstCheck = true;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          previous is! Authenticated && current is Authenticated,
      listener: (context, state) {
        if (state is Authenticated) {
          final messenger = rootScaffoldMessengerKey.currentState ??
              ScaffoldMessenger.maybeOf(context);
          if (messenger != null) {
            messenger.clearSnackBars();
            messenger.showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                backgroundColor: const Color(0xFF15803D), // Emerald-700
                duration: const Duration(seconds: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Login successful! Welcome, ${state.user.name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }
      },
      builder: (context, state) {
        // Only show initial full-screen splash before the first auth check completes
        if (_isFirstCheck && (state is AuthLoading || state is AuthInitial)) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  const Text('Initializing Zim Herbs...'),
                ],
              ),
            ),
          );
        }

        _isFirstCheck = false;

        if (state is Authenticated) {
          if (state.user.role.isAdmin) {
            return PortalSelectionPage(user: state.user);
          } else {
            // General authenticated customer learning experience
            return const HomePage();
          }
        }

        return const LoginPage();
      },
    );
  }
}

