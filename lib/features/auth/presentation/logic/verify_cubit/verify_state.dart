part of 'verify_cubit.dart';
sealed class VerifyState {}

final class VerifyInitial extends VerifyState {}

final class VerifyLoading extends VerifyState {}

final class VerifyLoaded extends VerifyState {
  final CustomerAuthResponse response;
  VerifyLoaded({required this.response});
}

final class VerifyError extends VerifyState {
  final ApiErrorModel error;
  VerifyError({required this.error});
}
