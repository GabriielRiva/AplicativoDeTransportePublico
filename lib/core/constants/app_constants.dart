/// Constantes globais do aplicativo TranCity.
library;

/// Nome do aplicativo exibido ao usuário.
const String kAppName = 'TranCity';

/// Intervalo de envio da posição do motorista ao Firebase. O RNF05 exige
/// no máximo 5 segundos; o app envia a cada 1 segundo para o passageiro
/// acompanhar o ônibus praticamente em tempo real.
const Duration kGpsUpdateInterval = Duration(seconds: 1);

/// Intervalo de leitura do GPS no aparelho do motorista.
const Duration kGpsSampleInterval = Duration(seconds: 1);

/// Raio (em metros) em que o ônibus é considerado "no ponto": a partir daí
/// o app avisa que o embarque e o desembarque estão liberados.
const double kStopArrivalRadiusMeters = 35;

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
