import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/map_utils.dart';
import '../../../domain/entities/line.dart';
import '../../../domain/entities/schedule.dart';
import '../../../domain/entities/stop.dart';
import '../../../domain/entities/trip.dart';
import '../../../domain/usecases/passenger/find_stop_at_position.dart';
import '../../controllers/lines_controller.dart';
import '../../providers/bus_providers.dart';
import '../../providers/line_providers.dart';
import '../../providers/map_icon_providers.dart';
import '../../widgets/lines/route_info_card.dart';
import '../../widgets/lines/schedule_tile.dart';
import '../../widgets/lines/stop_tile.dart';
import '../../widgets/map/bus_map.dart';
import '../../widgets/map/stop_arrival_banner.dart';
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

  @override
  Widget build(BuildContext context) {
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
                    markers: _buildStopMarkers(stops, icons),
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
                        extraMarkers: _buildStopMarkers(stops, icons),
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
                          (Schedule schedule) =>
                              ScheduleTile(schedule: schedule),
                        ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Pontos de Parada',
                          style: AppTextStyles.title,
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
                        ...stops.map((Stop stop) => StopTile(stop: stop)),
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

  Set<Marker> _buildStopMarkers(List<Stop> stops, MapMarkerIcons? icons) {
    return stops
        .map(
          (Stop stop) => Marker(
            markerId: MarkerId('stop_${stop.id}'),
            position: LatLng(stop.latitude, stop.longitude),
            anchor: icons?.stopAnchor ?? const Offset(0.5, 1),
            icon: icons?.stop ??
                BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure,
                ),
            infoWindow: InfoWindow(title: stop.name),
          ),
        )
        .toSet();
  }
}
