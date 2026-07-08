import '../entities/enums/driver_status.dart';
import '../entities/trip.dart';

/// Contrato de operações do motorista (nó drivers/ do Realtime Database).
///
/// Cobre também o ciclo de vida do trajeto (Trip), pois o trajeto ativo
/// é persistido dentro do próprio nó do motorista (FIREBASE_SCHEMA).
abstract interface class DriverRepository {
  /// Registra o início de um trajeto, gravando linha, ônibus, posição
  /// inicial e status trip_started no nó do motorista.
  Future<void> startTrip(Trip trip);

  /// Encerra o trajeto ativo do motorista, atualizando o status para
  /// trip_finished e interrompendo a transmissão.
  Future<void> finishTrip(String driverId);

  /// Sobrescreve a posição atual do motorista (chamado a cada 5 segundos
  /// durante um trajeto ativo — RNF05).
  Future<void> sendLocation({
    required String driverId,
    required double latitude,
    required double longitude,
  });

  /// Atualiza apenas o status do motorista.
  Future<void> updateStatus(String driverId, DriverStatus status);

  /// Stream com todos os motoristas presentes no nó drivers/,
  /// emitida a cada alteração no banco (base do tempo real).
  Stream<List<Trip>> watchActiveDrivers();
}
