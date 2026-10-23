part of 'login_cubit.dart';

sealed class LoginState {}

final class LoginInitial extends LoginState {}

final class LoginLoading extends LoginState {}

final class LoginLoaded extends LoginState {
  final AuthSessionTokenModel session;
  LoginLoaded({required this.session});
}

final class LoginError extends LoginState {
  final ApiErrorModel error;
  LoginError({required this.error});
}
