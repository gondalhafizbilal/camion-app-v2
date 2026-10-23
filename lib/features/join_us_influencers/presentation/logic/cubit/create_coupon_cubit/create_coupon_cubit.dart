import 'package:camion/core/api/api_error_model.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/features/join_us_influencers/data/repository/supplier_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'create_coupon_state.dart';

class CreateInfluencerCouponCubit extends Cubit<CreateCouponState> {
  CreateInfluencerCouponCubit(this.supplierRepository) : super(CreateCouponInitial());
  final InfluencerRepository supplierRepository;

  Future<void> createCoupon({
    required String code,
    required String expiryDate,
    required num discountPercentage,
  }) async {
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    if(isClosed) return;
    emit(CreateCouponLoading());
    final result = await supplierRepository.createCoupon(
      token: token!
           ,
      expiryDate: expiryDate,
      code: code,
      discountPercentage: discountPercentage,
    );
    if(isClosed) return;
    result.fold(
      (l) => emit(CreateCouponError(error: l)),
      (r) => emit(CreateCouponSuccess()),
    );
  }
}
