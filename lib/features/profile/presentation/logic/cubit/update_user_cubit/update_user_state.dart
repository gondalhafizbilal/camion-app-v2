// part of 'update_user_cubit.dart';
//
//
// sealed class UpdateUserState {}
//
// final class UpdateUserInitial extends UpdateUserState {}
//
// final class UpdateUserLoading extends UpdateUserState {}
//
// final class UpdateUserLoaded extends UpdateUserState {
//   final GetUserModel user;
//   UpdateUserLoaded({required this.user});
// }
//
// final class UpdateUserError extends UpdateUserState {
//   final ApiErrorModel error;
//   UpdateUserError({required this.error});
// }
part of 'update_user_cubit.dart';

abstract class UpdateUserState {}

class UpdateUserInitial extends UpdateUserState {}

class UpdateUserLoading extends UpdateUserState {}

class UpdateUserLoaded extends UpdateUserState {
  final GetUserModel user;
  UpdateUserLoaded({required this.user});
}

class UpdateUserError extends UpdateUserState {
  final ApiErrorModel error;
  UpdateUserError({required this.error});
}
