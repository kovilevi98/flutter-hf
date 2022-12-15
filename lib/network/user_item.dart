import 'package:equatable/equatable.dart';

class UserItem extends Equatable {
  final String name;
  final String avatarUrl;

  const UserItem(this.name, this.avatarUrl);

  @override
  List<Object?> get props => [name, avatarUrl];
}