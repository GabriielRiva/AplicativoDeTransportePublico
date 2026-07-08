import '../entities/schedule.dart';

/// Contrato de consulta de horários (nó schedules/ do Realtime Database).
abstract interface class ScheduleRepository {
  /// Retorna os horários de saída de uma linha.
  Future<List<Schedule>> getSchedulesByLine(String lineId);
}
