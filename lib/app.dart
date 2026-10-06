import 'package:flutter/material.dart';

import 'controllers/app_controller.dart';
import 'pages/home_page.dart';

class ValyutaApp extends StatefulWidget {
  const ValyutaApp({super.key});

  @override
  State<ValyutaApp> createState() => _ValyutaAppState();
}

class _ValyutaAppState extends State<ValyutaApp> {
  final _ctrl = AppController();

  @override
  void initState() {
    super.initState();
    _ctrl.init();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(controller: _ctrl, child: const _Themed());
  }
}

class _Themed extends StatelessWidget {
  const _Themed();

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final seed = kAccents[c.accent];

    ThemeData theme(Brightness b) => ThemeData(
      useMaterial3: true,
      colorSchemeSeed: seed,
      brightness: b,
      appBarTheme: const AppBarTheme(centerTitle: false),
    );

    return MaterialApp(
      title: 'Valyuta kursi',
      debugShowCheckedModeBanner: false,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      themeMode: c.themeMode,
      home: const HomePage(),
    );
  }
}