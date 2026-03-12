import 'package:flutter/material.dart';
import 'core/constants/route_names.dart';
import 'router/app_router.dart';

class SVVApp extends StatelessWidget {
  const SVVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shiv Video Vision',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepOrange,
        useMaterial3: true,
      ),
      initialRoute: RouteNames.splash,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}