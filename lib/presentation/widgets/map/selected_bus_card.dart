import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/line.dart';
import '../common/app_button.dart';
import '../common/info_row.dart';
import 'stop_arrival_banner.dart';

/// Card do ônibus selecionado no mapa do passageiro: linha, tempo até o
/// passageiro, aviso de embarque quando o ônibus está em um ponto e atalho
/// para os detalhes da linha.
class SelectedBusCard extends StatelessWidget {
  /// Cria o card do ônibus selecionado.
  const SelectedBusCard({
    required this.line,
    required this.onClose,
    required this.onOpenDetails,
    super.key,
    this.etaMinutes,
    this.stopName,
  });

  /// Linha do ônibus.
  final Line line;

  /// Estimativa de chegada até o passageiro (nula sem GPS do passageiro).
  final int? etaMinutes;

  /// Ponto em que o ônibus está agora (nulo se estiver em movimento).
  final String? stopName;

  /// Fecha o card e volta para a lista de ônibus próximos.
  final VoidCallback onClose;

  /// Abre a tela de detalhes da linha.
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colorFromHex(line.color),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    line.displayName,
                    style: AppTextStyles.title,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Fechar',
                  onPressed: onClose,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(line.description, style: AppTextStyles.caption),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: stopName != null
                  ? StopArrivalBanner(stopName: stopName!)
                  : InfoRow(
                      icon: Icons.access_time,
                      label: 'Chega até você em:',
                      value: etaMinutes == null
                          ? '—'
                          : Formatters.durationMinutes(etaMinutes!),
                    ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Ver detalhes da linha',
                  onPressed: onOpenDetails,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
