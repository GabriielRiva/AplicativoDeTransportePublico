import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/auth/get_current_user.dart';
import '../../domain/usecases/auth/login_user.dart';
import '../../domain/usecases/auth/logout_user.dart';
import '../../domain/usecases/auth/recover_password.dart';
import '../../domain/usecases/auth/register_user.dart';
import '../../domain/usecases/auth/watch_auth_state.dart';
import '../../domain/usecases/driver/finish_trip.dart';
import '../../domain/usecases/driver/get_buses_by_line.dart';
import '../../domain/usecases/driver/send_location.dart';
import '../../domain/usecases/driver/start_trip.dart';
import '../../domain/usecases/driver/update_driver_status.dart';
import '../../domain/usecases/passenger/favorite_line.dart';
import '../../domain/usecases/passenger/get_line_schedules.dart';
import '../../domain/usecases/passenger/get_line_stops.dart';
import '../../domain/usecases/passenger/get_lines.dart';
import '../../domain/usecases/passenger/get_nearby_buses.dart';
import '../../domain/usecases/passenger/watch_active_buses.dart';
import 'repository_providers.dart';
import 'service_providers.dart';

// ---------------------------------------------------------------- Auth

/// Usecase de cadastro (RF01).
final Provider<RegisterUser> registerUserProvider = Provider<RegisterUser>(
  (Ref ref) => RegisterUser(
    ref.watch(authRepositoryProvider),
    ref.watch(userRepositoryProvider),
  ),
);

/// Usecase de login (RF02).
final Provider<LoginUser> loginUserProvider = Provider<LoginUser>(
  (Ref ref) => LoginUser(
    ref.watch(authRepositoryProvider),
    ref.watch(userRepositoryProvider),
  ),
);

/// Usecase de logout (RF16).
final Provider<LogoutUser> logoutUserProvider = Provider<LogoutUser>(
  (Ref ref) => LogoutUser(ref.watch(authRepositoryProvider)),
);

/// Usecase de recuperação de senha (RF17).
final Provider<RecoverPassword> recoverPasswordProvider =
    Provider<RecoverPassword>(
  (Ref ref) => RecoverPassword(ref.watch(authRepositoryProvider)),
);

/// Usecase que retorna o perfil da sessão atual (RF03/RF20).
final Provider<GetCurrentUser> getCurrentUserProvider =
    Provider<GetCurrentUser>(
  (Ref ref) => GetCurrentUser(
    ref.watch(authRepositoryProvider),
    ref.watch(userRepositoryProvider),
  ),
);

/// Usecase que observa o estado da sessão (RF20).
final Provider<WatchAuthState> watchAuthStateProvider =
    Provider<WatchAuthState>(
  (Ref ref) => WatchAuthState(ref.watch(authRepositoryProvider)),
);

// -------------------------------------------------------------- Driver

/// Usecase de início de trajeto (RF04).
final Provider<StartTrip> startTripProvider = Provider<StartTrip>(
  (Ref ref) => StartTrip(
    ref.watch(driverRepositoryProvider),
    ref.watch(networkInfoProvider),
  ),
);

/// Usecase de encerramento de trajeto (RF05).
final Provider<FinishTrip> finishTripProvider = Provider<FinishTrip>(
  (Ref ref) => FinishTrip(ref.watch(driverRepositoryProvider)),
);

/// Usecase de transmissão de localização (RF06).
final Provider<SendLocation> sendLocationProvider = Provider<SendLocation>(
  (Ref ref) => SendLocation(ref.watch(driverRepositoryProvider)),
);

/// Usecase de atualização de status do motorista.
final Provider<UpdateDriverStatus> updateDriverStatusProvider =
    Provider<UpdateDriverStatus>(
  (Ref ref) => UpdateDriverStatus(ref.watch(driverRepositoryProvider)),
);

/// Usecase de listagem de ônibus por linha.
final Provider<GetBusesByLine> getBusesByLineProvider =
    Provider<GetBusesByLine>(
  (Ref ref) => GetBusesByLine(ref.watch(busRepositoryProvider)),
);

// ----------------------------------------------------------- Passenger

/// Usecase que observa os ônibus ativos (RF07/RF12/RF18).
final Provider<WatchActiveBuses> watchActiveBusesProvider =
    Provider<WatchActiveBuses>(
  (Ref ref) => WatchActiveBuses(ref.watch(driverRepositoryProvider)),
);

/// Usecase de listagem de linhas (RF08).
final Provider<GetLines> getLinesProvider = Provider<GetLines>(
  (Ref ref) => GetLines(ref.watch(lineRepositoryProvider)),
);

/// Usecase de consulta de paradas de uma linha (RF09).
final Provider<GetLineStops> getLineStopsProvider = Provider<GetLineStops>(
  (Ref ref) => GetLineStops(ref.watch(stopRepositoryProvider)),
);

/// Usecase de consulta de horários de uma linha (RF10).
final Provider<GetLineSchedules> getLineSchedulesProvider =
    Provider<GetLineSchedules>(
  (Ref ref) => GetLineSchedules(ref.watch(scheduleRepositoryProvider)),
);

/// Usecase de cálculo dos ônibus próximos (RF13).
final Provider<GetNearbyBuses> getNearbyBusesProvider =
    Provider<GetNearbyBuses>((Ref ref) => const GetNearbyBuses());

/// Usecase de linhas favoritas.
final Provider<FavoriteLine> favoriteLineProvider = Provider<FavoriteLine>(
  (Ref ref) => FavoriteLine(ref.watch(userRepositoryProvider)),
);
