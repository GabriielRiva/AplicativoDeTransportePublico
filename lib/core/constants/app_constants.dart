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

/// Precisão (m) mínima de uma leitura do GPS para mover o ônibus. Leituras
/// piores (sinal fraco, dentro de prédios, celular balançando) são
/// ignoradas e o ônibus fica na última posição confiável.
const double kGpsMaxAccuracyMeters = 40;

/// Precisão (m) aceita depois de [kGpsStaleAfter] só com leituras
/// imprecisas, para o ônibus não ficar parado para sempre com sinal ruim.
const double kGpsMaxAccuracyStaleMeters = 100;

/// Tempo só com leituras imprecisas a partir do qual o filtro do GPS
/// afrouxa (ver [kGpsMaxAccuracyStaleMeters]).
const Duration kGpsStaleAfter = Duration(seconds: 15);

/// Velocidade (m/s) acima da qual um salto entre duas leituras é
/// impossível para um ônibus urbano (~120 km/h): é erro do GPS.
const double kGpsMaxSpeedMps = 33;

/// Velocidade (m/s) a partir da qual o ônibus é considerado em movimento
/// (~5 km/h). Parado, o rumo informado pelo GPS é aleatório e é ignorado.
const double kGpsMovingSpeedMps = 1.5;

/// Deslocamento (m) mínimo, com o ônibus parado, para mover o ônibus no
/// mapa. Abaixo disso é só a oscilação normal do GPS.
const double kGpsMinMoveMeters = 5;

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

/// Tempo sem atualização de posição a partir do qual um ônibus deixa de
/// aparecer para o passageiro ("ônibus fantasma": app do motorista fechado,
/// sem bateria ou sem sinal antes de encerrar o trajeto).
const Duration kBusStaleAfter = Duration(minutes: 2);

/// De quanto em quanto tempo o app do passageiro confere se algum ônibus
/// ficou sem atualização por mais de [kBusStaleAfter].
const Duration kBusStaleCheckInterval = Duration(seconds: 15);

/// Intervalo máximo entre dois envios de posição do motorista, mesmo com o
/// ônibus parado (no ponto, no semáforo, no terminal). Mantém o ônibus
/// visível para o passageiro, bem abaixo de [kBusStaleAfter].
const Duration kDriverHeartbeatInterval = Duration(seconds: 30);
