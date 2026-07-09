import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../common/info_row.dart';

/// Card de informações do trajeto ativo exibido sobre o mapa
/// (wireframe da tela de Trajeto).
class BusInfoCard extends StatelessWidget {
  /// Cria o card com o [title] da linha e as informações do trajeto.
  const BusInfoCard({
    required this.title,
    required this.subtitle,
    super.key,
    this.estimatedTime,
    this.nextStop,
    this.action,
  });

  /// Nome da linha (ex.: "L101 - Centro/Ecoparque").
  final String title;

  /// Identificação do ônibus (ex.: "Ônibus: #1430").
  final String subtitle;

  /// Tempo estimado exibido (ex.: "15 min").
  final String? estimatedTime;

  /// Próximo ponto de parada.
  final String? nextStop;

  /// Ação opcional (ex.: botão Encerrar Trajeto).
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(title, style: AppTextStyles.title),
            Text(subtitle, style: AppTextStyles.caption),
            const SizedBox(height: 12),
            if (estimatedTime != null)
              InfoRow(
                icon: Icons.access_time,
                label: 'Tempo Estimado:',
                value: estimatedTime!,
              ),
            if (nextStop != null)
              InfoRow(
                icon: Icons.location_on_outlined,
                label: 'Próximo Ponto:',
                value: nextStop!,
              ),
            if (action != null) ...<Widget>[
              const SizedBox(height: 12),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}