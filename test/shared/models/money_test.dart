import 'package:daybook/shared/models/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parse reads what people type, in whole piasters', () {
    expect(Money.parse('12.5'), const Money(1250));
    expect(Money.parse('12'), const Money(1200));
    expect(Money.parse('1,250.75'), const Money(125075));
    expect(Money.parse('12.345'), const Money(1234)); // extra digits cut off
    expect(Money.tryParse('-3'), isNull);
    expect(Money.tryParse('abc'), isNull);
  });

  test('adding is exact: 0.10 + 0.20 is 0.30', () {
    expect(Money.parse('0.10') + Money.parse('0.20'), Money.parse('0.30'));
    expect(
      () => const Money(1) + const Money(1, currency: 'USD'),
      throwsArgumentError,
    );
  });

  test('formats for a locale', () {
    expect(const Money(125050).format('en'), 'EGP1,250.50');
    final arabic = const Money(125050).format('ar');
    expect(arabic, contains('EGP'));
    expect(arabic, isNot(const Money(125050).format('en')));
  });
}
