/// Faixa de horário com velocidade média própria (ex.: horário de pico).
class SpeedBand {
  /// Cria a faixa de horário.
  const SpeedBand({
    required this.label,
    required this.startMinute,
    required this.endMinute,
    required this.speedKmh,
    this.weekdaysOnly = false,
  });

  /// Nome da faixa exibido ao usuário (ex.: "Pico da manhã").
  final String label;

  /// Início da faixa em minutos desde 00:00 (ex.: 07:30 = 450).
  final int startMinute;

  /// Fim da faixa (exclusivo) em minutos desde 00:00 (24:00 = 1440).
  final int endMinute;

  /// Velocidade média dos ônibus nesta faixa (km/h), já considerando
  /// semáforos e trânsito.
  final double speedKmh;

  /// Vale só de segunda a sexta (ex.: horários de pico).
  final bool weekdaysOnly;

  /// Indica se a faixa vale no dia [weekday] (1 = segunda ... 7 = domingo).
  bool appliesOn(int weekday) =>
      !weekdaysOnly || weekday <= DateTime.friday;

  /// Indica se a faixa vale no dia [weekday], no minuto [minute] do dia.
  bool contains(int weekday, double minute) =>
      appliesOn(weekday) && minute >= startMinute && minute < endMinute;
}

/// Velocidade média dos ônibus ao longo do dia, usada nas estimativas de
/// tempo (horário previsto em cada ponto e tempo de chegada).
///
/// Fica no Firebase (nó speedProfile) para ser calibrada com o teste real
/// sem gerar um novo APK. Sem o nó, vale [SpeedProfile.fallback].
class SpeedProfile {
  /// Cria o perfil de velocidades.
  const SpeedProfile({
    required this.defaultSpeedKmh,
    required this.stopDwellSeconds,
    this.bands = const <SpeedBand>[],
  });

  /// Perfil padrão: picos de Chapecó (07:30–08:30 e 17:30–19:00, dias
  /// úteis) mais lentos, madrugada e noite mais rápidas.
  static const SpeedProfile fallback = SpeedProfile(
    defaultSpeedKmh: 20,
    stopDwellSeconds: 20,
    bands: <SpeedBand>[
      SpeedBand(
        label: 'Madrugada',
        startMinute: 0,
        endMinute: 6 * 60,
        speedKmh: 25,
      ),
      SpeedBand(
        label: 'Pico da manhã',
        startMinute: 7 * 60 + 30,
        endMinute: 8 * 60 + 30,
        speedKmh: 13,
        weekdaysOnly: true,
      ),
      SpeedBand(
        label: 'Pico da tarde',
        startMinute: 17 * 60 + 30,
        endMinute: 19 * 60,
        speedKmh: 13,
        weekdaysOnly: true,
      ),
      SpeedBand(
        label: 'Noite',
        startMinute: 21 * 60,
        endMinute: 24 * 60,
        speedKmh: 25,
      ),
    ],
  );

  /// Minutos em um dia.
  static const int minutesPerDay = 24 * 60;

  /// Velocidade média (km/h) fora das faixas cadastradas.
  final double defaultSpeedKmh;

  /// Tempo (s) parado em cada ponto para embarque e desembarque.
  final int stopDwellSeconds;

  /// Faixas de horário com velocidade própria.
  final List<SpeedBand> bands;

  /// Minuto do dia de [time] (ex.: 07:30:30 = 450,5).
  static double minuteOfDay(DateTime time) =>
      time.hour * 60 + time.minute + time.second / 60;

  /// Faixa que vale no dia [weekday], no minuto [minute], ou nula fora
  /// das faixas (vale [defaultSpeedKmh]).
  SpeedBand? bandAt(int weekday, double minute) {
    for (final SpeedBand band in bands) {
      if (band.contains(weekday, minute)) return band;
    }
    return null;
  }

  /// Velocidade média (km/h) no dia [weekday], no minuto [minute].
  double speedAt(int weekday, double minute) =>
      bandAt(weekday, minute)?.speedKmh ?? defaultSpeedKmh;

  /// Tempo (s) para percorrer [meters] saindo no dia [weekday], no minuto
  /// [startMinute], parando em [stops] pontos no caminho.
  ///
  /// Se o percurso atravessa uma mudança de faixa (ex.: sai 07:20 e entra
  /// no pico das 07:30), cada parte usa a velocidade da sua faixa.
  double secondsToTravel(
    double meters, {
    required int weekday,
    required double startMinute,
    int stops = 0,
  }) {
    double remaining = meters;
    double minute = startMinute % minutesPerDay;
    int day = weekday;
    double seconds = 0;
    // Limite de segurança: cada volta avança até a próxima mudança de
    // faixa, então poucas voltas bastam para qualquer percurso urbano.
    for (int step = 0; remaining > 0 && step < 100; step++) {
      final double metersPerSecond = speedAt(day, minute) / 3.6;
      final double boundary = _nextBoundary(day, minute);
      final double untilBoundary = (boundary - minute) * 60;
      final double reachable = untilBoundary * metersPerSecond;
      if (reachable >= remaining) {
        seconds += remaining / metersPerSecond;
        remaining = 0;
      } else {
        seconds += untilBoundary;
        remaining -= reachable;
        minute = boundary;
        if (minute >= minutesPerDay) {
          minute -= minutesPerDay;
          day = day % DateTime.sunday + 1;
        }
      }
    }
    return seconds + stops * stopDwellSeconds;
  }

  /// Próximo minuto, depois de [minute], em que alguma faixa começa ou
  /// termina no dia [weekday] (ou a meia-noite).
  double _nextBoundary(int weekday, double minute) {
    double next = minutesPerDay.toDouble();
    for (final SpeedBand band in bands) {
      if (!band.appliesOn(weekday)) continue;
      if (band.startMinute > minute && band.startMinute < next) {
        next = band.startMinute.toDouble();
      }
      if (band.endMinute > minute && band.endMinute < next) {
        next = band.endMinute.toDouble();
      }
    }
    return next;
  }
}
