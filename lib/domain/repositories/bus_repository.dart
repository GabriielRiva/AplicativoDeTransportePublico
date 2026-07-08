import '../entities/bus.dart';

/// Contrato de consulta de ônibus (nó buses/ do Realtime Database).
abstract interface class BusRepository {
  /// Retorna todos os ônibus cadastrados.
  Future<List<Bus>> getBuses();

  /// Retorna os ônibus vinculados a uma linha.
  Future<List<Bus>> getBusesByLine(String lineId);

  /// Busca um ônibus pelo identificador.
  Future<Bus> getBusById(String busId);
}
