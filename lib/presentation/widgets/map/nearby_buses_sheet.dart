import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/usecases/passenger/get_nearby_buses.dart';

/// Painel "Ônibus próximos" da tela inicial do passageiro (RF13).
class NearbyBusesSheet extends StatelessWidget {
  /// Cria o painel com a lista de [buses] próximos.
  const NearbyBusesSheet({required this.buses, super.key});

  /// Ônibus próximos ordenados pela distância.
  final List<NearbyBus> buses;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Ônibus próximos', style: AppTextStyles.title),
            const SizedBox(height: 8),
            if (buses.isEmpty)
              const Text(
                'Nenhum ônibus em circulação no momento.',
                style: AppTextStyles.caption,
              )
            else
              ...buses.map(
                (NearbyBus bus) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          bus.line.displayName,
                          style: AppTextStyles.body,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        Formatters.durationMinutes(bus.etaMinutes),
                        style: AppTextStyles.title,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
