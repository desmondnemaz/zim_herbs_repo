import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_cubit.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_state.dart';
import 'package:zim_herbs_repo/features/auth/presentation/login_page.dart';
import 'package:zim_herbs_repo/features/auth/presentation/portal_selection_page.dart';
import 'package:zim_herbs_repo/features/dashboard/presentation/home_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading || state is AuthInitial) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  const Text('Initializing Zim Herbs Admin...'),
                ],
              ),
            ),
          );
        }

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
