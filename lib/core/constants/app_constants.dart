/// Constantes globais do aplicativo TranCity.
library;

/// Nome do aplicativo exibido ao usuário.
const String kAppName = 'TranCity';

/// Intervalo de atualização do GPS do motorista (RNF05: máximo 5 segundos).
const Duration kGpsUpdateInterval = Duration(seconds: 5);

/// Tamanho mínimo de senha aceito no cadastro (padrão Firebase Auth).
const int kMinPasswordLength = 6;

/// Quantidade de dígitos de uma CNH válida.
const int kCnhLength = 11;

/// Velocidade média urbana usada na estimativa de chegada (km/h).
const double kAverageBusSpeedKmh = 25;

/// Quantidade máxima de linhas exibidas na lista "Ônibus próximos".
const int kMaxNearbyBuses = 3;
