import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Indicador de status do GPS da tela do motorista (RF14).
class GpsStatusIndicator extends StatelessWidget {
  /// Cria o indicador conforme o estado de [isTransmitting].
  const GpsStatusIndicator({required this.isTransmitting, super.key});

  /// Indica se a localização está sendo transmitida.
  final bool isTransmitting;

  @override
  Widget build(BuildContext context) {
    final Color color = isTransmitting ? kSuccessColor : kTextSecondaryColor;
    return Row(
      children: <Widget>[
        Icon(
          isTransmitting ? Icons.gps_fixed : Icons.gps_off,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            isTransmitting
                ? 'GPS Ativo: Transmitindo Localização'
                : 'GPS Inativo: Aguardando Trajeto',
            style: AppTextStyles.body.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
