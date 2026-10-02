import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../constants/map_constants.dart';
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

  /// Rumo (bearing) de [from] para [to], em graus de 0 a 360 no sentido
  /// horário a partir do norte.
  static double bearing(LatLng from, LatLng to) {
    final double lat1 = from.latitude * math.pi / 180;
    final double lat2 = to.latitude * math.pi / 180;
    final double dLon = (to.longitude - from.longitude) * math.pi / 180;
    final double y = math.sin(dLon) * math.cos(lat2);
    final double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
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

  /// Cria a polyline de uma rota a partir dos pontos ordenados,
  /// reutilizada nas telas de detalhes da linha e de trajeto ativo.
  static Polyline routePolyline({
    required String id,
    required Color color,
    required List<LatLng> points,
    int width = kRoutePolylineWidth,
  }) {
    return Polyline(
      polylineId: PolylineId(id),
      color: color,
      width: width,
      points: points,
    );
  }
}