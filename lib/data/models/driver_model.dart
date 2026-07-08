import '../../domain/entities/driver.dart';
import '../../domain/entities/enums/driver_status.dart';

/// Model de serialização do [Driver] (nó users/ do Realtime Database).
class DriverModel extends Driver {
  /// Cria o model com os mesmos atributos da entidade.
  const DriverModel({
    required super.uid,
    required super.name,
    required super.email,
    required super.createdAt,
    required super.cnh,
    super.busId,
    super.lineId,
    super.status,
    super.gpsEnabled,
  });

  /// Constrói o motorista a partir do JSON do nó users/{uid}.
  factory DriverModel.fromJson(String uid, Map<String, dynamic> json) {
    return DriverModel(
      uid: uid,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['createdAt'] as num?)?.toInt() ?? 0,
      ),
      cnh: json['cnh'] as String? ?? '',
      busId: json['busId'] as String?,
      lineId: json['lineId'] as String?,
      status: DriverStatus.fromValue(json['status'] as String? ?? 'offline'),
    );
  }

  /// Converte o perfil para o JSON persistido em users/{uid}.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'email': email,
      'role': role.value,
      'cnh': cnh,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
