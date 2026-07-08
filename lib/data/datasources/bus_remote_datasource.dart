import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../core/constants/firebase_paths.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/app_logger.dart';
import '../models/bus_model.dart';

/// Datasource do nó buses/ do Realtime Database.
class BusRemoteDatasource {
  /// Cria o datasource recebendo a instância de [FirebaseDatabase].
  const BusRemoteDatasource(this._database);

  final FirebaseDatabase _database;

  /// Lê todos os ônibus cadastrados.
  Future<List<BusModel>> getBuses() async {
    try {
      final DataSnapshot snapshot = await _database.ref(kBusesPath).get();
      return _parseList(snapshot.value);
    } on FirebaseException catch (error, stackTrace) {
      AppLogger.error('Falha ao carregar ônibus', error, stackTrace);
      throw const DatabaseException(
        'Não foi possível carregar os ônibus. Tente novamente.',
      );
    }
  }

  /// Lê os ônibus vinculados a uma linha filtrando pelo campo lineId.
  Future<List<BusModel>> getBusesByLine(String lineId) async {
    try {
      final DataSnapshot snapshot = await _database
          .ref(kBusesPath)
          .orderByChild('lineId')
          .equalTo(lineId)
          .get();
      return _parseList(snapshot.value);
    } on FirebaseException catch (error, stackTrace) {
      AppLogger.error('Falha ao carregar ônibus da linha', error, stackTrace);
      throw const DatabaseException(
        'Não foi possível carregar os ônibus da linha.',
      );
    }
  }

  /// Lê um ônibus específico por identificador.
  Future<BusModel> getBusById(String busId) async {
    try {
      final DataSnapshot snapshot =
          await _database.ref('$kBusesPath/$busId').get();
      final Object? value = snapshot.value;
      if (!snapshot.exists || value is! Map<Object?, Object?>) {
        throw const DatabaseException('Ônibus não encontrado.');
      }
      return BusModel.fromJson(busId, Map<String, dynamic>.from(value));
    } on FirebaseException catch (error, stackTrace) {
      AppLogger.error('Falha ao carregar ônibus', error, stackTrace);
      throw const DatabaseException(
        'Não foi possível carregar o ônibus. Tente novamente.',
      );
    }
  }

  List<BusModel> _parseList(Object? raw) {
    if (raw is! Map<Object?, Object?>) return <BusModel>[];
    final List<BusModel> buses = <BusModel>[];
    raw.forEach((Object? key, Object? value) {
      if (key == null || value is! Map<Object?, Object?>) return;
      buses.add(
        BusModel.fromJson(key.toString(), Map<String, dynamic>.from(value)),
      );
    });
    return buses;
  }
}
