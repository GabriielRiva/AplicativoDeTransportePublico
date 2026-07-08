import 'enums/driver_status.dart';

/// Trajeto ativo de um motorista (API_SPEC: Trip).
///
/// Decisão de projeto: o trajeto é persistido dentro do nó
/// `drivers/{uid}` do Realtime Database (FIREBASE_SCHEMA), sobrescrito
/// a cada 5 segundos, sem histórico de posições. Esta entidade
/// representa esse estado em memória nas camadas superiores.
class Trip {
  /// Cria a representação de um trajeto.
  const Trip({
    required this.id,
    required this.driverId,
    required this.busId,
    required this.lineId,
    required this.startedAt,
    required this.status,
    required this.currentLatitude,
    required this.currentLongitude,
    this.finishedAt,
  });

  /// Identificador do trajeto (igual ao UID do motorista, pois cada
  /// motorista possui no máximo um trajeto ativo por vez).
  final String id;

  /// UID do motorista que conduz o trajeto.
  final String driverId;

  /// Ônibus utilizado no trajeto.
  final String busId;

  /// Linha percorrida no trajeto.
  final String lineId;

  /// Momento de início do trajeto.
  final DateTime startedAt;

  /// Momento de encerramento (nulo enquanto o trajeto está ativo).
  final DateTime? finishedAt;

  /// Status atual do trajeto.
  final DriverStatus status;

  /// Latitude mais recente do veículo.
  final double currentLatitude;

  /// Longitude mais recente do veículo.
  final double currentLongitude;

  /// Retorna uma cópia do trajeto alterando apenas os campos informados.
  Trip copyWith({
    DriverStatus? status,
    double? currentLatitude,
    double? currentLongitude,
    DateTime? finishedAt,
  }) {
    return Trip(
      id: id,
      driverId: driverId,
      busId: busId,
      lineId: lineId,
      startedAt: startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      status: status ?? this.status,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
    );
  }

  @override
  bool operator ==(Object other) => other is Trip && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
