/// Horário de saída de uma linha (API_SPEC: Schedule).
class Schedule {
  /// Cria um horário de saída.
  const Schedule({
    required this.id,
    required this.lineId,
    required this.departureTime,
    required this.weekday,
  });

  /// Identificador único do horário.
  final String id;

  /// Linha à qual o horário pertence.
  final String lineId;

  /// Horário de saída no formato "HH:mm".
  final String departureTime;

  /// Dia da semana (1 = segunda-feira ... 7 = domingo).
  final int weekday;

  @override
  bool operator ==(Object other) => other is Schedule && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
