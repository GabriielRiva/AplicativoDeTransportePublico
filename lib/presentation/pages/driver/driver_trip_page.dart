import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/map_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/map_utils.dart';
import '../../../domain/entities/line.dart';
import '../../../domain/entities/stop.dart';
import '../../../domain/entities/trip.dart';
import '../../controllers/driver_trip_controller.dart';
import '../../providers/line_providers.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/map/bus_info_card.dart';
import '../../widgets/map/bus_map.dart';

/// Tela de Trajeto do motorista: mapa com a rota da linha, a posição
/// atual do veículo e o card do trajeto ativo (wireframe da Figura 2).
class DriverTripPage extends ConsumerWidget {
  /// Cria a tela do trajeto ativo.
  const DriverTripPage({super.key});

  /// Retorna a parada mais próxima da posição atual do veículo,
  /// exibida como "Próximo Ponto" no card do trajeto.
  Stop? _nearestStop(List<Stop> stops, LatLng position) {
    if (stops.isEmpty) return null;
    Stop nearest = stops.first;
    double nearestDistance = double.infinity;
    for (final Stop stop in stops) {
      final double distance = MapUtils.distanceInKm(
        position,
        LatLng(stop.latitude, stop.longitude),
      );
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = stop;
      }
    }
    return nearest;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    final Line? line = state.selectedLine;
    final List<Stop> stops =
        ref.watch(lineStopsProvider(trip.lineId)).valueOrNull ?? <Stop>[];
    final LatLng busPosition =
        LatLng(trip.currentLatitude, trip.currentLongitude);
    final Stop? nextStop = _nearestStop(stops, busPosition);

    return Scaffold(
      body: Stack(
        children: <Widget>[
          BusMap(
            initialTarget: busPosition,
            initialZoom: kBusFocusZoom,
            polylines: _buildPolylines(line, stops),
            markers: <Marker>{
              Marker(
                markerId: MarkerId(trip.id),
                position: busPosition,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ),
                infoWindow: InfoWindow(
                  title: line?.displayName ?? 'Trajeto ativo',
                ),
              ),
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: BusInfoCard(
              title: line?.displayName ?? 'Trajeto ativo',
              subtitle: 'Ônibus: #${state.selectedBus?.number ?? '-'}',
              estimatedTime: line == null
                  ? null
                  : Formatters.durationMinutes(line.averageDuration),
              nextStop: nextStop?.name,
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

  Set<Polyline> _buildPolylines(Line? line, List<Stop> stops) {
    if (line == null || stops.length < 2) return const <Polyline>{};
    return <Polyline>{
      Polyline(
        polylineId: PolylineId(line.id),
        color: colorFromHex(line.color),
        width: kRoutePolylineWidth,
        points: stops
            .map((Stop stop) => LatLng(stop.latitude, stop.longitude))
            .toList(),
      ),
    };
  }
}
