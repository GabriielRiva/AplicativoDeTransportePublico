import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/bus_remote_datasource.dart';
import '../../data/datasources/driver_remote_datasource.dart';
import '../../data/datasources/firebase_auth_datasource.dart';
import '../../data/datasources/line_remote_datasource.dart';
import '../../data/datasources/schedule_remote_datasource.dart';
import '../../data/datasources/stop_remote_datasource.dart';
import '../../data/datasources/user_remote_datasource.dart';
import 'firebase_providers.dart';

/// Datasource do Firebase Authentication.
final Provider<FirebaseAuthDatasource> firebaseAuthDatasourceProvider =
    Provider<FirebaseAuthDatasource>(
  (Ref ref) => FirebaseAuthDatasource(ref.watch(firebaseAuthProvider)),
);

/// Datasource do nó users/.
final Provider<UserRemoteDatasource> userRemoteDatasourceProvider =
    Provider<UserRemoteDatasource>(
  (Ref ref) => UserRemoteDatasource(ref.watch(firebaseDatabaseProvider)),
);

/// Datasource do nó drivers/.
final Provider<DriverRemoteDatasource> driverRemoteDatasourceProvider =
    Provider<DriverRemoteDatasource>(
  (Ref ref) => DriverRemoteDatasource(ref.watch(firebaseDatabaseProvider)),
);

/// Datasource do nó buses/.
final Provider<BusRemoteDatasource> busRemoteDatasourceProvider =
    Provider<BusRemoteDatasource>(
  (Ref ref) => BusRemoteDatasource(ref.watch(firebaseDatabaseProvider)),
);

/// Datasource do nó lines/.
final Provider<LineRemoteDatasource> lineRemoteDatasourceProvider =
    Provider<LineRemoteDatasource>(
  (Ref ref) => LineRemoteDatasource(ref.watch(firebaseDatabaseProvider)),
);

/// Datasource do nó stops/.
final Provider<StopRemoteDatasource> stopRemoteDatasourceProvider =
    Provider<StopRemoteDatasource>(
  (Ref ref) => StopRemoteDatasource(ref.watch(firebaseDatabaseProvider)),
);

/// Datasource do nó schedules/.
final Provider<ScheduleRemoteDatasource> scheduleRemoteDatasourceProvider =
    Provider<ScheduleRemoteDatasource>(
  (Ref ref) => ScheduleRemoteDatasource(ref.watch(firebaseDatabaseProvider)),
);
