import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../core/constants/firebase_paths.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/enums/driver_status.dart';
import '../models/trip_model.dart';

/// Datasource do nó drivers/ do Realtime Database.
///
/// Concentra o ciclo de vida do trajeto: início, transmissão de GPS
/// a cada 5 segundos (RNF05), encerramento e a stream de tempo real
/// consumida pelo perfil do passageiro.
class DriverRemoteDatasource {
  /// Cria o datasource recebendo a instância de [FirebaseDatabase].
  const DriverRemoteDatasource(this._database);

  final FirebaseDatabase _database;

  DatabaseReference _driverRef(String driverId) =>
      _database.ref('$kDriversPath/$driverId');

  /// Grava o início do trajeto em drivers/{uid}.
  Future<void> startTrip(TripModel trip) async {
    try {
      final Map<String, dynamic> json = trip.toJson()
        ..['updatedAt'] = ServerValue.timestamp;
      await _driverRef(trip.driverId).set(json);
      AppLogger.info('Trajeto iniciado pelo motorista ${trip.driverId}');
    } on FirebaseException catch (error, stackTrace) {
      AppLogger.error('Falha ao iniciar trajeto', error, stackTrace);
      throw const DatabaseException(
        'Não foi possível iniciar o trajeto. Tente novamente.',
      );
    }
  }

  /// Mantém o status do trajeto de acordo com a conexão do aparelho.
  ///
  /// A cada (re)conexão com o Firebase: registra no servidor que, se a
  /// conexão cair (app fechado, sem bateria, sem sinal), o motorista passa
  /// a "offline" sozinho, e volta o status para trip_started. Assim o
  /// ônibus some do mapa do passageiro quando o motorista desconecta e
  /// reaparece quando ele volta. Emite `true`/`false` conforme a conexão.
  Stream<bool> keepTripAlive(String driverId) {
    final DatabaseReference driverRef = _driverRef(driverId);
    return _database
        .ref('.info/connected')
        .onValue
        .asyncMap((DatabaseEvent event) async {
      final bool connected = event.snapshot.value == true;
      if (connected) {
        try {
          await driverRef.onDisconnect().update(<String, Object?>{
            'status': DriverStatus.offline.value,
          });
          await driverRef.update(<String, Object?>{
            'status': DriverStatus.tripStarted.value,
            'updatedAt': ServerValue.timestamp,
          });
        } on FirebaseException catch (error, stackTrace) {
          AppLogger.error(
            'Falha ao registrar a queda de conexão',
            error,
            stackTrace,
          );
        }
      }
      return connected;
    });
  }

  /// Encerra o trajeto, gravando status trip_finished e o horário.
  Future<void> finishTrip(String driverId) async {
    try {
      // O trajeto acabou: a queda de conexão não deve mais mudar o status.
      await _driverRef(driverId).onDisconnect().cancel();
      await _driverRef(driverId).update(<String, dynamic>{
        'status': DriverStatus.tripFinished.value,
        'finishedAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
      });
      AppLogger.info('Trajeto encerrado pelo motorista $driverId');
    } on FirebaseException catch (error, stackTrace) {
      AppLogger.error('Falha ao encerrar trajeto', error, stackTrace);
      throw const DatabaseException(
        'Não foi possível encerrar o trajeto. Tente novamente.',
      );
    }
  }

  /// Sobrescreve a posição atual do veículo em drivers/{uid}.
  Future<void> sendLocation({
    required String driverId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _driverRef(driverId).update(<String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
        'updatedAt': ServerValue.timestamp,
      });
    } on FirebaseException catch (error, stackTrace) {
      AppLogger.error('Falha ao transmitir localização', error, stackTrace);
      throw const DatabaseException(
        'Não foi possível transmitir a localização.',
      );
    }
  }

  /// Atualiza apenas o status do motorista.
  Future<void> updateStatus(String driverId, DriverStatus status) async {
    try {
      await _driverRef(driverId).update(<String, dynamic>{
        'status': status.value,
        'updatedAt': ServerValue.timestamp,
      });
    } on FirebaseException catch (error, stackTrace) {
      AppLogger.error('Falha ao atualizar status', error, stackTrace);
      throw const DatabaseException(
        'Não foi possível atualizar o status do motorista.',
      );
    }
  }

  /// Stream do nó drivers/ completo, emitida a cada alteração no banco.
  Stream<List<TripModel>> watchDrivers() {
    return _database.ref(kDriversPath).onValue.map((DatabaseEvent event) {
      final Object? raw = event.snapshot.value;
      if (raw is! Map<Object?, Object?>) return <TripModel>[];

      final List<TripModel> trips = <TripModel>[];
      raw.forEach((Object? key, Object? value) {
        if (key == null || value is! Map<Object?, Object?>) return;
        trips.add(
          TripModel.fromJson(
            key.toString(),
            Map<String, dynamic>.from(value),
          ),
        );
      });
      return trips;
    }).handleError((Object error, StackTrace stackTrace) {
      AppLogger.error('Falha na stream de motoristas', error, stackTrace);
      throw const DatabaseException(
        'Não foi possível acompanhar os ônibus em tempo real.',
      );
    });
  }
}
