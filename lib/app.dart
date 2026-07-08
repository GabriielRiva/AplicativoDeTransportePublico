import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'presentation/routes/app_router.dart';
import 'presentation/routes/app_routes.dart';

/// Widget raiz do TranCity: tema Material 3 e rotas nomeadas.
class TranCityApp extends StatelessWidget {
  /// Cria o aplicativo.
  const TranCityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: kSplashRoute,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
