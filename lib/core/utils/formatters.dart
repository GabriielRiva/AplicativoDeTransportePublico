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

  /// Converte o número do dia da semana (1 = segunda) em nome por extenso.
  static String weekdayName(int weekday) {
    if (weekday < DateTime.monday || weekday > DateTime.sunday) {
      return 'Dia inválido';
    }
    return _weekdays[weekday - 1];
  }
}
