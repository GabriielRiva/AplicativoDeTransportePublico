import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/utils/polyline_decoder.dart';
import '../../repositories/line_repository.dart';

/// Consulta o traçado de rua de uma linha (RF09 — rotas).
///
/// O traçado é fixo e foi pré-calculado uma única vez via Google Directions
/// API, sendo persistido codificado (precisão 5) no campo `routePolyline`
/// da própria linha. Este usecase apenas o decodifica; nenhuma chamada à
/// Directions API ocorre em runtime.
class GetLineRoute {
  /// Cria o usecase com o repositório de linhas.
  const GetLineRoute(this._lineRepository);

  final LineRepository _lineRepository;

  /// Retorna os pontos do traçado da [lineId], prontos para a polyline.
  /// Retorna lista vazia quando a linha ainda não possui rota semeada.
  Future<List<LatLng>> call(String lineId) async {
    final line = await _lineRepository.getLineById(lineId);
    if (line.routePolyline.isEmpty) return const <LatLng>[];
    return PolylineDecoder.decode(line.routePolyline);
  }
}
