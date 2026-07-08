import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../core/constants/firebase_paths.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/user.dart';
import '../models/user_model.dart';

/// Datasource do nó users/ do Realtime Database.
class UserRemoteDatasource {
  /// Cria o datasource recebendo a instância de [FirebaseDatabase].
  const UserRemoteDatasource(this._database);

  final FirebaseDatabase _database;

  /// Grava o perfil do usuário em users/{uid}.
  Future<void> saveProfile(User user) async {
    try {
      await _database
          .ref('$kUsersPath/${user.uid}')
          .set(UserModel.toJson(user));
      AppLogger.info('Perfil salvo para ${user.uid}');
    } on FirebaseException catch (error, stackTrace) {
      AppLogger.error('Falha ao salvar perfil', error, stackTrace);
      throw const DatabaseException(
        'Não foi possível salvar seu perfil. Tente novamente.',
      );
    }
  }

  /// Lê o perfil de users/{uid}, materializando Driver ou Passenger.
  Future<User> getProfile(String uid) async {
    try {
      final DataSnapshot snapshot =
          await _database.ref('$kUsersPath/$uid').get();
      final Object? value = snapshot.value;
      if (!snapshot.exists || value is! Map<Object?, Object?>) {
        throw const DatabaseException('Perfil de usuário não encontrado.');
      }
      return UserModel.fromJson(uid, Map<String, dynamic>.from(value));
    } on FirebaseException catch (error, stackTrace) {
      AppLogger.error('Falha ao carregar perfil', error, stackTrace);
      throw const DatabaseException(
        'Não foi possível carregar seu perfil. Tente novamente.',
      );
    }
  }

  /// Atualiza a lista de linhas favoritas em users/{uid}/favoriteLines.
  Future<void> updateFavoriteLines(String uid, List<String> lineIds) async {
    try {
      await _database
          .ref('$kUsersPath/$uid/favoriteLines')
          .set(lineIds);
    } on FirebaseException catch (error, stackTrace) {
      AppLogger.error('Falha ao atualizar favoritas', error, stackTrace);
      throw const DatabaseException(
        'Não foi possível atualizar suas linhas favoritas.',
      );
    }
  }
}
