import '../../providers/navigation_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/enums/driver_status.dart';
import '../../../domain/entities/line.dart';
import '../../../domain/entities/user.dart';
import '../../controllers/driver_trip_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../providers/line_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/usecase_providers.dart';
import '../../routes/app_routes.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/driver/bus_selector.dart';
import '../../widgets/driver/gps_status_indicator.dart';
import '../../widgets/driver/line_selector.dart';
import '../../widgets/driver/trip_action_buttons.dart';
import '../../widgets/driver/trip_status_card.dart';
import '../../widgets/driver/vehicle_info_card.dart';

/// Tela principal do motorista (Figura 9 do TCC — RF04/RF05/RF14):
/// status do GPS, seleção de linha/ônibus e controle do trajeto.
class DriverProfilePage extends ConsumerWidget {
  /// Cria a tela do perfil do motorista.
  const DriverProfilePage({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    // Encerra um trajeto ativo e marca o motorista como offline antes
    // de sair, evitando um ônibus "fantasma" no mapa dos passageiros.
    await ref.read(driverTripControllerProvider.notifier).finishTrip();
    final String? uid = ref.read(authRepositoryProvider).currentUid;
    if (uid != null) {
      await ref
          .read(updateDriverStatusProvider)
          .call(uid, DriverStatus.offline);
    }
    final bool success =
        await ref.read(profileControllerProvider.notifier).logout();
    if (success && context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        kLoginRoute,
        (Route<dynamic> _) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<DriverTripState>(driverTripControllerProvider,
        (DriverTripState? previous, DriverTripState next) {
      final String? error = next.errorMessage;
      if (error != null) {
        AppSnackbar.showError(context, error);
        ref.read(driverTripControllerProvider.notifier).clearError();
      }
    });

    final DriverTripState tripState =
        ref.watch(driverTripControllerProvider);
    final User? user = ref.watch(profileControllerProvider).valueOrNull;
    final List<Line> lines =
        ref.watch(linesProvider).valueOrNull ?? <Line>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Motorista'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair da Conta',
            onPressed: () => _logout(context, ref),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: tripState.isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: kPrimaryColor,
                    child:
                        Icon(Icons.person, size: 36, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          user?.name ?? 'Motorista',
                          style: AppTextStyles.headline
                              .copyWith(fontSize: 22),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Bem-Vindo${user == null ? '' : ', '
                              '${user.name.split(' ').first}'}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GpsStatusIndicator(isTransmitting: tripState.isTransmitting),
              const SizedBox(height: 24),
              const Text('Selecionar Linha', style: AppTextStyles.body),
              const SizedBox(height: 8),
              LineSelector(
                lines: lines,
                selected: tripState.selectedLine,
                enabled: !tripState.isTransmitting,
                onChanged: ref
                    .read(driverTripControllerProvider.notifier)
                    .selectLine,
              ),
              const SizedBox(height: 16),
              BusSelector(
                buses: tripState.availableBuses,
                selected: tripState.selectedBus,
                enabled: !tripState.isTransmitting &&
                    tripState.availableBuses.isNotEmpty,
                onChanged: ref
                    .read(driverTripControllerProvider.notifier)
                    .selectBus,
              ),
              const SizedBox(height: 24),
              TripStatusCard(status: tripState.status),
              const SizedBox(height: 16),
                 TripActionButtons(
                canStart: tripState.canStartTrip,
                canFinish: tripState.isTransmitting,
                onStart: () async {
                  await ref
                      .read(driverTripControllerProvider.notifier)
                      .startTrip();
                  // Se iniciou de fato, vai para a aba Trajeto.
                  if (ref.read(driverTripControllerProvider).isTransmitting) {
                    ref.read(driverNavIndexProvider.notifier).state = 0;
                  }
                },
                onFinish: ref
                    .read(driverTripControllerProvider.notifier)
                    .finishTrip,
              ),
              const SizedBox(height: 24),
              VehicleInfoCard(bus: tripState.selectedBus),
            ],
          ),
        ),
      ),
    );
  }
}