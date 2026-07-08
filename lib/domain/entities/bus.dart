import 'enums/driver_status.dart';

/// Ônibus da frota (API_SPEC: Bus).
class Bus {
  /// Cria um ônibus cadastrado no sistema.
  const Bus({
    required this.id,
    required this.number,
    required this.plate,
    required this.model,
    required this.year,
    required this.lineId,
    this.driverId,
    this.status = DriverStatus.offline,
    this.latitude,
    this.longitude,
    this.updatedAt,
  });

  /// Identificador único do ônibus.
  final String id;

  /// Número de frota exibido ao usuário (ex.: "1430").
  final String number;

  /// Placa do veículo.
  final String plate;

  /// Modelo do veículo (ex.: "Mercedes-Benz").
  final String model;

  /// Ano de fabricação.
  final int year;

  /// Linha à qual o ônibus está vinculado.
  final String lineId;

  /// Motorista atualmente associado (nulo quando sem motorista).
  final String? driverId;

  /// Status operacional do veículo.
  final DriverStatus status;

  /// Última latitude conhecida (nula antes do primeiro trajeto).
  final double? latitude;

  /// Última longitude conhecida (nula antes do primeiro trajeto).
  final double? longitude;

  /// Momento da última atualização de posição.
  final DateTime? updatedAt;

  @override
  bool operator ==(Object other) => other is Bus && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
