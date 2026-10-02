import '../../../core/constants/app_constants.dart';
import '../../../core/utils/geo_utils.dart';
import '../../entities/stop.dart';

/// Identifica se o ônibus está em um ponto de parada, para o app avisar
/// motorista e passageiro de que o embarque e o desembarque estão
/// liberados.
class FindStopAtPosition {
  /// Cria o usecase (cálculo puro, sem dependências externas).
  const FindStopAtPosition();

  /// Retorna a parada mais próxima de ([latitude], [longitude]) que esteja a
  /// até [radiusMeters] metros, ou `null` se o ônibus não estiver em nenhum
  /// ponto.
  Stop? call({
    required List<Stop> stops,
    required double latitude,
    required double longitude,
    double radiusMeters = kStopArrivalRadiusMeters,
  }) {
    Stop? closest;
    double closestMeters = double.infinity;
    for (final Stop stop in stops) {
      final double meters = GeoUtils.distanceInKm(
            latitude,
            longitude,
            stop.latitude,
            stop.longitude,
          ) *
          1000;
      if (meters <= radiusMeters && meters < closestMeters) {
        closest = stop;
        closestMeters = meters;
      }
    }
    return closest;
  }
}
