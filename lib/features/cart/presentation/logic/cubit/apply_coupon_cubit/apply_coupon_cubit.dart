import 'package:camion/core/api/api_error_model.dart';
import 'package:camion/features/cart/data/repository/cart_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
part 'apply_coupon_state.dart';

class ApplyCouponCubit extends Cubit<ApplyCouponState> {
  ApplyCouponCubit(this.cartRepository) : super(ApplyCouponInitial());
  final CartRepository cartRepository;

  Future<void> applyCoupon({required String code}) async {
    if (isClosed) return;
    emit(ApplyCouponLoading());
    emit(
      ApplyCouponError(
        ApiErrorModel(
          message: 'Coupons are not available in the new cart API flow.',
          statusCode: 400,
        ),
      ),
    );
  }
}
