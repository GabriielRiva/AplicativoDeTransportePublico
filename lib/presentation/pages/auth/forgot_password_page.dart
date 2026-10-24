import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/password_reset_cooldown.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/user.dart';
import '../../controllers/auth_controller.dart';
import '../../providers/service_providers.dart';
import '../../widgets/auth/auth_error_banner.dart';
import '../../widgets/auth/auth_layout.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/loading_overlay.dart';

/// Tela de recuperação de senha por e-mail (RF17).
///
/// Depois de um envio, o botão fica bloqueado por [kPasswordResetCooldown]
/// com uma contagem regressiva (ver [PasswordResetCooldown]), para evitar
/// vários e-mails com links diferentes e pedidos repetidos ao servidor.
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

  /// E-mail para o qual o link foi enviado nesta tela (nulo antes do envio).
  String? _sentTo;

  /// Tempo que falta para poder pedir outro e-mail.
  Duration _wait = Duration.zero;
  DateTime? _waitEndsAt;
  Timer? _ticker;

  /// Impede dois pedidos ao mesmo tempo (toques repetidos no botão).
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Se um e-mail foi pedido há pouco (mesmo antes de fechar a tela ou o
    // app), a espera continua de onde parou.
    ref
        .read(passwordResetCooldownProvider)
        .remaining()
        .then((Duration left) {
      if (mounted) _startWait(left);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  bool get _waiting => _wait > Duration.zero;

  /// Inicia a contagem regressiva de [duration] até liberar o reenvio.
  void _startWait(Duration duration) {
    _ticker?.cancel();
    if (duration <= Duration.zero) {
      setState(() => _wait = Duration.zero);
      return;
    }
    _waitEndsAt = DateTime.now().add(duration);
    setState(() => _wait = duration);
    _ticker = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      final Duration left = _waitEndsAt!.difference(DateTime.now());
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (left <= Duration.zero) {
        timer.cancel();
        setState(() => _wait = Duration.zero);
      } else {
        setState(() => _wait = left);
      }
    });
  }

  /// Tempo restante no formato m:ss (ex.: 0:45).
  static String _formatWait(Duration duration) {
    final int seconds = (duration.inMilliseconds / 1000).ceil();
    final String rest = (seconds % 60).toString().padLeft(2, '0');
    return '${seconds ~/ 60}:$rest';
  }

  Future<void> _submit() async {
    // Fecha o teclado para o card (e a faixa de erro) ficar todo visível.
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    if (_sending || _waiting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final PasswordResetCooldown cooldown =
        ref.read(passwordResetCooldownProvider);
    final Duration left = await cooldown.remaining();
    if (!mounted) return;
    if (left > Duration.zero) {
      _startWait(left);
      return;
    }

    _sending = true;
    final String email = _emailController.text.trim();
    final bool success = await ref
        .read(authControllerProvider.notifier)
        .recoverPassword(email);
    _sending = false;

    if (!success || !mounted) return;
    await cooldown.markSent();
    if (!mounted) return;
    setState(() => _sentTo = email);
    _startWait(kPasswordResetCooldown);
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
                if (_sentTo != null) _SentNotice(email: _sentTo!),
                const SizedBox(height: 24),
                AppButton(
                  label: _waiting
                      ? 'Reenviar em ${_formatWait(_wait)}'
                      : _sentTo != null
                          ? 'Reenviar e-mail'
                          : 'Enviar',
                  enabled: !_waiting,
                  onPressed: _submit,
                ),
                if (_waiting && _sentTo == null) ...<Widget>[
                  const SizedBox(height: 8),
                  const Text(
                    'Um e-mail de recuperação foi enviado há pouco. '
                    'Aguarde para pedir outro.',
                    style: AppTextStyles.caption,
                    textAlign: TextAlign.center,
                  ),
                ],
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

/// Confirmação do envio, exibida no card no lugar de fechar a tela: o
/// usuário vê para qual e-mail foi o link e por que o reenvio espera.
class _SentNotice extends StatelessWidget {
  const _SentNotice({required this.email});

  /// E-mail para o qual o link foi enviado.
  final String email;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kSuccessColor.withValues(alpha: 0.10),
          border: Border.all(color: kSuccessColor.withValues(alpha: 0.45)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(Icons.mark_email_read_outlined, color: kSuccessColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Enviamos o link de redefinição para $email. Ele vale por '
                '1 hora. Se não chegar em alguns minutos, confira a caixa '
                'de spam antes de pedir outro.',
                style: AppTextStyles.body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
