import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/map_constants.dart';
import '../../../core/errors/error_handler.dart';
import '../../controllers/passenger_map_controller.dart';
import '../../providers/service_providers.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/map/bus_map.dart';
import '../../widgets/map/nearby_buses_sheet.dart';

/// Tela inicial do passageiro (RF06 do TCC / RF07, RF12, RF13, RF18):
/// mapa com os ônibus em tempo real e a lista de ônibus próximos.
class PassengerMapPage extends ConsumerWidget {
  /// Cria a tela do mapa do passageiro.
  const PassengerMapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<Position>>(userPositionProvider,
        (AsyncValue<Position>? previous, AsyncValue<Position> next) {
      if (next.hasError && !next.isLoading) {
        AppSnackbar.showError(
          context,
          ErrorHandler.getUserMessage(next.error!),
        );
      }
    });

    final PassengerMapState state =
        ref.watch(passengerMapControllerProvider);

    return LoadingOverlay(
      isLoading: state.isLoading,
      child: Stack(
        children: <Widget>[
          BusMap(
            markers: state.markers,
            initialTarget: state.userPosition ?? kChapecoCenter,
          ),
          const SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: AppLogo(fontSize: 28),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: NearbyBusesSheet(buses: state.nearbyBuses),
          ),
        ],
      ),
    );
  }
}
