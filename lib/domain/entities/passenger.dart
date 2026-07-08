import 'enums/user_role.dart';
import 'user.dart';

/// Passageiro do transporte público (API_SPEC: Passenger, herda de User).
class Passenger extends User {
  /// Cria um passageiro; o [role] é fixado como [UserRole.passenger].
  const Passenger({
    required super.uid,
    required super.name,
    required super.email,
    required super.createdAt,
    this.favoriteLineIds = const <String>[],
  }) : super(role: UserRole.passenger);

  /// Linhas favoritadas pelo passageiro.
  ///
  /// Atributo de suporte ao método favoriteLine() previsto no API_SPEC:
  /// é a estrutura mínima necessária para persistir as favoritas.
  final List<String> favoriteLineIds;

  /// Retorna uma cópia do passageiro com a lista de favoritas atualizada.
  Passenger copyWith({List<String>? favoriteLineIds}) {
    return Passenger(
      uid: uid,
      name: name,
      email: email,
      createdAt: createdAt,
      favoriteLineIds: favoriteLineIds ?? this.favoriteLineIds,
    );
  }
}
