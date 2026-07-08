import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../core/constants/firebase_paths.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/app_logger.dart';
import '../models/stop_model.dart';

/// Datasource do nó stops/ do Realtime Database.
class StopRemoteDatasource {
  /// Cria o datasource recebendo a instância de [FirebaseDatabase].
  const StopRemoteDatasource(this._database);

  final FirebaseDatabase _database;

  /// Lê as paradas de uma linha filtrando pelo campo lineId.
  Future<List<StopModel>> getStopsByLine(String lineId) async {
    try {
      final DataSnapshot snapshot = await _database
          .ref(kStopsPath)
          .orderByChild('lineId')
          .equalTo(lineId)
          .get();
      final Object? raw = snapshot.value;
      if (raw is! Map<Object?, Object?>) return <StopModel>[];

      final List<StopModel> stops = <StopModel>[];
      raw.forEach((Object? key, Object? value) {
        if (key == null || value is! Map<Object?, Object?>) return;
        stops.add(
          StopModel.fromJson(
            key.toString(),
            Map<String, dynamic>.from(value),
          ),
        );
      });
      return stops;
    } on FirebaseException catch (error, stackTrace) {
      AppLogger.error('Falha ao carregar paradas', error, stackTrace);
      throw const DatabaseException(
        'Não foi possível carregar os pontos de parada.',
      );
    }
  }
}
