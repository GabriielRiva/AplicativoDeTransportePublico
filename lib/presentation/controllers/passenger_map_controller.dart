import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/geo_utils.dart';
import '../../domain/entities/line.dart';
import '../../domain/entities/stop.dart';
import '../../domain/entities/trip.dart';
import '../../domain/usecases/passenger/find_stop_at_position.dart';
import '../../domain/usecases/passenger/get_nearby_buses.dart';
import '../providers/bus_providers.dart';
import '../providers/line_providers.dart';
import '../providers/map_icon_providers.dart';
import '../providers/service_providers.dart';
import '../providers/usecase_providers.dart';
import '../widgets/map/route_progress.dart';

/// Ônibus selecionado no mapa do passageiro (id do trajeto), ou nulo.
final StateProvider<String?> selectedBusIdProvider =
    StateProvider<String?>((ref) => null);

/// Estado imutável do mapa do passageiro.
class PassengerMapState {
  /// Cria o estado do mapa.
  const PassengerMapState({
    this.markers = const <Marker>{},
    this.polylines = const <Polyline>{},
    this.nearbyBuses = const <NearbyBus>[],
    this.userPosition,
    this.isLoading = true,
    this.selectedTrip,
    this.selectedLine,
    this.selectedRoute = const <LatLng>[],
    this.selectedStopHere,
    this.selectedEtaMinutes,
  });

  /// Marcadores dos ônibus em circulação (RF12) e dos pontos de parada.
  final Set<Marker> markers;

  /// Trajeto do ônibus selecionado: trecho percorrido e trecho que ele
  /// ainda vai percorrer.
  final Set<Polyline> polylines;

  /// Lista "Ônibus próximos" com estimativa de chegada (RF13).
  final List<NearbyBus> nearbyBuses;

  /// Posição atual do passageiro (nula até o GPS responder).
  final LatLng? userPosition;

  /// Indica que os dados iniciais ainda estão carregando.
  final bool isLoading;

  /// Trajeto (ônibus) selecionado pelo passageiro no mapa.
  final Trip? selectedTrip;

  /// Linha do ônibus selecionado.
  final Line? selectedLine;

  /// Traçado completo da linha do ônibus selecionado.
  final List<LatLng> selectedRoute;

  /// Ponto em que o ônibus selecionado está agora (embarque liberado).
  final Stop? selectedStopHere;

  /// Estimativa de chegada do ônibus selecionado até o passageiro.
  final int? selectedEtaMinutes;
}

/// ViewModel do mapa do passageiro (RF07/RF12/RF13/RF18).
///
/// Deriva o estado das streams em tempo real: a cada emissão do nó
/// drivers/ os marcadores e a lista de próximos são recalculados
/// automaticamente, sem intervenção do usuário (RF18).
class PassengerMapController extends Notifier<PassengerMapState> {
  static const FindStopAtPosition _findStop = FindStopAtPosition();

  @override
  PassengerMapState build() {
    final AsyncValue<List<Trip>> tripsAsync =
        ref.watch(activeBusesProvider);
    final AsyncValue<List<Line>> linesAsync = ref.watch(linesProvider);
    final AsyncValue<Position> positionAsync =
        ref.watch(userPositionProvider);
    final MapMarkerIcons? icons =
        ref.watch(markerIconsProvider).valueOrNull;
    final String? selectedId = ref.watch(selectedBusIdProvider);

    final List<Trip> trips = tripsAsync.valueOrNull ?? <Trip>[];
    final List<Line> lines = linesAsync.valueOrNull ?? <Line>[];
    final Position? position = positionAsync.valueOrNull;

    final LatLng? userPosition = position == null
        ? null
        : LatLng(position.latitude, position.longitude);

    final Map<String, Line> linesById = <String, Line>{
      for (final Line line in lines) line.id: line,
    };
    final Map<String, List<Stop>> stopsByLine = <String, List<Stop>>{
      for (final Line line in lines)
        line.id:
            ref.watch(lineStopsProvider(line.id)).valueOrNull ?? <Stop>[],
    };

    // Ônibus selecionado (some sozinho se o trajeto for encerrado).
    final Trip? selectedTrip = selectedId == null
        ? null
        : trips.where((Trip trip) => trip.id == selectedId).firstOrNull;
    final Line? selectedLine =
        selectedTrip == null ? null : linesById[selectedTrip.lineId];
    final List<LatLng> selectedRoute = selectedTrip == null
        ? const <LatLng>[]
        : ref.watch(lineRouteProvider(selectedTrip.lineId)).valueOrNull ??
            const <LatLng>[];

    return PassengerMapState(
      markers: <Marker>{
        ..._buildStopMarkers(stopsByLine, linesById, icons),
        ..._buildBusMarkers(trips, linesById, stopsByLine, icons),
      },
      polylines: _buildSelectedRoute(selectedTrip, selectedLine, selectedRoute),
      nearbyBuses: _buildNearbyBuses(trips, lines, userPosition),
      userPosition: userPosition,
      isLoading: tripsAsync.isLoading || linesAsync.isLoading,
      selectedTrip: selectedTrip,
      selectedLine: selectedLine,
      selectedRoute: selectedRoute,
      selectedStopHere: selectedTrip == null
          ? null
          : _stopHere(selectedTrip, stopsByLine),
      selectedEtaMinutes: selectedTrip == null || userPosition == null
          ? null
          : GeoUtils.estimateArrivalMinutes(
              userPosition.latitude,
              userPosition.longitude,
              selectedTrip.currentLatitude,
              selectedTrip.currentLongitude,
            ),
    );
  }

