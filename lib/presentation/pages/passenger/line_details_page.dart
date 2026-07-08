import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/map_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/map_utils.dart';
import '../../../domain/entities/line.dart';
import '../../../domain/entities/schedule.dart';
import '../../../domain/entities/stop.dart';
import '../../../domain/entities/trip.dart';
import '../../controllers/lines_controller.dart';
import '../../providers/bus_providers.dart';
import '../../widgets/lines/route_info_card.dart';
import '../../widgets/lines/schedule_tile.dart';
import '../../widgets/lines/stop_tile.dart';
import '../../widgets/map/bus_map.dart';

/// Tela de detalhes da linha: rota no mapa (polyline), paradas,
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

  void _fitRoute(List<Stop> stops) {
    if (_mapController == null || stops.isEmpty) return;
    final List<LatLng> points = stops
        .map((Stop stop) => LatLng(stop.latitude, stop.longitude))
        .toList();
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

    final List<Trip> lineTrips = (ref
                .watch(activeBusesProvider)
                .valueOrNull ??
            <Trip>[])
        .where((Trip trip) => trip.lineId == widget.line.id)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.line.displayName)),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: BusMap(
              polylines: _buildPolylines(stops),
              markers: _buildMarkers(stops, lineTrips),
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                _fitRoute(stops);
              },
              myLocationEnabled: false,
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

  Set<Polyline> _buildPolylines(List<Stop> stops) {
    if (stops.length < 2) return const <Polyline>{};
    return <Polyline>{
      Polyline(
        polylineId: PolylineId(widget.line.id),
        color: colorFromHex(widget.line.color),
        width: kRoutePolylineWidth,
        points: stops
            .map((Stop stop) => LatLng(stop.latitude, stop.longitude))
            .toList(),
      ),
    };
  }

  Set<Marker> _buildMarkers(List<Stop> stops, List<Trip> trips) {
    final Set<Marker> markers = stops
        .map(
          (Stop stop) => Marker(
            markerId: MarkerId('stop_${stop.id}'),
            position: LatLng(stop.latitude, stop.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
            infoWindow: InfoWindow(title: stop.name),
          ),
        )
        .toSet();

    markers.addAll(
      trips.map(
        (Trip trip) => Marker(
          markerId: MarkerId('bus_${trip.id}'),
          position: LatLng(trip.currentLatitude, trip.currentLongitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(title: 'Ônibus em trajeto'),
        ),
      ),
    );
    return markers;
  }
}
