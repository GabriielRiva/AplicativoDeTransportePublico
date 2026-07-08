import '../../domain/entities/stop.dart';

/// Model de serialização do [Stop] (nó stops/ do Realtime Database).
class StopModel extends Stop {
  /// Cria o model com os mesmos atributos da entidade.
  const StopModel({
    required super.id,
    required super.lineId,
    required super.name,
    required super.latitude,
    required super.longitude,
    required super.order,
  });

  /// Constrói a parada a partir do JSON do nó stops/{stopId}.
  factory StopModel.fromJson(String id, Map<String, dynamic> json) {
    return StopModel(
      id: id,
      lineId: json['lineId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }

  /// Converte a parada para o JSON persistido em stops/{stopId}.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'lineId': lineId,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'order': order,
    };
  }
}
