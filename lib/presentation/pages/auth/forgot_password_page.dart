import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/user.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/auth/auth_error_banner.dart';
import '../../widgets/auth/auth_layout.dart';
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

  /// Erro da última tentativa, exibido dentro do card (ver
  /// [AuthErrorBanner]). Limpo ao tentar de novo ou ao fechar a faixa.
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Fecha o teclado para o card (e a faixa de erro) ficar todo visível.
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
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
        setState(() => _error = next.error.toString());
      }
    });

    final bool isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      // A foto ocupa a tela inteira, por trás da barra com o botão voltar.
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: kTextPrimaryColor,
      ),
      body: LoadingOverlay(
        isLoading: isLoading,
        child: AuthLayout(
          header: const Column(
            children: <Widget>[
              SizedBox(height: 24),
              AppLogo(fontSize: 40),
            ],
          ),
          card: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                const Text('Recuperar senha', style: AppTextStyles.title),
                const SizedBox(height: 8),
                const Text(
                  'Informe seu e-mail cadastrado para receber o link '
                  'de redefinição de senha.',
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _emailController,
                  hint: 'E-mail',
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  validator: Validators.email,
                ),
                AuthErrorBanner(
                  message: _error,
                  onClose: () => setState(() => _error = null),
                ),
                const SizedBox(height: 24),
                AppButton(label: 'Enviar', onPressed: _submit),
                const SizedBox(height: 12),
              ],
            ),
          ),
          footer: AuthFooterLink(
            question: 'Lembrou a senha?',
            action: 'Voltar ao login',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}
