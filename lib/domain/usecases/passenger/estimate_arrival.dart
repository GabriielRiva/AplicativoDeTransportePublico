import 'dart:math' as math;

import '../../entities/speed_profile.dart';
import 'bus_speed_tracker.dart';

/// Estima o tempo de chegada de um ônibus a um ponto.
///
/// Camada 1: velocidade média da faixa de horário ([SpeedProfile]) mais o
/// tempo parado em cada ponto do caminho.
/// Camada 2: velocidade real do ônibus nos últimos minutos
/// ([BusSpeedTracker]). Quanto mais tempo observado, maior o peso dela, até
/// [maxObservedWeight]; o restante continua vindo da faixa de horário, para
/// uma parada no semáforo não distorcer a estimativa.
class EstimateArrival {
  /// Cria o estimador com o perfil de velocidades.
  const EstimateArrival(this.profile);

  /// Tempo observado a partir do qual a velocidade real tem peso máximo.
  static const Duration fullTrustWindow = Duration(minutes: 5);

  /// Peso máximo da velocidade real na estimativa.
  static const double maxObservedWeight = 0.7;

  /// Velocidades médias por faixa de horário.
  final SpeedProfile profile;

  /// Peso da velocidade real para um tempo observado [window].
  static double observedWeight(Duration window) {
    final double ratio =
        window.inMilliseconds / fullTrustWindow.inMilliseconds;
    return maxObservedWeight * ratio.clamp(0.0, 1.0);
  }

  /// Tempo (s) para percorrer [meters] a partir de [now], passando por
  /// [stopsOnTheWay] pontos, com a velocidade real [observed] se houver.
  double seconds({
    required double meters,
    required DateTime now,
    int stopsOnTheWay = 0,
    ObservedSpeed? observed,
  }) {
    final double planned = profile.secondsToTravel(
      meters,
      weekday: now.weekday,
      startMinute: SpeedProfile.minuteOfDay(now),
      stops: stopsOnTheWay,
    );
    if (observed == null) return planned;
    final double weight = observedWeight(observed.window);
    final double real = meters / (observed.speedKmh / 3.6);
    return weight * real + (1 - weight) * planned;
  }

  /// Igual a [seconds], em minutos inteiros (no mínimo 1).
  int minutes({
    required double meters,
    required DateTime now,
    int stopsOnTheWay = 0,
    ObservedSpeed? observed,
  }) {
    final double value = seconds(
      meters: meters,
      now: now,
      stopsOnTheWay: stopsOnTheWay,
      observed: observed,
    );
    return math.max(1, (value / 60).round());
  }
}
