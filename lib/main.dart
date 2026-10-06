import 'package:daybook/app.dart';
import 'package:daybook/core/di/injection.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await configureDependencies();
  startSessionServices();

  runApp(const MyApp());
}
