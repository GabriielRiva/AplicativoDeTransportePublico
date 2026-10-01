import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/utils/map_utils.dart';

/// Resultado de [RouteProgress.snap]: o ponto sobre a rota e o índice do
/// início do trecho (segmento) em que ele está.
class RouteSnap {
  /// Cria o resultado da projeção.
  const RouteSnap(this.point, this.segmentStart);

  /// Ponto projetado sobre a rota.
  final LatLng point;

  /// Índice do primeiro ponto do trecho que contém [point].
  final int segmentStart;
}

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
    final int start = math.max(0, math.min(fromIndex, route.length - 1));

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

  /// Projeta [position] sobre a rota, considerando os dois trechos vizinhos
  /// ao ponto [index] (normalmente o retornado por [advance]). Usado para
  /// desenhar o ônibus em cima da rua, mesmo com pequenas imprecisões do GPS.
  /// Exige uma rota com pelo menos 2 pontos.
  static RouteSnap snap(List<LatLng> route, LatLng position, int index) {
    assert(route.length >= 2, 'A rota precisa de pelo menos 2 pontos.');
    final int i = math.max(0, math.min(index, route.length - 1));
    RouteSnap best = RouteSnap(route[i], math.min(i, route.length - 2));
    double bestDistance = double.infinity;
    for (final int start in <int>[i - 1, i]) {
      if (start < 0 || start + 1 >= route.length) continue;
      final LatLng projected =
          _projectOnSegment(route[start], route[start + 1], position);
      final double distance = MapUtils.distanceInKm(projected, position);
      if (distance < bestDistance) {
        bestDistance = distance;
        best = RouteSnap(projected, start);
      }
    }
    return best;
  }

  /// Ponto do segmento [a]-[b] mais próximo de [p], numa aproximação plana
  /// (suficiente para trechos de rua de poucas centenas de metros).
  static LatLng _projectOnSegment(LatLng a, LatLng b, LatLng p) {
    final double k = math.cos(a.latitude * math.pi / 180);
    final double ax = a.longitude * k;
    final double ay = a.latitude;
    final double dx = b.longitude * k - ax;
    final double dy = b.latitude - ay;
    final double lengthSq = dx * dx + dy * dy;
    if (lengthSq == 0) return a;
    final double raw =
        ((p.longitude * k - ax) * dx + (p.latitude - ay) * dy) / lengthSq;
    final double t = math.max(0.0, math.min(1.0, raw));
    return LatLng(ay + t * dy, (ax + t * dx) / k);
  }

  static double _squaredDegrees(LatLng a, LatLng b) {
    final double dLat = a.latitude - b.latitude;
    final double dLng = a.longitude - b.longitude;
    return dLat * dLat + dLng * dLng;
  }
}
