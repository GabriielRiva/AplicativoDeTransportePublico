import '../../domain/entities/line.dart';
import '../../domain/repositories/line_repository.dart';
import '../datasources/line_remote_datasource.dart';

/// Implementação de [LineRepository] via Realtime Database.
final class LineRepositoryImpl implements LineRepository {
  /// Cria a implementação recebendo o datasource de linhas.
  const LineRepositoryImpl(this._datasource);

  final LineRemoteDatasource _datasource;

  @override
  Future<List<Line>> getLines() => _datasource.getLines();

  @override
  Future<Line> getLineById(String lineId) =>
      _datasource.getLineById(lineId);
}
