import 'package:firebase_database/firebase_database.dart';

import '../../core/constants/firebase_paths.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/speed_profile.dart';
import '../models/speed_profile_model.dart';

/// Datasource do nó speedProfile/ do Realtime Database.
class SpeedProfileRemoteDatasource {
  /// Cria o datasource recebendo a instância de [FirebaseDatabase].
  const SpeedProfileRemoteDatasource(this._database);

  final FirebaseDatabase _database;

  /// Stream do perfil de velocidades. Sem o nó no banco, emite o perfil
  /// padrão ([SpeedProfile.fallback]).
  Stream<SpeedProfile> watchSpeedProfile() {
    return _database
        .ref(kSpeedProfilePath)
        .onValue
        .map((DatabaseEvent event) {
      final Object? raw = event.snapshot.value;
      if (raw is! Map<Object?, Object?>) return SpeedProfile.fallback;
      return SpeedProfileModel.fromJson(Map<String, dynamic>.from(raw));
    }).handleError((Object error, StackTrace stackTrace) {
      AppLogger.error('Falha ao ler as velocidades', error, stackTrace);
      throw const DatabaseException(
        'Não foi possível carregar as velocidades por horário.',
      );
    });
  }
}
