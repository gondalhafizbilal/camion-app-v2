import 'dart:io';

import 'package:camion/core/api/api_consumer.dart';
import 'package:camion/core/config/app_config.dart';
import 'package:camion/core/config/app_flavor.dart';
import 'package:camion/features/home/data/data_source/remote_data_source.dart';
import 'package:camion/features/home/data/models/reviews_model/review_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeApiConsumer implements ApiConsumer {
  String? lastPath;
  Object? lastData;
  Map<String, String>? lastHeaders;

  Response<dynamic> _response(String path, dynamic data) {
    return Response<dynamic>(
      requestOptions: RequestOptions(path: path),
      data: data,
      statusCode: 200,
    );
  }

  @override
  Future<Response<dynamic>> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    lastPath = path;
    lastData = data;
    lastHeaders = headers;
    return _response(path, {'ok': true});
  }

  @override
  Future<Response<dynamic>> get(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    lastPath = path;
    lastData = data;
    lastHeaders = headers;

    if (path.contains('/v1/products/') && path.endsWith('/reviews')) {
      return _response(path, [
        {
          'uuid': 'review-1',
          'customer': {'uuid': 'c-1', 'fullName': 'Your Name'},
          'rating': '1',
          'comment': 'This was very bad',
          'isEdited': false,
          'images': [
            {
              'uuid': 'img-1',
              'thumbnailUrl': 'https://example.com/thumb.jpg',
              'imageUrl': 'https://example.com/image.jpg',
            },
          ],
        },
      ]);
    }

    return _response(path, {'ok': true});
  }

  @override
  Future<Response<dynamic>> patch(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    lastPath = path;
    lastData = data;
    lastHeaders = headers;
    return _response(path, {'ok': true});
  }

  @override
  Future<Response<dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    lastPath = path;
    lastData = data;
    lastHeaders = headers;
    return _response(path, {
      'uuid': 'review-1',
      'rating': '1',
      'comment': 'ok',
    });
  }

  @override
  Future<Response<dynamic>> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    lastPath = path;
    lastData = data;
    lastHeaders = headers;
    return _response(path, {'ok': true});
  }
}

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: '.env.development');
    AppConfig.initialize(
      flavor: AppFlavor.development,
      envFile: '.env.development',
    );
  });

  test('Product review endpoints and mapping align with new API', () async {
    final api = _FakeApiConsumer();
    final ds = HomeRemoteDataSource(apiConsumer: api);

    final tempImage = File(
      '${Directory.systemTemp.path}/camion_review_test.jpg',
    );
    await tempImage.writeAsBytes(<int>[1, 2, 3, 4]);

    await ds.createReview(
      token: 't',
      productId: '660e5d31-24e8-42e2-b8d7-1c45118ef29a',
      formData: FormData.fromMap({
        'rating': 1.0,
        'comment': 'This was very bad',
        'images': await MultipartFile.fromFile(tempImage.path),
      }),
    );
    expect(
      api.lastPath,
      endsWith('/v2/products/660e5d31-24e8-42e2-b8d7-1c45118ef29a/reviews'),
    );
    final body = api.lastData as FormData;
    expect(
      body.fields.any(
        (entry) => entry.key == 'comment' && entry.value == 'This was very bad',
      ),
      true,
    );
    expect(
      body.fields.any(
        (entry) => entry.key == 'rating' && entry.value.toString() == '1.0',
      ),
      true,
    );
    expect(body.files.length, 1);

    await ds.deleteReviewImage(
      token: 't',
      productId: '660e5d31-24e8-42e2-b8d7-1c45118ef29a',
      reviewId: 'review-1',
      imageId: 'img-1',
    );
    expect(
      api.lastPath,
      endsWith(
        '/v1/products/660e5d31-24e8-42e2-b8d7-1c45118ef29a/reviews/review-1/images/img-1',
      ),
    );

    final listResponse = await ds.getReviews(
      token: 't',
      productId: '660e5d31-24e8-42e2-b8d7-1c45118ef29a',
    );
    final reviews = (listResponse.data as List)
        .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
    expect(reviews.length, 1);
    expect(reviews.first.id, 'review-1');
    expect(reviews.first.reviewer, 'Your Name');
    expect(reviews.first.review, 'This was very bad');
    expect(reviews.first.rating, 1);
    expect(reviews.first.images.length, 1);
    expect(reviews.first.images.first.id, 'img-1');
  });
}
