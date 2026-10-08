/// Velocidade real de um ônibus nos últimos minutos e o tempo observado.
typedef ObservedSpeed = ({double speedKmh, Duration window});

/// Mede a velocidade real de um ônibus pelo quanto ele andou na rota nos
/// últimos [window] (camada 2 da estimativa de chegada).
///
/// Num dia de trânsito pior que o normal, o ônibus anda mais devagar que a
/// média da faixa de horário; a velocidade observada percebe isso na hora.
class BusSpeedTracker {
  /// Janela de tempo considerada.
  static const Duration window = Duration(minutes: 5);

  /// Tempo mínimo de observação para a medida valer.
  static const Duration minWindow = Duration(seconds: 60);

  /// Deslocamento mínimo (m) na janela. Abaixo disso o ônibus está parado
  /// (no terminal, por exemplo) e a medida não representa o percurso.
  static const double minMovedMeters = 50;

  /// Recuo (m) que indica nova volta ou ônibus reposicionado: recomeça.
  static const double resetBackMeters = 100;

  /// Limites aceitos para a velocidade medida (km/h).
  static const double minSpeedKmh = 4;

  /// Limites aceitos para a velocidade medida (km/h).
  static const double maxSpeedKmh = 60;

  final List<({DateTime at, double meters})> _samples =
      <({DateTime at, double meters})>[];

  /// Registra que no instante [at] o ônibus estava a [meters] do início
  /// da rota. Posições repetidas ou fora de ordem são ignoradas.
  void add(DateTime at, double meters) {
    if (_samples.isNotEmpty) {
      final ({DateTime at, double meters}) last = _samples.last;
      if (!at.isAfter(last.at)) return;
      if (meters < last.meters - resetBackMeters) _samples.clear();
    }
    _samples
      ..add((at: at, meters: meters))
      ..removeWhere(
        (({DateTime at, double meters}) sample) =>
            at.difference(sample.at) > window,
      );
  }

  /// Velocidade média na janela, ou nula se ainda não há dados
  /// suficientes ou o ônibus está parado.
  ObservedSpeed? get speed {
    if (_samples.length < 2) return null;
    final ({DateTime at, double meters}) first = _samples.first;
    final ({DateTime at, double meters}) last = _samples.last;
    final Duration elapsed = last.at.difference(first.at);
    if (elapsed < minWindow) return null;
    final double moved = last.meters - first.meters;
    if (moved < minMovedMeters) return null;
    final double kmh = moved / elapsed.inMilliseconds * 3600;
    return (
      speedKmh: kmh.clamp(minSpeedKmh, maxSpeedKmh),
      window: elapsed,
    );
  }
}
