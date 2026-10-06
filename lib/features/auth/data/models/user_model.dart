import 'package:daybook/features/auth/domain/entities/user.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  const UserModel({required this.id, required this.email, required this.name});

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  final String id;
  final String email;
  final String name;

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  User toEntity() => User(id: id, email: email, name: name);
}
