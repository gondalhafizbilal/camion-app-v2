import 'package:camion/core/api/api_error_model.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/features/auth/utils/country_code_normalizer.dart';
import 'package:camion/features/profile/data/models/get_user_model/user_model.dart';
import 'package:camion/features/profile/data/repository/profie_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
part 'get_user_state.dart';

class GetUserCubit extends Cubit<GetUserState> {
  GetUserCubit(this.profileRepository) : super(GetUserInitial());
  final ProfileRepository profileRepository;

  Future<void> getUserById() async {
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    if (token == null || token.trim().isEmpty) {
      if (isClosed) return;
      emit(
        GetUserError(
          error: ApiErrorModel(message: 'Session expired. Please login again.'),
        ),
      );
      return;
    }
    if (isClosed) return;
    emit(GetUserLoading());
    final response = await profileRepository.getUserById(
      token: token,
      userId: '',
    );
    if (isClosed) return;
    await response.fold((l) async => emit(GetUserError(error: l)), (r) async {
      await _cacheLatestUserDefaults(r);
      if (isClosed) return;
      emit(GetUserLoaded(user: r));
    });
  }

  Future<void> _cacheLatestUserDefaults(GetUserModel user) async {
    final cache = sl<SecureCacheHelper>();
    final normalizedName = user.fullName.trim();
    final normalizedEmail = user.email.trim();
    final normalizedPhone = user.phone.trim();
    final inferredCountryCode = _extractDialCode(normalizedPhone);
    final existingCountryCode =
        (await cache.getData(key: 'countryCode'))?.trim() ?? '';
    final countryCodeToStore = inferredCountryCode.isNotEmpty
        ? inferredCountryCode
        : normalizeCountryCode(existingCountryCode);

    await Future.wait([
      if (normalizedName.isNotEmpty)
        cache.saveData(key: 'userName', value: normalizedName),
      if (normalizedEmail.isNotEmpty)
        cache.saveData(key: 'email', value: normalizedEmail),
      if (normalizedPhone.isNotEmpty)
        cache.saveData(key: 'phoneNumber', value: normalizedPhone),
      if (countryCodeToStore.isNotEmpty)
        cache.saveData(key: 'countryCode', value: countryCodeToStore),
    ]);
  }

  String _extractDialCode(String phone) {
    final match = RegExp(r'^\+\d{1,4}').firstMatch(phone.trim());
    return match?.group(0) ?? '';
  }
}
