/// Linha de ônibus (API_SPEC: Line).
class Line {
  /// Cria uma linha do transporte público.
  const Line({
    required this.id,
    required this.number,
    required this.name,
    required this.description,
    required this.distance,
    required this.averageDuration,
    required this.color,
  });

  /// Identificador único da linha.
  final String id;

  /// Número da linha exibido ao usuário (ex.: "L101").
  final String number;

  /// Nome da linha (ex.: "Centro/Ecoparque").
  final String name;

  /// Descrição do itinerário.
  final String description;

  /// Distância total da rota em quilômetros.
  final double distance;

  /// Tempo médio de percurso em minutos.
  final int averageDuration;

  /// Cor da linha em hexadecimal (ex.: "#4A9EBF"), usada na polyline.
  final String color;

  /// Nome completo exibido nas listas (ex.: "L101 - Centro/Ecoparque").
  String get displayName => '$number - $name';

  @override
  bool operator ==(Object other) => other is Line && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
