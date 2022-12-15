part of 'login_bloc.dart';

@immutable
abstract class LoginEvent extends Equatable{}

class LoginSubmitEvent extends LoginEvent {
  final String email;
  final String password;
  final bool rememberMe;

  LoginSubmitEvent(this.email, this.password, this.rememberMe);

  @override
  List<Object?> get props => [email, password, rememberMe];
}

class LoginAutoLoginEvent extends LoginEvent {
  @override
  List<Object?> get props => [];
}
