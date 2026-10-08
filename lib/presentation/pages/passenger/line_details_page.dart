import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/map_utils.dart';
import '../../../domain/entities/line.dart';
import '../../../domain/entities/schedule.dart';
import '../../../domain/entities/speed_profile.dart';
import '../../../domain/entities/stop.dart';
import '../../../domain/entities/trip.dart';
import '../../../domain/usecases/passenger/estimate_between_stops.dart';
import '../../../domain/usecases/passenger/find_stop_at_position.dart';
import '../../../domain/usecases/passenger/predict_stop_times.dart';
import '../../controllers/lines_controller.dart';
import '../../providers/bus_providers.dart';
import '../../providers/line_providers.dart';
import '../../providers/map_icon_providers.dart';
import '../../providers/speed_profile_providers.dart';
import '../../widgets/lines/route_info_card.dart';
import '../../widgets/lines/schedule_tile.dart';
import '../../widgets/lines/stop_tile.dart';
import '../../widgets/lines/stop_to_stop_sheet.dart';
import '../../widgets/lines/stop_times_sheet.dart';
import '../../widgets/map/bus_map.dart';
import '../../widgets/map/route_stops.dart';
import '../../widgets/map/stop_arrival_banner.dart';
import '../../widgets/map/stop_markers.dart';
import '../../widgets/map/trip_camera_config.dart';
import '../../widgets/map/trip_map_view.dart';

/// Tela de detalhes da linha: rota de rua no mapa, acompanhamento do ônibus
/// em tempo real (tracking, no estilo "carrinho deslizando"), paradas,
/// horários e o painel "Rota Detalhada" (RF09/RF10).
class LineDetailsPage extends ConsumerStatefulWidget {
  /// Cria a tela com a [line] selecionada.
  const LineDetailsPage({required this.line, super.key});

  /// Linha exibida em detalhes.
  final Line line;

  @override
  ConsumerState<LineDetailsPage> createState() => _LineDetailsPageState();
}

class _LineDetailsPageState extends ConsumerState<LineDetailsPage> {
  GoogleMapController? _mapController;

  /// Paradas posicionadas no traçado, recalculadas só quando a rota ou as
  /// paradas mudam (a tela é reconstruída a cada posição do ônibus).
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

  /// Tempo estimado do ponto anterior até cada ponto, saindo agora
  /// (texto exibido embaixo do nome de cada parada).
  Map<String, String> _legTimes(RouteStops routeStops, SpeedProfile profile) {
    final List<Stop> ordered = routeStops.stops;
    final DateTime now = DateTime.now();
    final Map<String, String> legs = <String, String>{};
    for (int i = 0; i < ordered.length; i++) {
      if (i == 0) {
        legs[ordered[i].id] = 'Início da linha';
        continue;
      }
      final StopToStop? leg = const EstimateBetweenStops()(
        stopMeters: routeStops.stopMeters,
        from: i - 1,
        to: i,
        isCircular: routeStops.isCircular,
        totalMeters: routeStops.totalMeters,
        profile: profile,
        departure: now,
      );
      if (leg != null) {
        legs[ordered[i].id] = '~${leg.minutes} min desde o ponto anterior';
      }
    }
    return legs;
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _fitRoute(List<LatLng> points) {
    if (_mapController == null || points.isEmpty) return;
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(MapUtils.boundsFromPoints(points), 48),
    );
  }

