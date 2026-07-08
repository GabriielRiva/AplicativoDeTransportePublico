import 'package:flutter/material.dart';

/// Sobreposição de carregamento exibida sobre qualquer tela
/// (PROJECT_RULES: toda tela deve possuir Loading).
class LoadingOverlay extends StatelessWidget {
  /// Envolve [child] e exibe o indicador quando [isLoading] é true.
  const LoadingOverlay({
    required this.isLoading,
    required this.child,
    super.key,
  });

  /// Indica se o carregamento está ativo.
  final bool isLoading;

  /// Conteúdo da tela.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        child,
        if (isLoading) ...<Widget>[
          const Opacity(
            opacity: 0.4,
            child: ModalBarrier(dismissible: false, color: Colors.black),
          ),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }
}
