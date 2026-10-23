part of 'delete_account_cubit.dart';

sealed class DeleteAccountState {}

final class DeleteAccountInitial extends DeleteAccountState {}

final class DeleteAccountLoading extends DeleteAccountState {}

enum DeleteAccountAction { requestDeletion, cancelDeletion }

final class DeleteAccountSuccess extends DeleteAccountState {
  final String message;
  final DeleteAccountAction action;

  DeleteAccountSuccess({required this.message, required this.action});
}

final class DeleteAccountFailure extends DeleteAccountState {
  final ApiErrorModel error;
  DeleteAccountFailure({required this.error});
}
