import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/utils/map_utils.dart';

/// Localiza o progresso do ônibus ao longo do traçado da linha.
///
/// Em linhas circulares (ida e volta pelo mesmo corredor) o traçado passa
/// duas vezes perto do mesmo ponto. Procurar o ponto mais próximo na rota
/// inteira faria o trecho percorrido "pular" para a volta enquanto o ônibus
/// ainda está na ida. Por isso [advance] parte do último índice conhecido e
/// só procura à frente, dentro de uma janela de distância. A busca global
/// fica como recuperação quando o ônibus não está perto da janela (início do
/// acompanhamento, GPS reposicionado, desvio de trajeto).
abstract final class RouteProgress {
  /// Distância (km) à frente do último índice considerada na busca.
  static const double defaultWindowKm = 1.0;

  /// Distância (km) máxima para aceitar o ponto encontrado na janela.
  static const double defaultMaxDistanceKm = 0.3;

  /// Índice do ponto da [route] mais próximo de [position], na rota inteira.
  static int nearestIndex(List<LatLng> route, LatLng position) {
    int bestIndex = 0;
    double bestDistance = double.infinity;
    for (int i = 0; i < route.length; i++) {
      final double distance = _squaredDegrees(route[i], position);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  /// Índice de progresso do ônibus, procurando apenas à frente de
  /// [fromIndex] (até [windowKm] de traçado). Se nenhum ponto da janela
  /// estiver a até [maxDistanceKm] da posição, recorre a [nearestIndex].
  static int advance(
    List<LatLng> route,
    LatLng position, {
    required int fromIndex,
    double windowKm = defaultWindowKm,
    double maxDistanceKm = defaultMaxDistanceKm,
  }) {
    if (route.isEmpty) return 0;
    final int start = fromIndex.clamp(0, route.length - 1);

    int bestIndex = start;
    double bestDistance = _squaredDegrees(route[start], position);
    double traveledKm = 0;
    for (int i = start + 1; i < route.length; i++) {
      traveledKm += MapUtils.distanceInKm(route[i - 1], route[i]);
      if (traveledKm > windowKm) break;
      final double distance = _squaredDegrees(route[i], position);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = i;
      }
    }

    if (MapUtils.distanceInKm(route[bestIndex], position) <= maxDistanceKm) {
      return bestIndex;
    }
    return nearestIndex(route, position);
  }

  static double _squaredDegrees(LatLng a, LatLng b) {
    final double dLat = a.latitude - b.latitude;
    final double dLng = a.longitude - b.longitude;
    return dLat * dLat + dLng * dLng;
  }
}
