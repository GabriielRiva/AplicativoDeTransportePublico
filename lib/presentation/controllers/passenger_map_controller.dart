import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/geo_utils.dart';
import '../../core/utils/map_utils.dart';
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
import '../widgets/map/route_stops.dart';
import '../widgets/map/stop_markers.dart';
import '../widgets/map/stop_placement.dart';

/// Ônibus selecionado no mapa do passageiro (id do trajeto), ou nulo.
final StateProvider<String?> selectedBusIdProvider =
    StateProvider<String?>((ref) => null);

/// Estado imutável do mapa do passageiro.
class PassengerMapState {
  /// Cria o estado do mapa.
  const PassengerMapState({
    this.markers = const <Marker>{},
    this.stopMarkers = const <Marker>{},
    this.nearbyBuses = const <NearbyBus>[],
    this.userPosition,
    this.isLoading = true,
    this.selectedTrip,
    this.selectedLine,
    this.selectedRoute = const <LatLng>[],
    this.selectedStopHere,
    this.selectedEtaMinutes,
    this.selectedNextStop,
    this.selectedUserStop,
    this.selectedUserStopMeters,
    this.selectedPassedUserStop = false,
  });

  /// Marcadores dos ônibus em circulação (RF12) e dos pontos de parada.
  final Set<Marker> markers;

  /// Só os marcadores dos pontos de parada (usados no acompanhamento do
  /// ônibus selecionado).
  final Set<Marker> stopMarkers;

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

  /// Estimativa de chegada do ônibus selecionado até o ponto do
  /// passageiro, pela rota (ou em linha reta, sem rota ou paradas).
  final int? selectedEtaMinutes;

  /// Próxima parada à frente do ônibus selecionado e a distância até ela.
  final StopAhead? selectedNextStop;

  /// Parada da linha do ônibus selecionado mais próxima do passageiro.
  final Stop? selectedUserStop;

  /// Distância (m) pela rota do ônibus selecionado até [selectedUserStop].
  final double? selectedUserStopMeters;

  /// O ônibus selecionado já passou pelo ponto do passageiro e não volta
  /// a passar nele neste trajeto.
  final bool selectedPassedUserStop;
}

/// Situação de um ônibus em relação às paradas e ao passageiro.
class BusApproach {
  /// Cria a situação do ônibus.
  const BusApproach({
    this.onRoute = false,
    this.nextStop,
    this.userStop,
    this.userStopMeters,
  });

  /// O ônibus está sobre o traçado da linha (as distâncias pela rota
  /// valem).
  final bool onRoute;

  /// Próxima parada à frente do ônibus e a distância até ela.
  final StopAhead? nextStop;

  /// Parada da linha mais próxima do passageiro.
  final Stop? userStop;

  /// Distância (m) pela rota até [userStop]; nula se o ônibus já passou.
  final double? userStopMeters;

  /// O ônibus já passou pelo ponto do passageiro e não volta a passar.
  bool get passedUserStop =>
      onRoute && userStop != null && userStopMeters == null;

  /// Minutos até o ônibus chegar ao ponto do passageiro, pela rota.
  int? get etaMinutes {
    final double? meters = userStopMeters;
    if (!onRoute || meters == null) return null;
    return GeoUtils.minutesForKm(meters / 1000);
  }
}

/// ViewModel do mapa do passageiro (RF07/RF12/RF13/RF18).
///
/// Deriva o estado das streams em tempo real: a cada emissão do nó
/// drivers/ os marcadores e a lista de próximos são recalculados
/// automaticamente, sem intervenção do usuário (RF18).
class PassengerMapController extends Notifier<PassengerMapState> {
  static const FindStopAtPosition _findStop = FindStopAtPosition();

  /// Deslocamento mínimo (m) para recalcular o rumo de um ônibus; abaixo
  /// disso a imprecisão do GPS faria o ícone "tremer" de direção.
  static const double _minMoveMeters = 3;

  /// Última posição e rumo conhecidos de cada ônibus, para virar o ícone
  /// 3D na direção em que ele está andando.
  final Map<String, ({LatLng position, double heading})> _busHeadings =
      <String, ({LatLng position, double heading})>{};

  /// Progresso de cada ônibus ao longo da rota da linha.
  final Map<String, RouteTracker> _trackers = <String, RouteTracker>{};

  /// Paradas posicionadas no traçado de cada linha, recalculadas só
  /// quando a rota ou as paradas mudam.
  final Map<String,
          ({List<LatLng> route, List<Stop> stops, RouteStops value})>
      _routeStops =
      <String, ({List<LatLng> route, List<Stop> stops, RouteStops value})>{};

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

    // Traçado de todas as linhas: vira o ícone de cada ônibus e põe os
    // abrigos das paradas na calçada.
    final Map<String, List<LatLng>> routesByLine = <String, List<LatLng>>{
      for (final Line line in lines)
        line.id: ref.watch(lineRouteProvider(line.id)).valueOrNull ??
            const <LatLng>[],
    };
    // Esquece ônibus que encerraram o trajeto.
    _trackers.removeWhere(
      (String id, _) => !trips.any((Trip trip) => trip.id == id),
    );
    final Map<String, BusApproach> approaches = <String, BusApproach>{
      for (final Trip trip in trips)
        trip.id: _approach(
          trip,
          userPosition,
          routesByLine[trip.lineId] ?? const <LatLng>[],
          stopsByLine[trip.lineId] ?? const <Stop>[],
        ),
    };
    final BusApproach? selectedApproach =
        selectedTrip == null ? null : approaches[selectedTrip.id];

