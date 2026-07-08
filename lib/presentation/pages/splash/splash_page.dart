import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user.dart';
import '../../providers/auth_providers.dart';
import '../../routes/app_router.dart';
import '../../routes/app_routes.dart';
import '../../widgets/common/app_logo.dart';

/// Tela inicial: verifica a sessão (RF20) e redireciona por perfil
/// (RF03) — Login, Home do Passageiro ou Home do Motorista.
class SplashPage extends ConsumerWidget {
  /// Cria a tela de splash.
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<User?>>(currentUserProfileProvider,
        (AsyncValue<User?>? previous, AsyncValue<User?> next) {
      next.when(
        loading: () {},
        error: (Object error, StackTrace stackTrace) {
          _goTo(context, kLoginRoute);
        },
        data: (User? user) {
          _goTo(
            context,
            user == null ? kLoginRoute : homeRouteForRole(user.role),
          );
        },
      );
    });

    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AppLogo(fontSize: 44),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  void _goTo(BuildContext context, String route) {
    Navigator.of(context)
        .pushNamedAndRemoveUntil(route, (Route<dynamic> _) => false);
  }
}
