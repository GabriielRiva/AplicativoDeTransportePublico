/// Caminhos (nós) do Firebase Realtime Database, conforme FIREBASE_SCHEMA.md.
library;

/// Nó de perfis de usuário, indexado pelo UID do Firebase Auth.
const String kUsersPath = 'users';

/// Nó de motoristas em circulação (localização e status em tempo real).
const String kDriversPath = 'drivers';

/// Nó de linhas de ônibus.
const String kLinesPath = 'lines';

/// Nó de pontos de parada.
const String kStopsPath = 'stops';

/// Nó de horários de saída.
const String kSchedulesPath = 'schedules';

/// Nó de ônibus cadastrados.
const String kBusesPath = 'buses';
