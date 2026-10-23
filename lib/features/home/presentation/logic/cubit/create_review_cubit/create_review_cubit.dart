import 'dart:async';
import 'dart:io';

import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/api/api_error_model.dart';
import 'package:camion/core/services/tiktok_business_service.dart';
import 'package:camion/features/home/data/models/reviews_model/review_model.dart';
import 'package:camion/features/home/data/repository/home_repo.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'create_review_state.dart';

class CreateReviewCubit extends Cubit<CreateReviewState> {
  CreateReviewCubit(this.homeRepository) : super(CreateReviewInitial());
  final HomeRepository homeRepository;

  Future<void> createReview({
    required String productId,
    required String comment,
    required double rating,
    List<String> imagePaths = const <String>[],
    String? orderUuid,
  }) async {
    await submitReview(
      productId: productId,
      comment: comment,
      rating: rating,
      imagePaths: imagePaths,
      orderUuid: orderUuid,
    );
  }

  Future<ReviewModel?> getMyReviewForProduct({
    required String productId,
  }) async {
    final customerId =
        (await sl<SecureCacheHelper>().getData(key: 'id'))?.trim() ?? '';
    if (customerId.isEmpty) {
      return null;
    }
    final response = await homeRepository.getReviews(
      productId: productId,
      lang: '',
    );
    return response.fold(
      (_) => null,
      (reviews) => reviews
          .where((r) => r.customerId.trim() == customerId)
          .fold(null, (previousValue, element) => previousValue ?? element),
    );
  }

  Future<void> submitReview({
    required String productId,
    required String comment,
    required double rating,
    String? existingReviewId,
    List<String> imagePaths = const <String>[],
    String? orderUuid,
  }) async {
    final normalizedProductId = productId.trim();
    final normalizedComment = comment.trim();
    if (normalizedProductId.isEmpty || normalizedComment.isEmpty) {
      if (!isClosed) {
        emit(
          CreateReviewError(
            error: ApiErrorModel(message: 'Please add your review comment'),
          ),
        );
      }
      return;
    }
    if (isClosed) return;
    emit(CreateReviewLoading());

    final normalizedExistingReviewId = existingReviewId?.trim() ?? '';
    final isUpdate = normalizedExistingReviewId.isNotEmpty;

    final reviewResponse = isUpdate
        ? await homeRepository.updateReview(
            productId: normalizedProductId,
            reviewId: normalizedExistingReviewId,
            comment: normalizedComment,
            rating: rating,
          )
        : await homeRepository.createReview(
            productId: normalizedProductId,
            comment: normalizedComment,
            rating: rating,
            imagePaths: imagePaths,
            orderUuid: orderUuid,
          );

    await reviewResponse.fold(
      (error) async {
        if (!isClosed) emit(CreateReviewError(error: error));
      },
      (data) async {
        var reviewId = normalizedExistingReviewId;
        if (reviewId.isEmpty && data is Map<String, dynamic>) {
          reviewId = _extractReviewId(data);
        }

        if (isUpdate && reviewId.isNotEmpty && imagePaths.isNotEmpty) {
          for (final path in imagePaths) {
            final normalizedPath = path.trim();
            if (normalizedPath.isEmpty) continue;
            final file = File(normalizedPath);
            if (!file.existsSync()) continue;
            final formData = FormData.fromMap({
              'file': await MultipartFile.fromFile(normalizedPath),
            });
            final uploadResult = await homeRepository.createReviewImage(
              productId: normalizedProductId,
              reviewId: reviewId,
              formData: formData,
            );
            final uploadFailed = uploadResult.isLeft();
            if (uploadFailed) {
              final uploadError = uploadResult.fold((l) => l, (_) => null);
              if (uploadError != null && !isClosed) {
                emit(CreateReviewError(error: uploadError));
                return;
              }
            }
          }
        }

        ReviewModel? review;
        if (reviewId.isNotEmpty) {
          final refreshed = await homeRepository.getReviewById(
            productId: normalizedProductId,
            reviewId: reviewId,
          );
          review = refreshed.fold((_) => null, (r) => r);
        }
        review ??= _fallbackReviewFromResponse(
          data: data,
          reviewId: reviewId,
          comment: normalizedComment,
          rating: rating,
        );
        unawaited(
          TikTokBusinessService.rate(
            eventId: reviewId.isNotEmpty ? reviewId : normalizedProductId,
          ),
        );
        if (!isClosed) {
          emit(CreateReviewSuccess(review: review, isEdited: isUpdate));
        }
      },
    );
  }

  String _extractReviewId(Map<String, dynamic> data) {
    final directId = (data['uuid'] ?? data['id'] ?? data['reviewId'] ?? '')
        .toString()
        .trim();
    if (directId.isNotEmpty) return directId;

    final nested = data['review'];
    if (nested is Map<String, dynamic>) {
      final nestedId = (nested['uuid'] ?? nested['id'] ?? '').toString().trim();
      if (nestedId.isNotEmpty) return nestedId;
    }
    return '';
  }

  ReviewModel? _fallbackReviewFromResponse({
    required dynamic data,
    required String reviewId,
    required String comment,
    required double rating,
  }) {
    if (reviewId.isEmpty) return null;
    final payload = data is Map<String, dynamic> ? data : null;
    final reviewPayload =
        payload != null && payload['review'] is Map<String, dynamic>
        ? payload['review'] as Map<String, dynamic>
        : payload;
    final customer = reviewPayload?['customer'];
    final customerMap = customer is Map<String, dynamic>
        ? customer
        : const <String, dynamic>{};
    final parsedRating = rating.round().clamp(1, 5);
    return ReviewModel(
      id: reviewId,
      customerId: (customerMap['uuid'] ?? reviewPayload?['customerId'] ?? '')
          .toString(),
      dateCreated: DateTime.now(),
      reviewer:
          (customerMap['fullName'] ?? reviewPayload?['reviewer'] ?? 'Anonymous')
              .toString(),
      review: (reviewPayload?['comment'] ?? reviewPayload?['review'] ?? comment)
          .toString(),
      rating: parsedRating,
      verified: (reviewPayload?['verified'] as bool?) ?? false,
      isEdited: (reviewPayload?['isEdited'] as bool?) ?? false,
      images: const <ReviewImageModel>[],
    );
  }
}
