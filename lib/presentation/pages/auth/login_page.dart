import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/validators.dart';
import '../../../domain/entities/user.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/app_router.dart';
import '../../routes/app_routes.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/password_field.dart';

/// Tela de login (RF02) com acesso a cadastro e recuperação de senha.
class LoginPage extends ConsumerStatefulWidget {
  /// Cria a tela de login.
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final User? user = await ref.read(authControllerProvider.notifier).login(
          email: _emailController.text,
          password: _passwordController.text,
        );

    if (user != null && mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        homeRouteForRole(user.role),
        (Route<dynamic> _) => false,
      );
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
      body: LoadingOverlay(
        isLoading: isLoading,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    const AppLogo(),
                    const SizedBox(height: 48),
                    AppTextField(
                      controller: _emailController,
                      hint: 'E-mail',
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),
                    PasswordField(
                      controller: _passwordController,
                      validator: Validators.password,
                    ),
                    const SizedBox(height: 24),
                    AppButton(label: 'Entrar', onPressed: _submit),
                    TextButton(
                      onPressed: () => Navigator.of(context)
                          .pushNamed(kForgotPasswordRoute),
                      child: const Text('Esqueci minha senha'),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).pushNamed(kRegisterRoute),
                      child: const Text('Criar Conta'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