    final Set<Marker> busMarkers = _buildBusMarkers(
      trips,
      linesById,
      stopsByLine,
      routesByLine,
      icons,
    );
    // Os dois mapas do passageiro ficam apontados para o norte.
    final Set<Marker> stopMarkers =
        _buildStopMarkers(stopsByLine, linesById, routesByLine, icons);

    return PassengerMapState(
      markers: <Marker>{...stopMarkers, ...busMarkers},
      stopMarkers: stopMarkers,
      nearbyBuses:
          _buildNearbyBuses(trips, lines, userPosition, approaches),
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
          : selectedApproach?.etaMinutes ??
              (selectedApproach?.passedUserStop ?? false
                  ? null
                  : GeoUtils.estimateArrivalMinutes(
                      userPosition.latitude,
                      userPosition.longitude,
                      selectedTrip.currentLatitude,
                      selectedTrip.currentLongitude,
                    )),
      selectedNextStop: selectedApproach?.nextStop,
      selectedUserStop: selectedApproach?.userStop,
      selectedUserStopMeters: selectedApproach?.userStopMeters,
      selectedPassedUserStop: selectedApproach?.passedUserStop ?? false,
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

  RouteStops _routeStopsFor(
    String lineId,
    List<LatLng> route,
    List<Stop> stops,
  ) {
    final ({List<LatLng> route, List<Stop> stops, RouteStops value})? cached =
        _routeStops[lineId];
    if (cached != null &&
        identical(cached.route, route) &&
        identical(cached.stops, stops)) {
      return cached.value;
    }
    final RouteStops value = RouteStops(route, stops);
    _routeStops[lineId] = (route: route, stops: stops, value: value);
    return value;
  }

  /// Onde o ônibus está em relação às paradas da linha e ao ponto do
  /// passageiro (a parada da linha mais próxima dele), medindo pela rua.
  BusApproach _approach(
    Trip trip,
    LatLng? userPosition,
    List<LatLng> route,
    List<Stop> stops,
  ) {
    if (route.length < 2 || stops.isEmpty) return const BusApproach();
    final RouteSnap? snap = _trackers
        .putIfAbsent(trip.id, RouteTracker.new)
        .locate(route, LatLng(trip.currentLatitude, trip.currentLongitude));
    final Stop? userStop =
        userPosition == null ? null : _nearestStop(stops, userPosition);
    if (snap == null) return BusApproach(userStop: userStop);

    final RouteStops routeStops = _routeStopsFor(trip.lineId, route, stops);
    final double busMeters = routeStops.metersAt(snap);
    return BusApproach(
      onRoute: true,
      nextStop: routeStops.nextStop(busMeters),
      userStop: userStop,
      userStopMeters:
          userStop == null ? null : routeStops.metersTo(userStop, busMeters),
    );
  }

  /// Parada de [stops] mais próxima de [position], em linha reta.
  Stop? _nearestStop(List<Stop> stops, LatLng position) {
    Stop? nearest;
    double nearestKm = double.infinity;
    for (final Stop stop in stops) {
      final double km = MapUtils.distanceInKm(
        position,
        LatLng(stop.latitude, stop.longitude),
      );
      if (km < nearestKm) {
        nearestKm = km;
        nearest = stop;
      }
    }
    return nearest;
  }

  /// Rumo do ônibus: pelo deslocamento desde a última posição; antes do
  /// primeiro deslocamento, pela direção do trecho da rota em que ele está.
  double _headingFor(Trip trip, List<LatLng> route) {
    final LatLng current = LatLng(trip.currentLatitude, trip.currentLongitude);
    final ({LatLng position, double heading})? previous =
        _busHeadings[trip.id];

    if (previous != null) {
      final double movedMeters =
          MapUtils.distanceInKm(previous.position, current) * 1000;
      if (movedMeters < _minMoveMeters) return previous.heading;
      final double heading = MapUtils.bearing(previous.position, current);
      _busHeadings[trip.id] = (position: current, heading: heading);
      return heading;
    }

    double heading = 0;
    if (route.length >= 2) {
      final int index = RouteProgress.nearestIndex(route, current);
      final RouteSnap snap = RouteProgress.snap(route, current, index);
      heading = MapUtils.bearing(
        route[snap.segmentStart],
        route[snap.segmentStart + 1],
      );
    }
    _busHeadings[trip.id] = (position: current, heading: heading);
    return heading;
  }

  Set<Marker> _buildBusMarkers(
    List<Trip> trips,
    Map<String, Line> linesById,
    Map<String, List<Stop>> stopsByLine,
    Map<String, List<LatLng>> routesByLine,
    MapMarkerIcons? icons,
  ) {
    // Esquece ônibus que encerraram o trajeto.
    _busHeadings.removeWhere(
      (String id, _) => !trips.any((Trip trip) => trip.id == id),
    );
    return trips.map((Trip trip) {
      final Line? line = linesById[trip.lineId];
      final Stop? stopHere = _stopHere(trip, stopsByLine);
      final double heading =
          _headingFor(trip, routesByLine[trip.lineId] ?? const <LatLng>[]);
      return Marker(
        markerId: MarkerId('bus_${trip.id}'),
        position: LatLng(trip.currentLatitude, trip.currentLongitude),
        zIndex: 2,
        // Ônibus 3D "em pé", virado na direção em que está andando.
        anchor: const Offset(0.5, 0.5),
        icon: icons?.busFacing(heading) ??
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

  /// Posição e orientação de cada abrigo, calculadas uma vez por traçado
  /// (o estado é recalculado a cada posição nova dos ônibus).
  final Map<String, ({int routeLength, StopDisplay display})> _stopDisplays =
      <String, ({int routeLength, StopDisplay display})>{};

  StopDisplay _stopDisplay(String key, Stop stop, List<LatLng> route) {
    final ({int routeLength, StopDisplay display})? cached =
        _stopDisplays[key];
    if (cached != null && cached.routeLength == route.length) {
      return cached.display;
    }
    final StopDisplay display = StopPlacement.roadside(
      LatLng(stop.latitude, stop.longitude),
      route,
    );
    _stopDisplays[key] = (routeLength: route.length, display: display);
    return display;
  }

  /// Pontos de parada de todas as linhas. Pontos compartilhados (ex.:
  /// Terminal Urbano) viram um único marcador com as linhas que param ali.
  Set<Marker> _buildStopMarkers(
    Map<String, List<Stop>> stopsByLine,
    Map<String, Line> linesById,
    Map<String, List<LatLng>> routesByLine,
    MapMarkerIcons? icons,
  ) {
    final Map<String, ({Stop stop, String lineId})> byPlace =
        <String, ({Stop stop, String lineId})>{};
    final Map<String, Set<String>> linesByPlace = <String, Set<String>>{};
    for (final MapEntry<String, List<Stop>> entry in stopsByLine.entries) {
      for (final Stop stop in entry.value) {
        // ~11 m de precisão: o mesmo ponto físico em linhas diferentes.
        final String key = '${stop.latitude.toStringAsFixed(4)},'
            '${stop.longitude.toStringAsFixed(4)}';
        byPlace.putIfAbsent(key, () => (stop: stop, lineId: entry.key));
        linesByPlace
            .putIfAbsent(key, () => <String>{})
            .add(linesById[entry.key]?.number ?? entry.key);
      }
    }

    return byPlace.entries
        .map((MapEntry<String, ({Stop stop, String lineId})> entry) {
      final Stop stop = entry.value.stop;
      final List<String> numbers = linesByPlace[entry.key]!.toList()..sort();
      // Abrigo na calçada, ao lado do traçado e de frente para a rua.
      return StopMarkers.of(
        id: entry.key,
        stop: stop,
        display: _stopDisplay(
          entry.key,
          stop,
          routesByLine[entry.value.lineId] ?? const <LatLng>[],
        ),
        icons: icons,
        snippet: 'Ponto de embarque — ${numbers.join(', ')}',
        zIndex: 1,
      );
    }).toSet();
  }

  /// Lista "Ônibus próximos" (RF13): ônibus que ainda vão passar no ponto
  /// do passageiro, do que chega primeiro ao que chega por último. A
  /// estimativa é pela rota quando o ônibus está sobre ela; senão, em
  /// linha reta. Ônibus que já passaram pelo ponto ficam de fora.
  List<NearbyBus> _buildNearbyBuses(
    List<Trip> trips,
    List<Line> lines,
    LatLng? userPosition,
    Map<String, BusApproach> approaches,
  ) {
    if (userPosition == null) return const <NearbyBus>[];
    final List<NearbyBus> all = ref.read(getNearbyBusesProvider).call(
          userLatitude: userPosition.latitude,
          userLongitude: userPosition.longitude,
          trips: trips,
          lines: lines,
          maxResults: trips.length,
        );
    final List<NearbyBus> coming = <NearbyBus>[];
    for (final NearbyBus bus in all) {
      final BusApproach? approach = approaches[bus.trip.id];
      if (approach != null && approach.passedUserStop) continue;
      final int? routeEta = approach?.etaMinutes;
      coming.add(
        routeEta == null
            ? bus
            : NearbyBus(
                trip: bus.trip,
                line: bus.line,
                distanceKm: bus.distanceKm,
                etaMinutes: routeEta,
              ),
      );
    }
    coming.sort(
      (NearbyBus a, NearbyBus b) => a.etaMinutes.compareTo(b.etaMinutes),
    );
    return coming.take(kMaxNearbyBuses).toList();
  }
}

/// Provider do [PassengerMapController].
final NotifierProvider<PassengerMapController, PassengerMapState>
    passengerMapControllerProvider =
    NotifierProvider<PassengerMapController, PassengerMapState>(
  PassengerMapController.new,
);
