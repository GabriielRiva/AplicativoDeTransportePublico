import '../../domain/entities/passenger.dart';

/// Model de serialização do [Passenger] (nó users/ do Realtime Database).
class PassengerModel extends Passenger {
  /// Cria o model com os mesmos atributos da entidade.
  const PassengerModel({
    required super.uid,
    required super.name,
    required super.email,
    required super.createdAt,
    super.favoriteLineIds,
  });

  /// Constrói o passageiro a partir do JSON do nó users/{uid}.
  factory PassengerModel.fromJson(String uid, Map<String, dynamic> json) {
    final Object? favorites = json['favoriteLines'];
    return PassengerModel(
      uid: uid,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['createdAt'] as num?)?.toInt() ?? 0,
      ),
      favoriteLineIds: favorites is List
          ? favorites.map((Object? id) => id.toString()).toList()
          : const <String>[],
    );
  }

  /// Converte o perfil para o JSON persistido em users/{uid}.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'email': email,
      'role': role.value,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'favoriteLines': favoriteLineIds,
    };
  }
}
