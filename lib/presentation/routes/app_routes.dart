/// Nomes das rotas nomeadas do aplicativo.
library;

/// Rota inicial: verifica a sessão e redireciona por perfil (RF03/RF20).
const String kSplashRoute = '/';

/// Tela de login (RF02).
const String kLoginRoute = '/login';

/// Tela de cadastro (RF01).
const String kRegisterRoute = '/register';

/// Tela de recuperação de senha (RF17).
const String kForgotPasswordRoute = '/forgot-password';

/// Home do passageiro com Bottom Navigation (RF15/RF19).
const String kPassengerHomeRoute = '/passenger';

/// Detalhes de uma linha: rota, paradas e horários (RF09/RF10).
const String kLineDetailsRoute = '/line-details';

/// Home do motorista com Bottom Navigation (RF14).
const String kDriverHomeRoute = '/driver';