  /// Abre o horário previsto em cada ponto para a saída [schedule].
  void _showStopTimes(
    Schedule schedule,
    List<LatLng> route,
    List<Stop> stops,
    SpeedProfile profile,
  ) {
    // Distância pela rua do início da linha até cada ponto.
    final RouteStops routeStops = _routeStopsFor(route, stops);
    StopTimesSheet.show(
      context,
      schedule: schedule,
      profile: profile,
      times: const PredictStopTimes()(
        schedule: schedule,
        stops: routeStops.stops,
        stopMeters: routeStops.stopMeters,
        profile: profile,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SpeedProfile profile =
        ref.watch(speedProfileProvider).valueOrNull ?? SpeedProfile.fallback;
    final LinesState? state =
        ref.watch(linesControllerProvider).valueOrNull;
    final List<Stop> stops = state?.stops ?? <Stop>[];
    final List<Schedule> schedules = state?.schedules ?? <Schedule>[];
    final bool isLoadingDetails = state?.isLoadingDetails ?? true;
    final MapMarkerIcons? icons =
        ref.watch(markerIconsProvider).valueOrNull;

    final List<LatLng> streetRoute =
        ref.watch(lineRouteProvider(widget.line.id)).valueOrNull ??
            <LatLng>[];
    final List<LatLng> routePoints = streetRoute.isNotEmpty
        ? streetRoute
        : stops
            .map((Stop stop) => LatLng(stop.latitude, stop.longitude))
            .toList();

    final List<Trip> lineTrips = (ref
                .watch(activeBusesProvider)
                .valueOrNull ??
            <Trip>[])
        .where((Trip trip) => trip.lineId == widget.line.id)
        .toList();
    final Trip? activeBus = lineTrips.isNotEmpty ? lineTrips.first : null;
    final RouteStops? routeStops =
        stops.isEmpty ? null : _routeStopsFor(routePoints, stops);
    final Map<String, String> legTimes = routeStops == null
        ? const <String, String>{}
        : _legTimes(routeStops, profile);
    final Stop? stopHere = activeBus == null
        ? null
        : const FindStopAtPosition()(
            stops: stops,
            latitude: activeBus.currentLatitude,
            longitude: activeBus.currentLongitude,
          );

    return Scaffold(
      appBar: AppBar(title: Text(widget.line.displayName)),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: activeBus == null
                ? BusMap(
                    polylines: _buildPolylines(routePoints),
                    markers: StopMarkers.forLine(stops, routePoints, icons),
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                      _fitRoute(routePoints);
                    },
                  )
                : Stack(
                    children: <Widget>[
                      TripMapView(
                        mode: TripMode.passenger,
                        showMyLocation: true,
                        busPosition: LatLng(
                          activeBus.currentLatitude,
                          activeBus.currentLongitude,
                        ),
                        route: routePoints,
                        follow: false,
                        extraMarkers: StopMarkers.forLine(
                          stops,
                          routePoints,
                          icons,
                        ),
                        // Ônibus 3D virado na direção em que está andando.
                        busIcon: icons?.bus,
                        busIconForHeading: icons?.busFacing,
                        rotateBusIcon: false,
                        // Posições chegam a cada kGpsUpdateInterval (1 s):
                        // a animação dura o mesmo, sem paradas entre elas.
                        interpolationDuration: kGpsUpdateInterval,
                      ),
                      if (stopHere != null)
                        Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: StopArrivalBanner(stopName: stopHere.name),
                          ),
                        ),
                    ],
                  ),
          ),
          Expanded(
            flex: 3,
            child: isLoadingDetails
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    children: <Widget>[
                      RouteInfoCard(
                        line: widget.line,
                        stopsCount: stops.length,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Horários de Saída',
                          style: AppTextStyles.title,
                        ),
                      ),
                      if (schedules.isNotEmpty && stops.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 2, 16, 0),
                          child: Text(
                            'Toque em um horário para ver a previsão de '
                            'passagem em cada ponto.',
                            style: AppTextStyles.caption,
                          ),
                        ),
                      if (schedules.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Nenhum horário cadastrado para esta linha.',
                            style: AppTextStyles.caption,
                          ),
                        )
                      else
                        ...schedules.map(
                          (Schedule schedule) => ScheduleTile(
                            schedule: schedule,
                            onTap: stops.isEmpty
                                ? null
                                : () => _showStopTimes(
                                      schedule,
                                      routePoints,
                                      stops,
                                      profile,
                                    ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 8),
                        child: Row(
                          children: <Widget>[
                            const Expanded(
                              child: Text(
                                'Pontos de Parada',
                                style: AppTextStyles.title,
                              ),
                            ),
                            if (routeStops != null && stops.length > 1)
                              TextButton.icon(
                                onPressed: () => StopToStopSheet.show(
                                  context,
                                  routeStops: routeStops,
                                  profile: profile,
                                ),
                                icon: const Icon(Icons.timer_outlined),
                                label: const Text('Tempo entre pontos'),
                              ),
                          ],
                        ),
                      ),
                      if (stops.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Nenhum ponto cadastrado para esta linha.',
                            style: AppTextStyles.caption,
                          ),
                        )
                      else
                        ...stops.map(
                          (Stop stop) => StopTile(
                            stop: stop,
                            subtitle: legTimes[stop.id],
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Set<Polyline> _buildPolylines(List<LatLng> points) {
    if (points.length < 2) return const <Polyline>{};
    return <Polyline>{
      MapUtils.routePolyline(
        id: widget.line.id,
        color: colorFromHex(widget.line.color),
        points: points,
      ),
    };
  }
}
