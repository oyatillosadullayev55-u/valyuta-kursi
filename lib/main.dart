import 'package:flutter/material.dart';
import 'package:valyuta_kursi/services/storage.dart' show initStorage;

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initStorage();
  runApp(const ValyutaApp());
}