  /// Seleciona o ônibus [tripId] para mostrar o trajeto dele no mapa.
  void selectBus(String tripId) {
    ref.read(selectedBusIdProvider.notifier).state = tripId;
  }

  /// Volta para a visão geral (sem ônibus selecionado).
  void clearSelection() {
    ref.read(selectedBusIdProvider.notifier).state = null;
  }

  Stop? _stopHere(Trip trip, Map<String, List<Stop>> stopsByLine) {
    return _findStop(
      stops: stopsByLine[trip.lineId] ?? const <Stop>[],
      latitude: trip.currentLatitude,
      longitude: trip.currentLongitude,
    );
  }

  Set<Marker> _buildBusMarkers(
    List<Trip> trips,
    Map<String, Line> linesById,
    Map<String, List<Stop>> stopsByLine,
    MapMarkerIcons? icons,
  ) {
    return trips.map((Trip trip) {
      final Line? line = linesById[trip.lineId];
      final Stop? stopHere = _stopHere(trip, stopsByLine);
      return Marker(
        markerId: MarkerId('bus_${trip.id}'),
        position: LatLng(trip.currentLatitude, trip.currentLongitude),
        zIndex: 2,
        icon: icons?.bus ??
            BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
        infoWindow: InfoWindow(
          title: line?.displayName ?? 'Ônibus em circulação',
          snippet: stopHere == null
              ? 'Em trajeto — toque para ver o percurso'
              : 'No ponto ${stopHere.name} — embarque liberado',
        ),
        onTap: () => selectBus(trip.id),
      );
    }).toSet();
  }

  /// Pontos de parada de todas as linhas. Pontos compartilhados (ex.:
  /// Terminal Urbano) viram um único marcador com as linhas que param ali.
  Set<Marker> _buildStopMarkers(
    Map<String, List<Stop>> stopsByLine,
    Map<String, Line> linesById,
    MapMarkerIcons? icons,
  ) {
    final Map<String, Stop> byPlace = <String, Stop>{};
    final Map<String, Set<String>> linesByPlace = <String, Set<String>>{};
    for (final MapEntry<String, List<Stop>> entry in stopsByLine.entries) {
      for (final Stop stop in entry.value) {
        // ~11 m de precisão: o mesmo ponto físico em linhas diferentes.
        final String key = '${stop.latitude.toStringAsFixed(4)},'
            '${stop.longitude.toStringAsFixed(4)}';
        byPlace.putIfAbsent(key, () => stop);
        linesByPlace
            .putIfAbsent(key, () => <String>{})
            .add(linesById[entry.key]?.number ?? entry.key);
      }
    }

    return byPlace.entries.map((MapEntry<String, Stop> entry) {
      final Stop stop = entry.value;
      final List<String> numbers = linesByPlace[entry.key]!.toList()..sort();
      return Marker(
        markerId: MarkerId('stop_${entry.key}'),
        position: LatLng(stop.latitude, stop.longitude),
        zIndex: 1,
        icon: icons?.stop ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(
          title: stop.name,
          snippet: 'Ponto de embarque — ${numbers.join(', ')}',
        ),
      );
    }).toSet();
  }

  /// Trajeto do ônibus selecionado: cinza no que já foi percorrido e na
  /// cor da linha no que ele ainda vai percorrer.
  Set<Polyline> _buildSelectedRoute(
    Trip? trip,
    Line? line,
    List<LatLng> route,
  ) {
    if (trip == null || route.length < 2) return const <Polyline>{};
    final LatLng bus = LatLng(trip.currentLatitude, trip.currentLongitude);
    final int index = RouteProgress.nearestIndex(route, bus);
    final RouteSnap snap = RouteProgress.snap(route, bus, index);
    final Color lineColor =
        line == null ? kSuccessColor : colorFromHex(line.color);

    return <Polyline>{
      Polyline(
        polylineId: const PolylineId('selected_traveled'),
        points: <LatLng>[
          ...route.sublist(0, snap.segmentStart + 1),
          snap.point,
        ],
        color: const Color(0xFF9E9E9E),
        width: 5,
      ),
      Polyline(
        polylineId: const PolylineId('selected_remaining'),
        points: <LatLng>[
          snap.point,
          ...route.sublist(snap.segmentStart + 1),
        ],
        color: lineColor,
        width: 6,
      ),
    };
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
