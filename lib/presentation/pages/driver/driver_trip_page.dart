import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/map_utils.dart';
import '../../../domain/entities/line.dart';
import '../../../domain/entities/stop.dart';
import '../../../domain/entities/trip.dart';
import '../../../domain/usecases/passenger/find_stop_at_position.dart';
import '../../controllers/driver_trip_controller.dart';
import '../../providers/line_providers.dart';
import '../../providers/map_icon_providers.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/map/bus_info_card.dart';
import '../../widgets/map/route_progress.dart';
import '../../widgets/map/route_stops.dart';
import '../../widgets/map/stop_arrival_banner.dart';
import '../../widgets/map/stop_markers.dart';
import '../../widgets/map/trip_camera_config.dart';
import '../../widgets/map/trip_map_view.dart';

/// Tela de Trajeto do motorista: navegação turn-by-turn com a rota da linha,
/// a posição do veículo seguindo o traçado e o card do trajeto ativo, com a
/// próxima parada à frente e a distância até ela pela rua.
class DriverTripPage extends ConsumerStatefulWidget {
  /// Cria a tela do trajeto ativo.
  const DriverTripPage({super.key});

  @override
  ConsumerState<DriverTripPage> createState() => _DriverTripPageState();
}

class _DriverTripPageState extends ConsumerState<DriverTripPage> {
  /// Progresso do ônibus ao longo da rota (só avança, ver RouteProgress).
  RouteTracker _tracker = RouteTracker();
  String? _trackedTripId;

  /// Paradas posicionadas no traçado, recalculadas só quando a rota ou as
  /// paradas mudam.
  RouteStops? _routeStops;
  List<LatLng>? _routeStopsRoute;
  List<Stop>? _routeStopsStops;

  RouteStops _routeStopsFor(List<LatLng> route, List<Stop> stops) {
    final RouteStops? cached = _routeStops;
    if (cached != null &&
        identical(route, _routeStopsRoute) &&
        identical(stops, _routeStopsStops)) {
      return cached;
    }
    _routeStopsRoute = route;
    _routeStopsStops = stops;
    return _routeStops = RouteStops(route, stops);
  }

  /// Próxima parada à frente do ônibus e a distância pela rota. Fora da
  /// rota (ex.: ainda indo para o início), usa a parada mais próxima em
  /// linha reta.
  StopAhead? _nextStop(
    String tripId,
    List<LatLng> route,
    List<Stop> stops,
    LatLng position,
  ) {
    if (stops.isEmpty) return null;
    if (_trackedTripId != tripId) {
      _trackedTripId = tripId;
      _tracker = RouteTracker();
    }
    final RouteSnap? snap = _tracker.locate(route, position);
    if (snap != null) {
      final RouteStops routeStops = _routeStopsFor(route, stops);
      return routeStops.nextStop(routeStops.metersAt(snap));
    }

    Stop nearest = stops.first;
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
    return (stop: nearest, meters: nearestKm * 1000);
  }

  @override
  Widget build(BuildContext context) {
    final DriverTripState state = ref.watch(driverTripControllerProvider);
    final Trip? trip = state.activeTrip;

    if (trip == null || !state.isTransmitting) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.route_outlined,
          title: 'Nenhum trajeto ativo',
          message: 'Inicie um trajeto na aba Perfil para visualizar a '
              'rota e a transmissão de GPS em tempo real.',
        ),
      );
    }

    final MapMarkerIcons? icons =
        ref.watch(markerIconsProvider).valueOrNull;

    final List<Line> allLines =
        ref.watch(linesProvider).valueOrNull ?? <Line>[];
    final Line? line = state.selectedLine ??
        allLines.where((Line l) => l.id == trip.lineId).firstOrNull;

    final List<Stop> stops =
        ref.watch(lineStopsProvider(trip.lineId)).valueOrNull ?? <Stop>[];
    final List<LatLng> streetRoute =
        ref.watch(lineRouteProvider(trip.lineId)).valueOrNull ?? <LatLng>[];
    final List<LatLng> routePoints = streetRoute.isNotEmpty
        ? streetRoute
        : stops
            .map((Stop stop) => LatLng(stop.latitude, stop.longitude))
            .toList();

    final LatLng busPosition =
        LatLng(trip.currentLatitude, trip.currentLongitude);
    final StopAhead? nextStop =
        _nextStop(trip.id, routePoints, stops, busPosition);
    final Stop? stopHere = const FindStopAtPosition()(
      stops: stops,
      latitude: trip.currentLatitude,
      longitude: trip.currentLongitude,
    );

    return Scaffold(
      body: Stack(
        children: <Widget>[
          TripMapView(
            mode: TripMode.driver,
            busPosition: busPosition,
            route: routePoints,
            extraMarkers: StopMarkers.forLine(
              stops,
              routePoints,
              icons,
              cameraBearing: state.heading,
            ),
            heading: state.heading,
            // Ônibus 3D visto de trás: a câmera do motorista gira junto com
            // o ônibus, então ele aparece sempre de costas, em pé na tela.
            busIcon: icons?.bus3d,
            rotateBusIcon: false,
            busIconAnchor: kBus3dAnchor,
            // Ônibus no terço de baixo da área visível (acima do card),
            // como nos apps de navegação: mais rua à frente na tela.
            mapPadding: EdgeInsets.only(
              top: MediaQuery.sizeOf(context).height * 0.32,
              bottom: 240,
            ),
            // Mesma duração da leitura do GPS: o ônibus termina um trecho
            // quando chega a próxima posição, sem paradas entre leituras.
            interpolationDuration: kGpsSampleInterval,
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (!state.isOnline) const _OfflineBanner(),
                    if (!state.isOnline && stopHere != null)
                      const SizedBox(height: 8),
                    if (stopHere != null)
                      StopArrivalBanner(stopName: stopHere.name),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: BusInfoCard(
              title: line?.displayName ?? 'Trajeto ativo',
              subtitle: 'Ônibus: #${state.selectedBus?.number ?? '-'}',
              estimatedTime: line == null
                  ? null
                  : Formatters.durationMinutes(line.averageDuration),
              nextStop: nextStop?.stop.name,
              nextStopDistance: nextStop == null
                  ? null
                  : Formatters.distanceMeters(nextStop.meters),
              action: AppButton(
                label: 'Encerrar Trajeto',
                color: kErrorColor,
                onPressed: ref
                    .read(driverTripControllerProvider.notifier)
                    .finishTrip,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Aviso de que o aparelho do motorista perdeu a conexão com a internet.
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF4E5),
      elevation: 3,
      borderRadius: BorderRadius.circular(12),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.wifi_off, color: Color(0xFFB45309)),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                'Sem conexão. Os passageiros voltam a ver o ônibus '
                'quando a internet voltar.',
                style: TextStyle(fontSize: 14, color: Color(0xFF7C2D12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
