/// Constantes globais do aplicativo TranCity.
library;

/// Nome do aplicativo exibido ao usuário.
const String kAppName = 'TranCity';

/// Intervalo de envio da posição do motorista ao Firebase
/// (RNF05: máximo 5 segundos).
const Duration kGpsUpdateInterval = Duration(seconds: 5);

/// Intervalo de leitura do GPS no aparelho do motorista. Mais curto que o
/// envio para que o mapa do próprio motorista se mova de forma contínua;
/// o envio ao Firebase continua limitado por [kGpsUpdateInterval].
const Duration kGpsSampleInterval = Duration(seconds: 1);

/// Tamanho mínimo de senha aceito no cadastro (padrão Firebase Auth).
const int kMinPasswordLength = 6;

/// Quantidade de dígitos de uma CNH válida.
const int kCnhLength = 11;

/// Velocidade média urbana usada na estimativa de chegada (km/h).
const double kAverageBusSpeedKmh = 25;

/// Quantidade máxima de linhas exibidas na lista "Ônibus próximos".
const int kMaxNearbyBuses = 3;

/// Deslocamento mínimo (em metros) do passageiro para o app recalcular a
/// lista "Ônibus próximos". A posição do passageiro só é usada no próprio
/// aparelho e nunca é enviada ao Firebase.
const int kPassengerDistanceFilterMeters = 25;
