import '../../entities/stop.dart';
import '../../repositories/stop_repository.dart';

/// Consulta os pontos de parada de uma linha (RF09 — rotas).
class GetLineStops {
  /// Cria o usecase com o repositório de paradas.
  const GetLineStops(this._stopRepository);

  final StopRepository _stopRepository;

  /// Retorna as paradas da [lineId] ordenadas pela sequência da rota,
  /// prontas para desenhar a polyline no mapa.
  Future<List<Stop>> call(String lineId) async {
    final List<Stop> stops = await _stopRepository.getStopsByLine(lineId);
    stops.sort((Stop a, Stop b) => a.order.compareTo(b.order));
    return stops;
  }
}
