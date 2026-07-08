import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/user.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/loading_overlay.dart';

/// Tela de recuperação de senha por e-mail (RF17).
class ForgotPasswordPage extends ConsumerStatefulWidget {
  /// Cria a tela de recuperação de senha.
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final bool success = await ref
        .read(authControllerProvider.notifier)
        .recoverPassword(_emailController.text);

    if (success && mounted) {
      AppSnackbar.showSuccess(
        context,
        'E-mail de recuperação enviado. Verifique sua caixa de entrada.',
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<User?>>(authControllerProvider,
        (AsyncValue<User?>? previous, AsyncValue<User?> next) {
      if (next.hasError && !next.isLoading) {
        AppSnackbar.showError(context, next.error.toString());
      }
    });

    final bool isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar Senha')),
      body: LoadingOverlay(
        isLoading: isLoading,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  const AppLogo(),
                  const SizedBox(height: 16),
                  const Text(
                    'Informe seu e-mail cadastrado para receber o link '
                    'de redefinição de senha.',
                    style: AppTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  AppTextField(
                    controller: _emailController,
                    hint: 'E-mail',
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 24),
                  AppButton(label: 'Enviar', onPressed: _submit),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
