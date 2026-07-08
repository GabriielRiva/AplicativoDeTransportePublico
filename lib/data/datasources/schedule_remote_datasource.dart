import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../core/constants/firebase_paths.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/app_logger.dart';
import '../models/schedule_model.dart';

/// Datasource do nó schedules/ do Realtime Database.
class ScheduleRemoteDatasource {
  /// Cria o datasource recebendo a instância de [FirebaseDatabase].
  const ScheduleRemoteDatasource(this._database);

  final FirebaseDatabase _database;

  /// Lê os horários de uma linha filtrando pelo campo lineId.
  Future<List<ScheduleModel>> getSchedulesByLine(String lineId) async {
    try {
      final DataSnapshot snapshot = await _database
          .ref(kSchedulesPath)
          .orderByChild('lineId')
          .equalTo(lineId)
          .get();
      final Object? raw = snapshot.value;
      if (raw is! Map<Object?, Object?>) return <ScheduleModel>[];

      final List<ScheduleModel> schedules = <ScheduleModel>[];
      raw.forEach((Object? key, Object? value) {
        if (key == null || value is! Map<Object?, Object?>) return;
        schedules.add(
          ScheduleModel.fromJson(
            key.toString(),
            Map<String, dynamic>.from(value),
          ),
        );
      });
      return schedules;
    } on FirebaseException catch (error, stackTrace) {
      AppLogger.error('Falha ao carregar horários', error, stackTrace);
      throw const DatabaseException(
        'Não foi possível carregar os horários de saída.',
      );
    }
  }
}
