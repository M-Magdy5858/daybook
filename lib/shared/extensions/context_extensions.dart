import 'package:daybook/shared/models/money.dart';
import 'package:flutter/material.dart';

extension ContextX on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;

  void showSnack(String message) =>
      ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: Text(message)));

  /// [money] in the user's language, e.g. `EGP 1,250.50`.
  String formatMoney(Money money) =>
      money.format(Localizations.localeOf(this).toString());
}
