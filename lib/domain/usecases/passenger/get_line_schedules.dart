import '../../entities/schedule.dart';
import '../../repositories/schedule_repository.dart';

/// Consulta os horários de saída de uma linha (RF10).
class GetLineSchedules {
  /// Cria o usecase com o repositório de horários.
  const GetLineSchedules(this._scheduleRepository);

  final ScheduleRepository _scheduleRepository;

  /// Retorna os horários da [lineId] ordenados por dia da semana
  /// e horário de saída.
  Future<List<Schedule>> call(String lineId) async {
    final List<Schedule> schedules =
        await _scheduleRepository.getSchedulesByLine(lineId);
    schedules.sort((Schedule a, Schedule b) {
      final int byWeekday = a.weekday.compareTo(b.weekday);
      if (byWeekday != 0) return byWeekday;
      return a.departureTime.compareTo(b.departureTime);
    });
    return schedules;
  }
}
