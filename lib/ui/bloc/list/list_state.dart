part of 'list_bloc.dart';

@immutable
abstract class ListState extends Equatable {}

class ListInitial extends ListState {
  @override
  List<Object?> get props => [];
}

class ListLoading extends ListState {
  @override
  List<Object?> get props => [];
}

class ListLoaded extends ListState {
  final List<UserItem> users;

  ListLoaded(this.users);

  @override
  List<Object?> get props => [users];
}

class ListError extends ListState {
  final String message;

  ListError(this.message);

  @override
  List<Object?> get props => [message];
}
