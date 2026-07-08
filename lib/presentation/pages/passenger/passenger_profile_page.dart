import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/user.dart';
import '../../controllers/profile_controller.dart';
import '../../routes/app_routes.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/empty_state.dart';

/// Tela de perfil do passageiro com dados da conta e logout
/// (RF15/RF16).
class PassengerProfilePage extends ConsumerWidget {
  /// Cria a tela de perfil do passageiro.
  const PassengerProfilePage({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final bool success =
        await ref.read(profileControllerProvider.notifier).logout();
    if (success && context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        kLoginRoute,
        (Route<dynamic> _) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<User?>>(profileControllerProvider,
        (AsyncValue<User?>? previous, AsyncValue<User?> next) {
      if (next.hasError && !next.isLoading) {
        AppSnackbar.showError(
          context,
          ErrorHandler.getUserMessage(next.error!),
        );
      }
    });

    final AsyncValue<User?> profileAsync =
        ref.watch(profileControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stackTrace) => EmptyState(
          icon: Icons.error_outline,
          title: 'Não foi possível carregar o perfil',
          message: ErrorHandler.getUserMessage(error),
        ),
        data: (User? user) {
          if (user == null) {
            return const EmptyState(
              icon: Icons.person_off_outlined,
              title: 'Sessão encerrada',
              message: 'Faça login novamente para acessar seu perfil.',
            );
          }
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: <Widget>[
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: kPrimaryColor,
                  child: Icon(Icons.person, size: 48, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(user.name, style: AppTextStyles.headline),
                Text(user.email, style: AppTextStyles.caption),
                const SizedBox(height: 8),
                Chip(label: Text(user.role.label)),
                const Spacer(),
                AppButton(
                  label: 'Sair da Conta',
                  color: kErrorColor,
                  onPressed: () => _logout(context, ref),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
