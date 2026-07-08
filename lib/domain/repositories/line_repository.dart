import '../entities/line.dart';

/// Contrato de consulta de linhas (nó lines/ do Realtime Database).
abstract interface class LineRepository {
  /// Retorna todas as linhas cadastradas.
  Future<List<Line>> getLines();

  /// Busca uma linha pelo identificador.
  Future<Line> getLineById(String lineId);
}
