import '../../repositories/user_repository.dart';

/// Alterna uma linha como favorita do passageiro (API_SPEC:
/// Passenger.favoriteLine).
class FavoriteLine {
  /// Cria o usecase com o repositório de usuários.
  const FavoriteLine(this._userRepository);

  final UserRepository _userRepository;

  /// Adiciona ou remove a [lineId] das favoritas e retorna a lista
  /// atualizada, já persistida no perfil do passageiro.
  Future<List<String>> call({
    required String uid,
    required String lineId,
    required List<String> currentFavorites,
  }) async {
    final List<String> updated = List<String>.from(currentFavorites);
    if (updated.contains(lineId)) {
      updated.remove(lineId);
    } else {
      updated.add(lineId);
    }
    await _userRepository.updateFavoriteLines(uid, updated);
    return updated;
  }
}
