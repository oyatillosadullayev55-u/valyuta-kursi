import 'package:flutter/material.dart';
import 'package:valyuta_kursi/pages/shell.dart';
import 'package:valyuta_kursi/services/storage.dart' show prefs;


class ValyutaApp extends StatefulWidget {
  const ValyutaApp({super.key});

  @override
  State<ValyutaApp> createState() => _ValyutaAppState();
}

class _ValyutaAppState extends State<ValyutaApp> {
  bool _dark = prefs.getBool('dark') ?? false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Valyuta kursi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: _dark ? Brightness.dark : Brightness.light,
      ),
      home: Shell(
        dark: _dark,
        onToggleTheme: () {
          setState(() => _dark = !_dark);
          prefs.setBool('dark', _dark);
        },
      ),
    );
  }
}