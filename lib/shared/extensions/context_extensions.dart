import 'package:flutter/material.dart';

extension ContextX on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;

  void showSnak(String message) =>
      ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: Text(message)));
}
