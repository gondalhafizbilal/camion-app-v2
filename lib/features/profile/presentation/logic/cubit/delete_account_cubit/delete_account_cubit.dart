import 'package:camion/core/api/api_error_model.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/features/profile/data/repository/profie_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
part 'delete_account_state.dart';

class DeleteAccountCubit extends Cubit<DeleteAccountState> {
  DeleteAccountCubit(this.profileRepository) : super(DeleteAccountInitial());
  final ProfileRepository profileRepository;

  Future<void> deleteAccount() async {
    final token = await sl<SecureCacheHelper>().getData(key: "token");
    if (token == null || token.trim().isEmpty) {
      emit(
        DeleteAccountFailure(
          error: ApiErrorModel(
            message: 'Authentication required',
            statusCode: 401,
          ),
        ),
      );
      return;
    }
    emit(DeleteAccountLoading());
    final result = await profileRepository.deleteAccount(token: token);
    result.fold((error) => emit(DeleteAccountFailure(error: error)), (data) {
      final message = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : 'Account marked for deletion';
      emit(
        DeleteAccountSuccess(
          message: message,
          action: DeleteAccountAction.requestDeletion,
        ),
      );
    });
  }

  Future<void> cancelDeletion() async {
    final token = await sl<SecureCacheHelper>().getData(key: "token");
    if (token == null || token.trim().isEmpty) {
      emit(
        DeleteAccountFailure(
          error: ApiErrorModel(
            message: 'Authentication required',
            statusCode: 401,
          ),
        ),
      );
      return;
    }

    emit(DeleteAccountLoading());
    final result = await profileRepository.cancelAccountDeletion(token: token);
    result.fold((error) => emit(DeleteAccountFailure(error: error)), (data) {
      final message = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : 'Account deletion cancelled';
      emit(
        DeleteAccountSuccess(
          message: message,
          action: DeleteAccountAction.cancelDeletion,
        ),
      );
    });
  }
}
