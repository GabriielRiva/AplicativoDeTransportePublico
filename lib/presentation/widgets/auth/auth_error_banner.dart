import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Faixa de erro exibida dentro do card das telas de autenticação, logo
/// acima do botão principal.
///
/// Substitui o snackbar nessas telas: com o teclado aberto, o snackbar
/// aparecia no rodapé, escondido atrás do teclado, e o usuário não via a
/// mensagem (ex.: "E-mail ou senha incorretos."). Sem [message], não ocupa
/// espaço.
class AuthErrorBanner extends StatelessWidget {
  /// Cria a faixa com a [message] de erro, ou vazia se ela for nula.
  const AuthErrorBanner({
    required this.message,
    required this.onClose,
    super.key,
  });

  /// Mensagem exibida; nula esconde a faixa.
  final String? message;

  /// Chamado ao tocar no botão de fechar.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final String? text = message;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: text == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Semantics(
                liveRegion: true,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                  decoration: BoxDecoration(
                    color: kErrorColor.withValues(alpha: 0.10),
                    border: Border.all(
                      color: kErrorColor.withValues(alpha: 0.45),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.error_outline,
                        color: kErrorColor,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          text,
                          style: const TextStyle(
                            color: kErrorColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onClose,
                        icon: const Icon(Icons.close, size: 18),
                        color: kErrorColor,
                        tooltip: 'Fechar',
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
