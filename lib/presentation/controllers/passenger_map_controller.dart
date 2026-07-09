import '../providers/map_icon_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/line.dart';
import '../../domain/entities/trip.dart';
import '../../domain/usecases/passenger/get_nearby_buses.dart';
import '../providers/bus_providers.dart';
import '../providers/line_providers.dart';
import '../providers/service_providers.dart';
import '../providers/usecase_providers.dart';

/// Estado imutável do mapa do passageiro.
class PassengerMapState {
  /// Cria o estado do mapa.
  const PassengerMapState({
    this.markers = const <Marker>{},
    this.nearbyBuses = const <NearbyBus>[],
    this.userPosition,
    this.isLoading = true,
  });

  /// Marcadores dos ônibus em circulação (RF12).
  final Set<Marker> markers;

  /// Lista "Ônibus próximos" com estimativa de chegada (RF13).
  final List<NearbyBus> nearbyBuses;

  /// Posição atual do passageiro (nula até o GPS responder).
  final LatLng? userPosition;

  /// Indica que os dados iniciais ainda estão carregando.
  final bool isLoading;
}

/// ViewModel do mapa do passageiro (RF07/RF12/RF13/RF18).
///
/// Deriva o estado das streams em tempo real: a cada emissão do nó
/// drivers/ os marcadores e a lista de próximos são recalculados
/// automaticamente, sem intervenção do usuário (RF18).
class PassengerMapController extends Notifier<PassengerMapState> {
   @override
  PassengerMapState build() {
    final AsyncValue<List<Trip>> tripsAsync =
        ref.watch(activeBusesProvider);
    final AsyncValue<List<Line>> linesAsync = ref.watch(linesProvider);
    final AsyncValue<Position> positionAsync =
        ref.watch(userPositionProvider);
    final MapMarkerIcons? icons =
        ref.watch(markerIconsProvider).valueOrNull;

    final List<Trip> trips = tripsAsync.valueOrNull ?? <Trip>[];
    final List<Line> lines = linesAsync.valueOrNull ?? <Line>[];
    final Position? position = positionAsync.valueOrNull;

    final LatLng? userPosition = position == null
        ? null
        : LatLng(position.latitude, position.longitude);

    return PassengerMapState(
      markers: _buildMarkers(trips, lines, icons),
      nearbyBuses: _buildNearbyBuses(trips, lines, userPosition),
      userPosition: userPosition,
      isLoading: tripsAsync.isLoading || linesAsync.isLoading,
    );
  }

Set<Marker> _buildMarkers(
    List<Trip> trips,
    List<Line> lines,
    MapMarkerIcons? icons,
  ) {
    final Map<String, Line> linesById = <String, Line>{
      for (final Line line in lines) line.id: line,
    };

    return trips.map((Trip trip) {
      final Line? line = linesById[trip.lineId];
      return Marker(
        markerId: MarkerId(trip.id),
        position: LatLng(trip.currentLatitude, trip.currentLongitude),
        icon: icons?.bus ??
            BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
        infoWindow: InfoWindow(
          title: line?.displayName ?? 'Ônibus em circulação',
          snippet: 'Em trajeto',
        ),
      );
    }).toSet();
  }

  List<NearbyBus> _buildNearbyBuses(
    List<Trip> trips,
    List<Line> lines,
    LatLng? userPosition,
  ) {
    if (userPosition == null) return const <NearbyBus>[];
    return ref.read(getNearbyBusesProvider).call(
          userLatitude: userPosition.latitude,
          userLongitude: userPosition.longitude,
          trips: trips,
          lines: lines,
          maxResults: kMaxNearbyBuses,
        );
  }
}

/// Provider do [PassengerMapController].
final NotifierProvider<PassengerMapController, PassengerMapState>
    passengerMapControllerProvider =
    NotifierProvider<PassengerMapController, PassengerMapState>(
  PassengerMapController.new,
);
