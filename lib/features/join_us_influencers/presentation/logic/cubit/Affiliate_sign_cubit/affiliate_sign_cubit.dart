import 'package:camion/core/api/api_error_model.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/features/join_us_influencers/data/models/affiliate_model/affiliate_model.dart';
import 'package:camion/features/join_us_influencers/data/repository/supplier_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'affiliate_sign_state.dart';

class InfluencerSignCubit extends Cubit<AffiliateSignState> {
  InfluencerSignCubit(this.supplierRepository) : super(AffiliateSignInitial());
  final InfluencerRepository supplierRepository;

  Future<void> signSupplier({
    required String name,
    required String nationality,
    required String gender,
    required String bio,
  }) async {
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
     if(isClosed) return;
    emit(AffiliateSignLoading());
    final result = await supplierRepository.signAffiliate(
      token: token!,
      name: name,
      nationality: nationality,
      gender: gender,
      bio: bio,
       
    );
    if(isClosed) return;
    result.fold((l) => emit(AffiliateSignError(l)), (r) async {
      // await sl<SecureCacheHelper>().saveData(key: 'affiliateId', value: r.id);

      emit(AffiliateSignSuccess(affiliateModel: r));
    });
  }
}
