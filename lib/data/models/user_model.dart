import '../../domain/entities/driver.dart';
import '../../domain/entities/enums/user_role.dart';
import '../../domain/entities/passenger.dart';
import '../../domain/entities/user.dart';
import 'driver_model.dart';
import 'passenger_model.dart';

/// Fábrica de serialização de usuários.
///
/// Decide, pelo campo role do JSON, se o perfil deve ser materializado
/// como [Driver] ou [Passenger] — base do redirecionamento por perfil.
abstract final class UserModel {
  /// Constrói o usuário concreto a partir do JSON de users/{uid}.
  static User fromJson(String uid, Map<String, dynamic> json) {
    final UserRole role =
        UserRole.fromValue(json['role'] as String? ?? 'passenger');
    return role == UserRole.driver
        ? DriverModel.fromJson(uid, json)
        : PassengerModel.fromJson(uid, json);
  }

  /// Converte qualquer usuário para o JSON persistido em users/{uid}.
  static Map<String, dynamic> toJson(User user) {
    if (user is Driver) {
      return DriverModel(
        uid: user.uid,
        name: user.name,
        email: user.email,
        createdAt: user.createdAt,
        cnh: user.cnh,
      ).toJson();
    }
    if (user is Passenger) {
      return PassengerModel(
        uid: user.uid,
        name: user.name,
        email: user.email,
        createdAt: user.createdAt,
        favoriteLineIds: user.favoriteLineIds,
      ).toJson();
    }
    return <String, dynamic>{
      'name': user.name,
      'email': user.email,
      'role': user.role.value,
      'createdAt': user.createdAt.millisecondsSinceEpoch,
    };
  }
}
