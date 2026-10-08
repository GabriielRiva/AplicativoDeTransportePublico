import 'dart:math' as math;

import '../../../core/utils/formatters.dart';
import '../../entities/schedule.dart';
import '../../entities/speed_profile.dart';
import '../../entities/stop.dart';

/// Horário previsto de passagem em uma parada, em minutos desde 00:00 do
/// dia da saída (pode passar de 1440 em viagens que viram a meia-noite).
typedef StopTime = ({Stop stop, int minuteOfDay});

/// Calcula o horário previsto de passagem em cada parada de uma saída
/// (ex.: saída 10:00, ponto 5 às 10:10, ponto 10 às 10:20).
///
/// Previsão = horário de saída + distância pela rua até a parada na
/// velocidade da faixa de horário + tempo parado nos pontos anteriores.
class PredictStopTimes {
  /// Cria o usecase (cálculo puro, sem dependências externas).
  const PredictStopTimes();

  /// [stops] na ordem da linha e [stopMeters] a distância (m) pela rua do
  /// início da rota até cada uma. Vazio se o horário de saída é inválido.
  List<StopTime> call({
    required Schedule schedule,
    required List<Stop> stops,
    required List<double> stopMeters,
    required SpeedProfile profile,
  }) {
    final int? departure = Formatters.parseClock(schedule.departureTime);
    if (departure == null || stops.length != stopMeters.length) {
      return const <StopTime>[];
    }
    return <StopTime>[
      for (int i = 0; i < stops.length; i++)
        (
          stop: stops[i],
          minuteOfDay: departure +
              (profile.secondsToTravel(
                        stopMeters[i],
                        weekday: schedule.weekday,
                        startMinute: departure.toDouble(),
                        // A primeira parada é a saída; o tempo parado
                        // conta a partir da segunda.
                        stops: math.max(0, i - 1),
                      ) /
                      60)
                  .round(),
        ),
    ];
  }
}
