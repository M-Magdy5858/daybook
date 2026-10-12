import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

/// An amount of money, kept as whole minor units (piasters, cents) in an
/// `int`. Never a `double`: `0.1 + 0.2` is `0.30000000000000004`.
class Money extends Equatable implements Comparable<Money> {
  const Money(this.minor, {this.currency = 'EGP'});

  /// e.g. 1250 means 12.50.
  final int minor;
  final String currency;

  static const zero = Money(0);

  /// Reads what a person typed: `12`, `12.5`, `1,250.75`. Extra decimals are
  /// cut off (`12.345` → 12.34). Returns null for anything else, including
  /// negative amounts.
  static Money? tryParse(String input, {String currency = 'EGP'}) {
    final text = input.trim().replaceAll(',', '');
    final match = RegExp(r'^(\d+)(?:\.(\d*))?$').firstMatch(text);
    if (match == null) return null;
    final whole = int.parse(match.group(1)!);
    final fraction = (match.group(2) ?? '').padRight(2, '0').substring(0, 2);
    return Money(whole * 100 + int.parse(fraction), currency: currency);
  }

  /// Like [tryParse], but throws [FormatException] on bad input.
  factory Money.parse(String input, {String currency = 'EGP'}) =>
      tryParse(input, currency: currency) ??
      (throw FormatException('Not an amount', input));

  bool get isZero => minor == 0;

  /// `operator +` lets you write `a + b` with your own class.
  Money operator +(Money other) {
    _sameCurrency(other);
    return Money(minor + other.minor, currency: currency);
  }

  Money operator -(Money other) {
    _sameCurrency(other);
    return Money(minor - other.minor, currency: currency);
  }

  /// This amount as a share of [total], 0.0 and up (for charts and budgets).
  double ratioOf(Money total) => total.minor == 0 ? 0 : minor / total.minor;

  /// e.g. `EGP 1,250.50` in English. Dividing by 100 here is for display
  /// only; sums always use [minor].
  String format(String locale) =>
      NumberFormat.currency(locale: locale, name: currency).format(minor / 100);

  /// `1250.50`: plain digits for a text field.
  String toInputText() =>
      '${minor ~/ 100}.${(minor % 100).toString().padLeft(2, '0')}';

  void _sameCurrency(Money other) {
    if (other.currency != currency) {
      throw ArgumentError('Cannot mix $currency and ${other.currency}');
    }
  }

  @override
  int compareTo(Money other) => minor.compareTo(other.minor);

  @override
  List<Object?> get props => [minor, currency];
}
