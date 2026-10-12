import 'package:equatable/equatable.dart';

/// Where money lives: cash, a bank card…
class Account extends Equatable {
  const Account({
    required this.id,
    required this.name,
    this.currency = 'EGP',
    required this.updatedAt,
    this.version = 0,
  });

  final String id;
  final String name;
  final String currency;
  final DateTime updatedAt;
  final int version;

  @override
  List<Object?> get props => [id, name, currency, updatedAt, version];
}
