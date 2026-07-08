import '../../domain/entities/schedule.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../datasources/schedule_remote_datasource.dart';

/// Implementação de [ScheduleRepository] via Realtime Database.
final class ScheduleRepositoryImpl implements ScheduleRepository {
  /// Cria a implementação recebendo o datasource de horários.
  const ScheduleRepositoryImpl(this._datasource);

  final ScheduleRemoteDatasource _datasource;

  @override
  Future<List<Schedule>> getSchedulesByLine(String lineId) =>
      _datasource.getSchedulesByLine(lineId);
}
