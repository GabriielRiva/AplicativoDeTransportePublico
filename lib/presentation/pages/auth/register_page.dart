import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/enums/user_role.dart';
import '../../../domain/entities/user.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/app_router.dart';
import '../../widgets/auth/profile_selector.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/password_field.dart';

/// Tela de cadastro (RF01) com seleção de perfil e campo de CNH
/// exclusivo do motorista (wireframes das Figuras 4 e 5 do TCC).
class RegisterPage extends ConsumerStatefulWidget {
  /// Cria a tela de cadastro.
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final TextEditingController _cnhController = TextEditingController();

  UserRole _selectedRole = UserRole.passenger;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _cnhController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final User? user =
        await ref.read(authControllerProvider.notifier).register(
              name: _nameController.text,
              email: _emailController.text,
              password: _passwordController.text,
              role: _selectedRole,
              cnh: _selectedRole == UserRole.driver
                  ? _cnhController.text
                  : null,
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
    final bool isDriver = _selectedRole == UserRole.driver;

    return Scaffold(
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
                  const SizedBox(height: 8),
                  const Text('Crie sua conta', style: AppTextStyles.title),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Selecione seu Perfil',
                      style: AppTextStyles.body,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ProfileSelector(
                    selected: _selectedRole,
                    onChanged: (UserRole role) =>
                        setState(() => _selectedRole = role),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _nameController,
                    hint: 'Nome Completo',
                    icon: Icons.person_outline,
                    validator: Validators.fullName,
                  ),
                  const SizedBox(height: 16),
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
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  PasswordField(
                    controller: _confirmController,
                    hint: 'Confirmar Senha',
                    validator: (String? value) => Validators.confirmPassword(
                      value,
                      _passwordController.text,
                    ),
                    textInputAction:
                        isDriver ? TextInputAction.next : TextInputAction.done,
                  ),
                  if (isDriver) ...<Widget>[
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _cnhController,
                      hint: 'Número da CNH',
                      icon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      validator: Validators.cnh,
                    ),
                  ],
                  const SizedBox(height: 24),
                  AppButton(label: 'Cadastrar', onPressed: _submit),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Já possui conta? Fazer Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
