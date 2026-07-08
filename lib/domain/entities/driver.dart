import 'enums/driver_status.dart';
import 'enums/user_role.dart';
import 'user.dart';

/// Motorista do transporte público (API_SPEC: Driver, herda de User).
class Driver extends User {
  /// Cria um motorista; o [role] é fixado como [UserRole.driver].
  const Driver({
    required super.uid,
    required super.name,
    required super.email,
    required super.createdAt,
    required this.cnh,
    this.busId,
    this.lineId,
    this.status = DriverStatus.offline,
    this.gpsEnabled = false,
  }) : super(role: UserRole.driver);

  /// Número da CNH do motorista.
  final String cnh;

  /// Ônibus atualmente associado (nulo quando fora de serviço).
  final String? busId;

  /// Linha atualmente selecionada (nula quando fora de serviço).
  final String? lineId;

  /// Status atual do motorista.
  final DriverStatus status;

  /// Indica se o GPS do dispositivo está habilitado para transmissão.
  final bool gpsEnabled;

  /// Retorna uma cópia do motorista alterando apenas os campos informados.
  Driver copyWith({
    String? busId,
    String? lineId,
    DriverStatus? status,
    bool? gpsEnabled,
  }) {
    return Driver(
      uid: uid,
      name: name,
      email: email,
      createdAt: createdAt,
      cnh: cnh,
      busId: busId ?? this.busId,
      lineId: lineId ?? this.lineId,
      status: status ?? this.status,
      gpsEnabled: gpsEnabled ?? this.gpsEnabled,
    );
  }
}
