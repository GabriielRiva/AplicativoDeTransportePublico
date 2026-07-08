import '../entities/stop.dart';

/// Contrato de consulta de paradas (nó stops/ do Realtime Database).
abstract interface class StopRepository {
  /// Retorna as paradas de uma linha ordenadas pela sequência da rota.
  Future<List<Stop>> getStopsByLine(String lineId);
}
