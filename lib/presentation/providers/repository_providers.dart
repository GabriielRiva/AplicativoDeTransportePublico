import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/bus_repository_impl.dart';
import '../../data/repositories/driver_repository_impl.dart';
import '../../data/repositories/line_repository_impl.dart';
import '../../data/repositories/schedule_repository_impl.dart';
import '../../data/repositories/stop_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/bus_repository.dart';
import '../../domain/repositories/driver_repository.dart';
import '../../domain/repositories/line_repository.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../../domain/repositories/stop_repository.dart';
import '../../domain/repositories/user_repository.dart';
import 'datasource_providers.dart';

/// Repositório de autenticação (contrato → implementação Firebase).
final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>(
  (Ref ref) =>
      AuthRepositoryImpl(ref.watch(firebaseAuthDatasourceProvider)),
);

/// Repositório de perfis de usuário.
final Provider<UserRepository> userRepositoryProvider =
    Provider<UserRepository>(
  (Ref ref) => UserRepositoryImpl(ref.watch(userRemoteDatasourceProvider)),
);

/// Repositório de operações do motorista/trajeto.
final Provider<DriverRepository> driverRepositoryProvider =
    Provider<DriverRepository>(
  (Ref ref) =>
      DriverRepositoryImpl(ref.watch(driverRemoteDatasourceProvider)),
);

/// Repositório de ônibus.
final Provider<BusRepository> busRepositoryProvider =
    Provider<BusRepository>(
  (Ref ref) => BusRepositoryImpl(ref.watch(busRemoteDatasourceProvider)),
);

/// Repositório de linhas.
final Provider<LineRepository> lineRepositoryProvider =
    Provider<LineRepository>(
  (Ref ref) => LineRepositoryImpl(ref.watch(lineRemoteDatasourceProvider)),
);

/// Repositório de paradas.
final Provider<StopRepository> stopRepositoryProvider =
    Provider<StopRepository>(
  (Ref ref) => StopRepositoryImpl(ref.watch(stopRemoteDatasourceProvider)),
);

/// Repositório de horários.
final Provider<ScheduleRepository> scheduleRepositoryProvider =
    Provider<ScheduleRepository>(
  (Ref ref) =>
      ScheduleRepositoryImpl(ref.watch(scheduleRemoteDatasourceProvider)),
);
