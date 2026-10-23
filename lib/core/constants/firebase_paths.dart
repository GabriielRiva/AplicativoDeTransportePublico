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

/// Nó de CNHs já cadastradas (CNH → UID do motorista). Garante que a mesma
/// CNH não seja usada em duas contas: as regras só aceitam gravar uma CNH
/// que ainda não existe.
const String kCnhsPath = 'cnhs';

/// Nó do perfil de velocidades por faixa de horário (estimativas de tempo).
const String kSpeedProfilePath = 'speedProfile';
