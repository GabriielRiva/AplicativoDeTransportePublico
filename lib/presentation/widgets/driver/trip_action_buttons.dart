import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../common/app_button.dart';

/// Botões Iniciar/Encerrar Trajeto da tela do motorista (RF04/RF05).
class TripActionButtons extends StatelessWidget {
  /// Cria os botões com as ações e habilitações do estado atual.
  const TripActionButtons({
    required this.onStart,
    required this.onFinish,
    required this.canStart,
    required this.canFinish,
    super.key,
  });

  /// Ação do botão Iniciar Trajeto.
  final VoidCallback onStart;

  /// Ação do botão Encerrar Trajeto.
  final VoidCallback onFinish;

  /// Habilita o botão Iniciar.
  final bool canStart;

  /// Habilita o botão Encerrar.
  final bool canFinish;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: AppButton(
            label: 'Iniciar Trajeto',
            color: kSuccessColor,
            enabled: canStart,
            onPressed: onStart,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton(
            label: 'Encerrar Trajeto',
            color: kErrorColor,
            enabled: canFinish,
            onPressed: onFinish,
          ),
        ),
      ],
    );
  }
}
