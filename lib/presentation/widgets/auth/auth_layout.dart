import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Foto de fundo das telas de login e cadastro.
const String kAuthBackgroundAsset = 'assets/images/auth_background.jpg';

/// Layout das telas de autenticação: foto de um ônibus na cidade ao fundo,
/// [header] (logo) sobre o céu, o formulário dentro de um card claro e
/// [footer] (link para a outra tela) em branco sobre a rua, embaixo.
///
/// O fundo não se move quando o teclado abre: só o conteúdo rola.
class AuthLayout extends StatelessWidget {
  /// Cria o layout.
  const AuthLayout({
    required this.header,
    required this.card,
    super.key,
    this.footer,
  });

  /// Conteúdo acima do card (logo e subtítulo).
  final Widget header;

  /// Conteúdo do card (formulário).
  final Widget card;

  /// Conteúdo abaixo do card, encostado no fim da tela.
  final Widget? footer;

  /// Azul-escuro do degradê sobre a parte de baixo da foto, para o texto
  /// branco do rodapé ficar legível.
  static const Color _shade = Color(0xFF0B2545);

  @override
  Widget build(BuildContext context) {
    final double keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Image.asset(
          kAuthBackgroundAsset,
          fit: BoxFit.cover,
          // Mantém o ônibus (lado direito da foto) visível em telas
          // estreitas.
          alignment: const Alignment(0.6, 0),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const <double>[0, 0.45, 1],
              colors: <Color>[
                _shade.withAlpha(0),
                _shade.withAlpha(0),
                _shade.withAlpha(160),
              ],
            ),
          ),
        ),
        SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + keyboard),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 48,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Column(
                        children: <Widget>[
                          header,
                          const SizedBox(height: 32),
                          _AuthCard(child: card),
                        ],
                      ),
                      if (footer != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: footer,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Card claro e levemente translúcido que envolve o formulário.
class _AuthCard extends StatelessWidget {
  const _AuthCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      decoration: BoxDecoration(
        color: kBackgroundColor.withAlpha(242),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Link branco do rodapé ("Criar conta", "Fazer login"), legível sobre a
/// parte escura da foto.
class AuthFooterLink extends StatelessWidget {
  /// Cria o link com o texto [question] seguido da ação [action].
  const AuthFooterLink({
    required this.question,
    required this.action,
    required this.onPressed,
    super.key,
  });

  /// Pergunta em texto normal (ex.: "Não tem conta?").
  final String question;

  /// Ação em negrito (ex.: "Criar conta").
  final String action;

  /// Toque no link.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: Colors.white),
      child: Text.rich(
        TextSpan(
          text: '$question ',
          style: const TextStyle(fontSize: 15, color: Colors.white),
          children: <InlineSpan>[
            TextSpan(
              text: action,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
