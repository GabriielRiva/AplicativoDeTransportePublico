import '../../../core/utils/geo_utils.dart';
import '../../entities/line.dart';
import '../../entities/trip.dart';

/// Ônibus próximo do passageiro, com linha, distância e estimativa
/// de chegada — item da lista "Ônibus próximos" (RF13).
class NearbyBus {
  /// Cria um resultado de proximidade.
  const NearbyBus({
    required this.trip,
    required this.line,
    required this.distanceKm,
    required this.etaMinutes,
  });

  /// Trajeto ativo do ônibus.
  final Trip trip;

  /// Linha percorrida pelo ônibus.
  final Line line;

  /// Distância em km até o passageiro.
  final double distanceKm;

  /// Estimativa de chegada em minutos.
  final int etaMinutes;
}

/// Calcula os ônibus mais próximos do passageiro (RF13).
class GetNearbyBuses {
  /// Cria o usecase (cálculo puro, sem dependências externas).
  const GetNearbyBuses();

  /// Cruza os [trips] ativos com as [lines] cadastradas e retorna a
  /// lista ordenada da menor para a maior distância até o passageiro,
  /// limitada a [maxResults].
  List<NearbyBus> call({
    required double userLatitude,
    required double userLongitude,
    required List<Trip> trips,
    required List<Line> lines,
    int maxResults = 3,
  }) {
    final Map<String, Line> linesById = <String, Line>{
      for (final Line line in lines) line.id: line,
    };

    final List<NearbyBus> nearby = <NearbyBus>[];
    for (final Trip trip in trips) {
      final Line? line = linesById[trip.lineId];
      if (line == null) continue;

      final double distanceKm = GeoUtils.distanceInKm(
        userLatitude,
        userLongitude,
        trip.currentLatitude,
        trip.currentLongitude,
      );
      final int etaMinutes = GeoUtils.estimateArrivalMinutes(
        userLatitude,
        userLongitude,
        trip.currentLatitude,
        trip.currentLongitude,
      );

      nearby.add(
        NearbyBus(
          trip: trip,
          line: line,
          distanceKm: distanceKm,
          etaMinutes: etaMinutes,
        ),
      );
    }

    nearby.sort(
      (NearbyBus a, NearbyBus b) => a.distanceKm.compareTo(b.distanceKm),
    );
    return nearby.take(maxResults).toList();
  }
}
