import '../../entities/line.dart';
import '../../repositories/line_repository.dart';

/// Lista as linhas disponíveis no sistema (RF08).
class GetLines {
  /// Cria o usecase com o repositório de linhas.
  const GetLines(this._lineRepository);

  final LineRepository _lineRepository;

  /// Retorna todas as linhas ordenadas pelo número.
  Future<List<Line>> call() async {
    final List<Line> lines = await _lineRepository.getLines();
    lines.sort((Line a, Line b) => a.number.compareTo(b.number));
    return lines;
  }
}
