import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/map_constants.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/map_utils.dart';
import '../../../domain/entities/line.dart';
import '../../../domain/usecases/passenger/get_nearby_buses.dart';
import '../../controllers/lines_controller.dart';
import '../../controllers/passenger_map_controller.dart';
import '../../providers/service_providers.dart';
import '../../routes/app_routes.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/map/bus_map.dart';
import '../../widgets/map/nearby_buses_sheet.dart';
import '../../widgets/map/selected_bus_card.dart';

/// Tela inicial do passageiro (RF06 do TCC / RF07, RF12, RF13, RF18):
/// mapa com os ônibus em tempo real, os pontos de parada e a lista de
/// ônibus próximos. Tocar em um ônibus mostra o trajeto que ele vai fazer.
class PassengerMapPage extends ConsumerStatefulWidget {
  /// Cria a tela do mapa do passageiro.
  const PassengerMapPage({super.key});

  @override
  ConsumerState<PassengerMapPage> createState() => _PassengerMapPageState();
}

class _PassengerMapPageState extends ConsumerState<PassengerMapPage> {
  GoogleMapController? _mapController;
  bool _centeredOnUser = false;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _centerOnUser(LatLng position) {
    if (_centeredOnUser || _mapController == null) return;
    _centeredOnUser = true;
    _mapController!.animateCamera(CameraUpdate.newLatLng(position));
  }

  void _fitSelectedRoute(PassengerMapState state) {
    final List<LatLng> points = <LatLng>[
      ...state.selectedRoute,
      if (state.selectedTrip != null)
        LatLng(
          state.selectedTrip!.currentLatitude,
          state.selectedTrip!.currentLongitude,
        ),
    ];
    if (_mapController == null || points.isEmpty) return;
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(MapUtils.boundsFromPoints(points), 64),
    );
  }

  Future<void> _openLineDetails(Line line) async {
    // A tela de detalhes lê paradas e horários do LinesController.
    await ref.read(linesControllerProvider.future);
    ref.read(linesControllerProvider.notifier).selectLine(line);
    if (!mounted) return;
    Navigator.of(context).pushNamed(kLineDetailsRoute, arguments: line);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<Position>>(userPositionProvider,
        (AsyncValue<Position>? previous, AsyncValue<Position> next) {
      if (next.hasError && !next.isLoading) {
        AppSnackbar.showError(
          context,
          ErrorHandler.getUserMessage(next.error!),
        );
      }
      final Position? position = next.valueOrNull;
      if (position != null) {
        _centerOnUser(LatLng(position.latitude, position.longitude));
      }
    });

    // Ao selecionar um ônibus (e o traçado da linha carregar), enquadra o
    // trajeto inteiro na tela.
    ref.listen<String?>(
        passengerMapControllerProvider.select(
          (PassengerMapState s) =>
              s.selectedRoute.isEmpty ? null : s.selectedTrip?.id,
        ), (String? previous, String? next) {
      if (next != null && next != previous) {
        _fitSelectedRoute(ref.read(passengerMapControllerProvider));
      }
    });

    final PassengerMapState state =
        ref.watch(passengerMapControllerProvider);
    final PassengerMapController controller =
        ref.read(passengerMapControllerProvider.notifier);

    return LoadingOverlay(
      isLoading: state.isLoading,
      child: Stack(
        children: <Widget>[
          BusMap(
            markers: state.markers,
            polylines: state.polylines,
            initialTarget: state.userPosition ?? kChapecoCenter,
            onMapCreated: (GoogleMapController mapController) {
              _mapController = mapController;
              final LatLng? user = state.userPosition;
              if (user != null) _centerOnUser(user);
            },
            onTap: (_) => controller.clearSelection(),
          ),
          const SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: AppLogo(fontSize: 28),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: state.selectedTrip != null && state.selectedLine != null
                ? SelectedBusCard(
                    line: state.selectedLine!,
                    etaMinutes: state.selectedEtaMinutes,
                    stopName: state.selectedStopHere?.name,
                    onClose: controller.clearSelection,
                    onOpenDetails: () =>
                        _openLineDetails(state.selectedLine!),
                  )
                : NearbyBusesSheet(
                    buses: state.nearbyBuses,
                    onSelect: (NearbyBus bus) =>
                        controller.selectBus(bus.trip.id),
                  ),
          ),
        ],
      ),
    );
  }
}
