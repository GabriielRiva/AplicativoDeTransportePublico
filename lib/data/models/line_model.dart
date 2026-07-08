import '../../domain/entities/line.dart';

/// Model de serialização da [Line] (nó lines/ do Realtime Database).
class LineModel extends Line {
  /// Cria o model com os mesmos atributos da entidade.
  const LineModel({
    required super.id,
    required super.number,
    required super.name,
    required super.description,
    required super.distance,
    required super.averageDuration,
    required super.color,
  });

  /// Constrói a linha a partir do JSON do nó lines/{lineId}.
  ///
  /// Aceita tanto a chave averageDuration (API_SPEC) quanto
  /// averageTime (FIREBASE_SCHEMA) para o tempo médio de percurso.
  factory LineModel.fromJson(String id, Map<String, dynamic> json) {
    final num? duration =
        (json['averageDuration'] ?? json['averageTime']) as num?;
    return LineModel(
      id: id,
      number: json['number']?.toString() ?? id,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      distance: (json['distance'] as num?)?.toDouble() ?? 0,
      averageDuration: duration?.toInt() ?? 0,
      color: json['color'] as String? ?? '#4A9EBF',
    );
  }

  /// Converte a linha para o JSON persistido em lines/{lineId}.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'number': number,
      'name': name,
      'description': description,
      'distance': distance,
      'averageDuration': averageDuration,
      'color': color,
    };
  }
}
