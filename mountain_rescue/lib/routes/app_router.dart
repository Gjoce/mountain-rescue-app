import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/login_screen.dart';
import '../features/rescuer/rescuer_home.dart';
import '../features/admin/admin_home.dart';
import '../state/providers/auth_provider.dart';

class AppRouter extends ConsumerWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(firebaseAuthStateProvider);
    final user = ref.watch(currentUserProvider);

    return authState.when(
      data: (firebaseUser) {
        if (firebaseUser == null) return const LoginScreen();
        return user.when(
          data: (appUser) {
            if (appUser == null) return const LoginScreen();
            return appUser.role == 'admin'
                ? const AdminHomeScreen()
                : const RescuerHomeScreen();
          },
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, __) => const LoginScreen(),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const LoginScreen(),
    );
  }
}
