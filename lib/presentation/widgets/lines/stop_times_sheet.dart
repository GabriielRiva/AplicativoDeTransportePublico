import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/schedule.dart';
import '../../../domain/entities/speed_profile.dart';
import '../../../domain/usecases/passenger/predict_stop_times.dart';

/// Horário previsto de passagem em cada ponto para uma saída da linha
/// (ex.: saída 10:00, ponto 5 às 10:10, ponto 10 às 10:20).
class StopTimesSheet extends StatelessWidget {
  /// Cria a lista com os horários [times] previstos para a saída
  /// [schedule], calculados com o perfil [profile].
  const StopTimesSheet({
    required this.schedule,
    required this.times,
    required this.profile,
    super.key,
  });

  /// Saída da linha.
  final Schedule schedule;

  /// Horário previsto em cada ponto, na ordem da linha.
  final List<StopTime> times;

  /// Velocidades por faixa de horário usadas na previsão.
  final SpeedProfile profile;

  /// Abre a lista como painel na parte de baixo da tela.
  static Future<void> show(
    BuildContext context, {
    required Schedule schedule,
    required List<StopTime> times,
    required SpeedProfile profile,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) => StopTimesSheet(
        schedule: schedule,
        times: times,
        profile: profile,
      ),
    );
  }

  String _speedNote() {
    final int? departure = Formatters.parseClock(schedule.departureTime);
    final SpeedBand? band = departure == null
        ? null
        : profile.bandAt(schedule.weekday, departure.toDouble());
    final double speed = band?.speedKmh ?? profile.defaultSpeedKmh;
    final String label = band == null ? 'horário normal' : band.label;
    return 'Previsão pela distância na rua, na velocidade média de '
        '${speed.round()} km/h ($label), com ${profile.stopDwellSeconds} s '
        'parado em cada ponto. Pode variar com o trânsito.';
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Saída às ${schedule.departureTime} · '
                  '${Formatters.weekdayName(schedule.weekday)}',
                  style: AppTextStyles.title,
                ),
                const SizedBox(height: 4),
                Text(_speedNote(), style: AppTextStyles.caption),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: times.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Não foi possível calcular a previsão desta saída.',
                      style: AppTextStyles.caption,
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: times.length,
                    itemBuilder: (BuildContext context, int index) {
                      final StopTime time = times[index];
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: kPrimaryColor,
                          child: Text(
                            '${time.stop.order}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        title: Text(
                          time.stop.name,
                          style: AppTextStyles.body,
                        ),
                        trailing: Text(
                          index == 0
                              ? Formatters.clock(time.minuteOfDay)
                              : '~${Formatters.clock(time.minuteOfDay)}',
                          style: AppTextStyles.title,
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
