/// Ponto de parada de uma linha (API_SPEC: Stop).
class Stop {
  /// Cria um ponto de parada.
  const Stop({
    required this.id,
    required this.lineId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.order,
  });

  /// Identificador único da parada.
  final String id;

  /// Linha à qual a parada pertence.
  final String lineId;

  /// Nome da parada (ex.: "R. São Marcos").
  final String name;

  /// Latitude da parada.
  final double latitude;

  /// Longitude da parada.
  final double longitude;

  /// Posição da parada na sequência da rota (1 = primeira).
  final int order;

  @override
  bool operator ==(Object other) => other is Stop && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
