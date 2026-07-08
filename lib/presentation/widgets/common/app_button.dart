import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';

/// Botão padrão do aplicativo com suporte a estado de carregamento.
class AppButton extends StatelessWidget {
  /// Cria o botão com [label] e ação [onPressed].
  const AppButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.color,
    this.isLoading = false,
    this.enabled = true,
  });

  /// Texto exibido no botão.
  final String label;

  /// Ação executada ao tocar (ignorada durante o carregamento).
  final VoidCallback onPressed;

  /// Cor de fundo (usa a cor primária do tema quando nula).
  final Color? color;

  /// Exibe um indicador de progresso no lugar do texto.
  final bool isLoading;

  /// Habilita ou desabilita o botão.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: color == null
          ? null
          : ElevatedButton.styleFrom(backgroundColor: color),
      onPressed: (isLoading || !enabled) ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : Text(label, style: AppTextStyles.button),
    );
  }
}
