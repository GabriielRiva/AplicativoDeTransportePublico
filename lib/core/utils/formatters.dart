/// Formatações de valores exibidos ao usuário.
abstract final class Formatters {
  static const List<String> _weekdays = <String>[
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
  ];

  /// Formata distância em km com uma casa decimal (ex.: "8,5 km").
  static String distanceKm(double distanceKm) {
    return '${distanceKm.toStringAsFixed(1).replaceAll('.', ',')} km';
  }

  /// Formata uma distância em metros: até 1 km em metros, de 10 em 10
  /// (ex.: "320 m"); a partir disso em km (ex.: "1,2 km").
  static String distanceMeters(double meters) {
    if (meters < 995) {
      final int rounded = ((meters < 0 ? 0 : meters) / 10).round() * 10;
      return '$rounded m';
    }
    return distanceKm(meters / 1000);
  }

  /// Formata duração em minutos (ex.: "35 min").
  static String durationMinutes(int minutes) => '$minutes min';

  /// Converte "HH:mm" em minutos desde 00:00 (ex.: "07:30" = 450;
  /// "24:00" = 1440). Nulo se o texto não for um horário válido.
  static int? parseClock(String value) {
    final List<String> parts = value.trim().split(':');
    if (parts.length != 2) return null;
    final int? hours = int.tryParse(parts[0]);
    final int? minutes = int.tryParse(parts[1]);
    if (hours == null || minutes == null) return null;
    if (hours < 0 || minutes < 0 || minutes > 59) return null;
    final int total = hours * 60 + minutes;
    return total > 24 * 60 ? null : total;
  }

  /// Formata minutos desde 00:00 como "HH:mm" (ex.: 610 = "10:10"),
  /// voltando a 00:00 depois da meia-noite.
  static String clock(int minuteOfDay) {
    final int minute = minuteOfDay % (24 * 60);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(minute ~/ 60)}:${two(minute % 60)}';
  }

  /// Converte o número do dia da semana (1 = segunda) em nome por extenso.
  static String weekdayName(int weekday) {
    if (weekday < DateTime.monday || weekday > DateTime.sunday) {
      return 'Dia inválido';
    }
    return _weekdays[weekday - 1];
  }
}
