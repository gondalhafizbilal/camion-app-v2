part of 'guest_auth_cubit.dart';

sealed class GuestAuthState {}

final class GuestAuthInitial extends GuestAuthState {}

final class GuestAuthLoading extends GuestAuthState {
  GuestAuthLoading({this.isSilent = false});

  final bool isSilent;
}

final class GuestAuthLoaded extends GuestAuthState {
  GuestAuthLoaded({required this.token, this.isSilent = false});

  final String token;
  final bool isSilent;
}

final class GuestAuthError extends GuestAuthState {
  GuestAuthError({required this.error, this.isSilent = false});

  final ApiErrorModel error;
  final bool isSilent;
}
