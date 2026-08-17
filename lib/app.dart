import 'package:flutter/material.dart';

import 'core/router/app_router.dart';

class MoveCrewApp extends StatelessWidget {
  const MoveCrewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MoveCrew',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1E56A0),
      ),
    );
  }
}
