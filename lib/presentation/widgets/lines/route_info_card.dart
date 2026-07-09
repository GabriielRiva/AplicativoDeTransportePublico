import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/line.dart';
import '../common/info_row.dart';

/// Painel "Rota Detalhada" da tela de Linhas e Trajetos (RF09).
class RouteInfoCard extends StatelessWidget {
  /// Cria o painel com os dados da [line] e a [stopsCount] da rota.
  const RouteInfoCard({
    required this.line,
    required this.stopsCount,
    super.key,
  });

  /// Linha selecionada.
  final Line line;

  /// Quantidade de pontos de parada da rota.
  final int stopsCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Rota Detalhada\n${line.displayName}',
              style: AppTextStyles.title,
            ),
            const SizedBox(height: 12),
            InfoRow(
              icon: Icons.map_outlined,
              label: 'Trajetos:',
              value: line.description,
            ),
            InfoRow(
              icon: Icons.route_outlined,
              label: 'Distância Total:',
              value: Formatters.distanceKm(line.distance),
            ),
            InfoRow(
              icon: Icons.directions_bus_outlined,
              label: 'Quantidade de Pontos:',
              value: '$stopsCount',
            ),
            InfoRow(
              icon: Icons.access_time,
              label: 'Tempo Médio:',
              value: Formatters.durationMinutes(line.averageDuration),
            ),
          ],
        ),
      ),
    );
  }
}