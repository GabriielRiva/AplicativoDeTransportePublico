import 'dart:math' as math;

import '../constants/app_constants.dart';

/// Matemática geográfica em Dart puro (sem dependência de Flutter),
/// permitindo uso tanto no domínio quanto na apresentação.
abstract final class GeoUtils {
  static const double _earthRadiusKm = 6371;

  /// Calcula a distância em km entre duas coordenadas usando a fórmula
  /// de Haversine.
  static double distanceInKm(
    double fromLat,
    double fromLng,
    double toLat,
    double toLng,
  ) {
    final double dLat = _toRadians(toLat - fromLat);
    final double dLng = _toRadians(toLng - fromLng);
    final double a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_toRadians(fromLat)) *
            math.cos(_toRadians(toLat)) *
            math.pow(math.sin(dLng / 2), 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadiusKm * c;
  }

  /// Estima o tempo de chegada em minutos com base na velocidade média
  /// urbana definida em [kAverageBusSpeedKmh].
  static int estimateArrivalMinutes(
    double fromLat,
    double fromLng,
    double toLat,
    double toLng,
  ) {
    final double km = distanceInKm(fromLat, fromLng, toLat, toLng);
    final double minutes = (km / kAverageBusSpeedKmh) * 60;
    return math.max(1, minutes.round());
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;
}
