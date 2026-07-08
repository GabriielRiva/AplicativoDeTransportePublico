import '../../domain/entities/bus.dart';
import '../../domain/entities/enums/driver_status.dart';

/// Model de serialização do [Bus] (nó buses/ do Realtime Database).
class BusModel extends Bus {
  /// Cria o model com os mesmos atributos da entidade.
  const BusModel({
    required super.id,
    required super.number,
    required super.plate,
    required super.model,
    required super.year,
    required super.lineId,
    super.driverId,
    super.status,
    super.latitude,
    super.longitude,
    super.updatedAt,
  });

  /// Constrói o ônibus a partir do JSON do nó buses/{busId}.
  factory BusModel.fromJson(String id, Map<String, dynamic> json) {
    final num? updatedAt = json['updatedAt'] as num?;
    return BusModel(
      id: id,
      number: json['number']?.toString() ?? '',
      plate: json['plate'] as String? ?? '',
      model: json['model'] as String? ?? '',
      year: (json['year'] as num?)?.toInt() ?? 0,
      lineId: json['lineId'] as String? ?? '',
      driverId: json['driverId'] as String?,
      status: DriverStatus.fromValue(json['status'] as String? ?? 'offline'),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      updatedAt: updatedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(updatedAt.toInt()),
    );
  }

  /// Converte o ônibus para o JSON persistido em buses/{busId}.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'number': number,
      'plate': plate,
      'model': model,
      'year': year,
      'lineId': lineId,
      if (driverId != null) 'driverId': driverId,
      'status': status.value,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (updatedAt != null) 'updatedAt': updatedAt!.millisecondsSinceEpoch,
    };
  }
}
