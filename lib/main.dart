import 'package:flutter/material.dart';

import 'app.dart';
import 'services/storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initStorage();
  runApp(const ValyutaApp());
}