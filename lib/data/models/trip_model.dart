import '../../domain/entities/enums/driver_status.dart';
import '../../domain/entities/trip.dart';

/// Model de serialização do [Trip] (nó drivers/{uid} do Realtime
/// Database, conforme decisão de projeto documentada na entidade).
class TripModel extends Trip {
  /// Cria o model com os mesmos atributos da entidade.
  const TripModel({
    required super.id,
    required super.driverId,
    required super.busId,
    required super.lineId,
    required super.startedAt,
    required super.status,
    required super.currentLatitude,
    required super.currentLongitude,
    super.finishedAt,
  });

  /// Constrói o trajeto a partir do JSON do nó drivers/{uid}.
  factory TripModel.fromJson(String driverId, Map<String, dynamic> json) {
    final num? finishedAt = json['finishedAt'] as num?;
    return TripModel(
      id: driverId,
      driverId: driverId,
      busId: json['busId'] as String? ?? '',
      lineId: json['lineId'] as String? ?? '',
      startedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['startedAt'] as num?)?.toInt() ?? 0,
      ),
      finishedAt: finishedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(finishedAt.toInt()),
      status: DriverStatus.fromValue(json['status'] as String? ?? 'offline'),
      currentLatitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      currentLongitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Converte o trajeto para o JSON gravado em drivers/{uid} no início
  /// do trajeto (a posição é sobrescrita a cada 5 segundos — RNF05).
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'busId': busId,
      'lineId': lineId,
      'startedAt': startedAt.millisecondsSinceEpoch,
      'status': status.value,
      'latitude': currentLatitude,
      'longitude': currentLongitude,
      if (finishedAt != null) 'finishedAt': finishedAt!.millisecondsSinceEpoch,
    };
  }
}
