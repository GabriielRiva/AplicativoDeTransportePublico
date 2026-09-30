import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/map_utils.dart';
import '../../../domain/entities/line.dart';
import '../../../domain/entities/stop.dart';
import '../../../domain/entities/trip.dart';
import '../../controllers/driver_trip_controller.dart';
import '../../providers/line_providers.dart';
import '../../providers/map_icon_providers.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/map/bus_info_card.dart';
import '../../widgets/map/trip_camera_config.dart';
import '../../widgets/map/trip_map_view.dart';

/// Tela de Trajeto do motorista: navegação turn-by-turn com a rota da linha,
/// a posição do veículo seguindo o traçado e o card do trajeto ativo.
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
    final Stop? nextStop = _nearestStop(stops, busPosition);

    return Scaffold(
      body: Stack(
        children: <Widget>[
          TripMapView(
            mode: TripMode.driver,
            busPosition: busPosition,
            route: routePoints,
            heading: state.heading,
            busIcon: icons?.bus,
            interpolationDuration: const Duration(milliseconds: 1200),
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
}
