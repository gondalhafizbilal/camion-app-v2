part of 'log_out_cubit.dart';

sealed class LogOutState {}

final class LogOutInitial extends LogOutState {}

final class LogOutLoading extends LogOutState {}

final class LogOutSuccess extends LogOutState {
  final String message;

  LogOutSuccess({required this.message});
}

final class LogOutFailure extends LogOutState {
  final String message;

  LogOutFailure({required this.message});
}

