import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'geo_utils.dart';

/// Utilitários de mapa dependentes do Google Maps (camada de apresentação).
abstract final class MapUtils {
  /// Calcula a distância em km entre dois pontos do mapa.
  static double distanceInKm(LatLng from, LatLng to) {
    return GeoUtils.distanceInKm(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  /// Estima o tempo de chegada em minutos entre dois pontos do mapa.
  static int estimateArrivalMinutes(LatLng from, LatLng to) {
    return GeoUtils.estimateArrivalMinutes(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  /// Calcula os limites (bounds) que englobam todos os [points],
  /// usado para enquadrar uma rota inteira na câmera.
  static LatLngBounds boundsFromPoints(List<LatLng> points) {
    assert(points.isNotEmpty, 'A lista de pontos não pode ser vazia.');
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final LatLng point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}
