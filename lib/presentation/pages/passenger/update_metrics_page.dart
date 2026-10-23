import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/interval_stats.dart';
import '../../../domain/entities/line.dart';
import '../../controllers/update_metrics_controller.dart';
import '../../providers/line_providers.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/info_row.dart';

/// Tela de medição do intervalo de atualização da posição dos ônibus
/// (RNF05: no máximo 5 segundos), usada no teste do protótipo.
class UpdateMetricsPage extends ConsumerWidget {
  /// Cria a tela de medição.
  const UpdateMetricsPage({super.key});

  static String _seconds(num ms) =>
      '${(ms / 1000).toStringAsFixed(2).replaceAll('.', ',')} s';

  static String _percent(double value) =>
      '${value.toStringAsFixed(1).replaceAll('.', ',')}%';

  static String _time(DateTime time) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
  }

  Future<void> _copyCsv(BuildContext context, WidgetRef ref) async {
    final String csv = ref.read(updateMetricsProvider.notifier).toCsv();
    await Clipboard.setData(ClipboardData(text: csv));
    if (context.mounted) {
      AppSnackbar.showSuccess(
        context,
        'Dados copiados. Cole em uma planilha para o TCC.',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UpdateMetricsState state = ref.watch(updateMetricsProvider);
    final List<Line> lines = ref.watch(linesProvider).valueOrNull ?? <Line>[];
    final Map<String, String> lineNames = <String, String>{
      for (final Line line in lines) line.id: line.displayName,
    };

    final List<UpdateSample> samples = state.samples;
    final IntervalStats sent = IntervalStats.of(
      samples.map((UpdateSample s) => s.serverIntervalMs).toList(),
    );
    final IntervalStats received = IntervalStats.of(
      samples.map((UpdateSample s) => s.receiveIntervalMs).toList(),
    );
    final IntervalStats latency = IntervalStats.of(
      samples
          .map((UpdateSample s) => s.latencyMs < 0 ? 0 : s.latencyMs)
          .toList(),
    );

    final Map<String, List<UpdateSample>> byLine =
        <String, List<UpdateSample>>{};
    for (final UpdateSample sample in samples) {
      byLine.putIfAbsent(sample.lineId, () => <UpdateSample>[]).add(sample);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Medição de atualização')),
      // Os botões ficam fixos embaixo, fora da lista: em telas pequenas eles
      // ficavam no fim da rolagem, às vezes atrás da barra de navegação do
      // Android, e não dava para tocar neles.
      bottomNavigationBar: _MetricsActions(
        onCopy: samples.isEmpty ? null : () => _copyCsv(context, ref),
        onReset: ref.read(updateMetricsProvider.notifier).reset,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const Text(
            'Mede de quanto em quanto tempo chegam posições novas dos ônibus '
            'em circulação (RNF05: no máximo 5 segundos). A medição roda '
            'enquanto o app do passageiro está aberto.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 12),
          _ResultBanner(stats: sent),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Envio (motorista → servidor)',
                    style: AppTextStyles.title,
                  ),
                  const SizedBox(height: 8),
                  InfoRow(
                    icon: Icons.numbers,
                    label: 'Amostras:',
                    value: '${sent.count}',
                  ),
                  InfoRow(
                    icon: Icons.timer_outlined,
                    label: 'Intervalo médio:',
                    value: _seconds(sent.meanMs),
                  ),
                  InfoRow(
                    icon: Icons.arrow_upward,
                    label: 'Maior intervalo:',
                    value: _seconds(sent.maxMs),
                  ),
                  InfoRow(
                    icon: Icons.insights_outlined,
                    label: '95% dos intervalos até:',
                    value: _seconds(sent.p95Ms),
                  ),
                  InfoRow(
                    icon: Icons.check_circle_outline,
                    label: 'Dentro de 5 s:',
                    value: _percent(sent.withinLimitPercent),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Recebimento (passageiro)',
                    style: AppTextStyles.title,
                  ),
                  const SizedBox(height: 8),
                  InfoRow(
                    icon: Icons.timer_outlined,
                    label: 'Intervalo médio:',
                    value: _seconds(received.meanMs),
                  ),
                  InfoRow(
                    icon: Icons.arrow_upward,
                    label: 'Maior intervalo:',
                    value: _seconds(received.maxMs),
                  ),
                  InfoRow(
                    icon: Icons.speed,
                    label: 'Atraso médio de entrega:',
                    value: _seconds(latency.meanMs),
                  ),
                  InfoRow(
                    icon: Icons.schedule,
                    label: 'Medindo desde:',
                    value: _time(state.startedAt),
                  ),
                ],
              ),
            ),
          ),
          if (byLine.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            const Text('Por linha', style: AppTextStyles.title),
            const SizedBox(height: 4),
            ...byLine.entries.map((MapEntry<String, List<UpdateSample>> e) {
              final IntervalStats stats = IntervalStats.of(
                e.value.map((UpdateSample s) => s.serverIntervalMs).toList(),
              );
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.directions_bus_outlined),
                  title: Text(lineNames[e.key] ?? e.key),
                  subtitle: Text(
                    '${stats.count} amostras · média '
                    '${_seconds(stats.meanMs)} · máx. '
                    '${_seconds(stats.maxMs)}',
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

/// Botões "Copiar dados" e "Zerar", fixos no rodapé da tela e acima da
/// barra de navegação do Android, visíveis em qualquer tamanho de tela.
class _MetricsActions extends StatelessWidget {
  const _MetricsActions({required this.onCopy, required this.onReset});

  /// Copia as amostras em CSV (nulo enquanto não há amostras).
  final VoidCallback? onCopy;

  /// Zera a medição.
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kSurfaceColor,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Copiar dados'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.restart_alt),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Zerar'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Faixa com o resultado do RNF05 para o intervalo de envio.
class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.stats});

  final IntervalStats stats;

  @override
  Widget build(BuildContext context) {
    final bool hasData = stats.count > 0;
    final bool ok = stats.allWithinLimit;
    final Color color = !hasData
        ? kTextSecondaryColor
        : ok
            ? kSuccessColor
            : const Color(0xFFB45309);
    final String percent =
        stats.withinLimitPercent.toStringAsFixed(1).replaceAll('.', ',');
    final String text = !hasData
        ? 'Aguardando posições dos ônibus em circulação…'
        : ok
            ? 'RNF05 atendido: todas as posições chegaram em até 5 s.'
            : 'RNF05 atendido em $percent% das posições. Intervalos '
                'maiores costumam ser perda de sinal ou app em segundo '
                'plano.';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            !hasData
                ? Icons.hourglass_empty
                : ok
                    ? Icons.verified_outlined
                    : Icons.info_outline,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}
