import 'dart:math' as math;

import '../../entities/speed_profile.dart';

/// Estimativa de viagem entre duas paradas da mesma linha.
typedef StopToStop = ({double meters, int stopsOnTheWay, int minutes});

/// Estima quanto tempo o ônibus leva de uma parada a outra da mesma linha
/// (ex.: "do ponto 3 ao ponto 8: ~12 min, 3,2 km, 4 paradas no caminho").
///
/// Usa a distância pela rua entre as paradas, a velocidade média da faixa
/// de horário ([SpeedProfile]) e o tempo parado em cada ponto do caminho.
class EstimateBetweenStops {
  /// Cria o usecase (cálculo puro, sem dependências externas).
  const EstimateBetweenStops();

  /// [stopMeters] é a distância (m) pela rua do início da linha até cada
  /// parada, na ordem da linha; [from] e [to] são posições nessa lista.
  ///
  /// Nulo se as paradas são iguais ou se, numa linha que não é circular,
  /// o destino fica antes da origem (o ônibus não passa lá depois).
  StopToStop? call({
    required List<double> stopMeters,
    required int from,
    required int to,
    required bool isCircular,
    required double totalMeters,
    required SpeedProfile profile,
    required DateTime departure,
  }) {
    final int count = stopMeters.length;
    if (from == to || from < 0 || to < 0 || from >= count || to >= count) {
      return null;
    }
    final double meters;
    final int stops;
    if (to > from) {
      meters = stopMeters[to] - stopMeters[from];
      stops = to - from - 1;
    } else if (isCircular) {
      // Dá a volta: até o fim da linha e de novo do início até o destino.
      meters = totalMeters - stopMeters[from] + stopMeters[to];
      stops = (count - 1 - from) + to;
    } else {
      return null;
    }
    final double seconds = profile.secondsToTravel(
      meters,
      weekday: departure.weekday,
      startMinute: SpeedProfile.minuteOfDay(departure),
      stops: stops,
    );
    return (
      meters: meters,
      stopsOnTheWay: stops,
      minutes: math.max(1, (seconds / 60).round()),
    );
  }
}
