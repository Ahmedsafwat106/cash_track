abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final String? token;
  final String? message;
  AuthSuccess({this.token, this.message});
}

class AuthFailure extends AuthState {
  final String error;
  AuthFailure(this.error);
}

class AuthEmailNotConfirmed extends AuthState {}

class AuthPasswordResetSent extends AuthState {}

class AuthPasswordResetSuccess extends AuthState {}