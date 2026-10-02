import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Aviso exibido sobre o mapa quando o ônibus está em um ponto de parada:
/// informa o nome do ponto e que o embarque e o desembarque estão
/// liberados.
class StopArrivalBanner extends StatelessWidget {
  /// Cria o aviso para a parada [stopName].
  const StopArrivalBanner({required this.stopName, super.key});

  /// Nome do ponto em que o ônibus está.
  final String stopName;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kSuccessColor,
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.transfer_within_a_station, color: Colors.white),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'No ponto: $stopName',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const Text(
                    'Embarque e desembarque liberados',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
