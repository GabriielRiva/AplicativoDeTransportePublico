import 'package:flutter/material.dart';

import '../../domain/entities/enums/user_role.dart';
import '../../domain/entities/line.dart';
import '../pages/auth/forgot_password_page.dart';
import '../pages/auth/login_page.dart';
import '../pages/auth/register_page.dart';
import '../pages/driver/driver_home_page.dart';
import '../pages/passenger/line_details_page.dart';
import '../pages/passenger/passenger_home_page.dart';
import '../pages/splash/splash_page.dart';
import '../widgets/common/empty_state.dart';
import 'app_routes.dart';

/// Retorna a rota da home correspondente ao perfil do usuário (RF03).
String homeRouteForRole(UserRole role) {
  return role == UserRole.driver ? kDriverHomeRoute : kPassengerHomeRoute;
}

/// Gerador central de rotas nomeadas do aplicativo.
abstract final class AppRouter {
  /// Resolve o [settings.name] para a página correspondente.
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case kSplashRoute:
        return _page(const SplashPage(), settings);
      case kLoginRoute:
        return _page(const LoginPage(), settings);
      case kRegisterRoute:
        return _page(const RegisterPage(), settings);
      case kForgotPasswordRoute:
        return _page(const ForgotPasswordPage(), settings);
      case kPassengerHomeRoute:
        return _page(const PassengerHomePage(), settings);
      case kDriverHomeRoute:
        return _page(const DriverHomePage(), settings);
      case kLineDetailsRoute:
        final Object? args = settings.arguments;
        if (args is Line) {
          return _page(LineDetailsPage(line: args), settings);
        }
        return _errorRoute(settings);
      default:
        return _errorRoute(settings);
    }
  }

  static MaterialPageRoute<dynamic> _page(
    Widget page,
    RouteSettings settings,
  ) {
    return MaterialPageRoute<dynamic>(
      builder: (BuildContext _) => page,
      settings: settings,
    );
  }

  static MaterialPageRoute<dynamic> _errorRoute(RouteSettings settings) {
    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (BuildContext _) => const Scaffold(
        body: EmptyState(
          icon: Icons.error_outline,
          title: 'Página não encontrada',
          message: 'A rota solicitada não existe ou recebeu '
              'parâmetros inválidos.',
        ),
      ),
    );
  }
}
