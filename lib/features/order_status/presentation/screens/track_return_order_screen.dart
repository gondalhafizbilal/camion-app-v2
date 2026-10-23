import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:camion/config/widgets/custom_sliver_app_bar.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/config/app_config.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_toast.dart';
import 'package:camion/core/utils/currency_display_utils.dart';
import 'package:camion/core/utils/image_url_transformer.dart';
import 'package:camion/features/order_status/data/models/order_model/order_model.dart';
import 'package:camion/features/order_status/data/models/return_request_model.dart';
import 'package:camion/features/order_status/data/models/order_status_item_model.dart';
import 'package:camion/features/order_status/data/repository/order_status_repo.dart';
import 'package:camion/features/order_status/presentation/widgets/order_status_item_widget.dart';
import 'package:camion/features/order_status/utils/order_status_utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class TrackReturnOrderScreen extends StatefulWidget {
  const TrackReturnOrderScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
    required this.productTitle,
    required this.productImage,
    this.requestUuid,
  });

  final String orderId;
  final String orderNumber;
  final String productTitle;
  final String productImage;
  final String? requestUuid;

  @override
  State<TrackReturnOrderScreen> createState() => _TrackReturnOrderScreenState();
}

class _TrackReturnOrderScreenState extends State<TrackReturnOrderScreen> {
  static const List<_ReturnReasonOption> _reasonOptions = [
    _ReturnReasonOption(
      value: 'wrong_variation',
      title: 'Wrong Variation',
      description:
          'Received a different size, colour, or variant than ordered.',
      arabicTitle: 'اختلاف المقاس أو اللون',
      arabicDescription: 'تم استلام مقاس أو لون أو نوع مختلف عن الطلب.',
    ),
    _ReturnReasonOption(
      value: 'damaged_broken',
      title: 'Damaged / Broken',
      description: 'The item arrived damaged, broken, or unusable.',
      arabicTitle: 'تالف / مكسور',
      arabicDescription: 'وصل المنتج تالفًا أو مكسورًا أو غير صالح للاستخدام.',
    ),
    _ReturnReasonOption(
      value: 'wrong_product',
      title: 'Wrong Product',
      description: 'A completely different product was delivered.',
      arabicTitle: 'منتج خاطئ',
      arabicDescription: 'تم تسليم منتج مختلف تمامًا عن المطلوب.',
    ),
  ];

  final TextEditingController _reasonDetailController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedEvidence = <XFile>[];

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isUploadingEvidence = false;
  bool _isFullOrderReturn = true;

  OrderModel? _order;
  ReturnRequestModel? _returnRequest;
  String? _errorMessage;
  String _selectedReason = _reasonOptions.first.value;
  String? _selectedOrderItemUuid;
  bool get _isArabic =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _reasonDetailController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool forceSingleRequest = false}) async {
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    if (!mounted) return;
    if (token == null || token.trim().isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = _isArabic
            ? 'يرجى تسجيل الدخول لإدارة طلبات الإرجاع.'
            : 'Please sign in to manage returns.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repo = sl<OrderStatusRepository>();
    final orderResult = await repo.getCurrentCustomerOrder(
      token: token,
      uuid: widget.orderId,
    );
    if (!mounted) return;

    ReturnRequestModel? resolvedRequest;
    if ((widget.requestUuid ?? '').trim().isNotEmpty || forceSingleRequest) {
      final requestUuid = (widget.requestUuid ?? _returnRequest?.uuid ?? '')
          .trim();
      if (requestUuid.isNotEmpty) {
        final requestResult = await repo.getCurrentCustomerReturnRequest(
          token: token,
          uuid: requestUuid,
        );
        resolvedRequest = requestResult.fold((_) => null, (request) => request);
      }
    }

    if (resolvedRequest == null) {
      final requestsResult = await repo.getCurrentCustomerReturnRequests(
        token: token,
      );
      resolvedRequest = requestsResult.fold((_) => null, (requests) {
        final matches = requests.where(
          (request) => request.order?.uuid.trim() == widget.orderId.trim(),
        );
        return matches.isEmpty ? null : matches.first;
      });
    }

    orderResult.fold(
      (error) {
        setState(() {
          _isLoading = false;
          _errorMessage = error.message;
        });
      },
      (order) {
        setState(() {
          _order = order;
          _returnRequest = resolvedRequest;
          _isLoading = false;
          _errorMessage = null;
          if (!_isFullOrderReturn &&
              _selectedOrderItemUuid == null &&
              order.items.isNotEmpty) {
            _selectedOrderItemUuid = order.items.first.id;
          }
        });
      },
    );
  }

  bool get _canCreateReturnRequest {
    final status = (_order?.wcOrderStatus ?? _order?.statusDisplay ?? '')
        .trim();
    return orderStatusFromRaw(status) == OrderStatus.delivered ||
        orderStatusFromRaw(status) == OrderStatus.paymentSuccessful;
  }

  String get _displayOrderNumber {
    if (widget.orderNumber.trim().isNotEmpty) return widget.orderNumber.trim();
    return widget.orderId.trim();
  }

  String _reasonLabel(String value) {
    final option = _reasonOptions
        .where((entry) => entry.value == value)
        .firstWhere(
          (_) => true,
          orElse: () => const _ReturnReasonOption(
            value: '',
            title: 'Return Request',
            description: '',
            arabicTitle: 'طلب إرجاع',
            arabicDescription: '',
          ),
        );
    return _isArabic ? option.arabicTitle : option.title;
  }

  Color _requestStatusBackgroundColor(String rawStatus) {
    switch (rawStatus.trim().toLowerCase()) {
      case 'approved':
      case 'returned':
      case 'refunded':
        return const Color(0xFFE3FFD5);
      case 'rejected':
        return const Color(0xFFFFE8E8);
      case 'pending':
      default:
        return const Color(0xFFFFF2D9);
    }
  }

  Color _requestStatusTextColor(String rawStatus) {
    switch (rawStatus.trim().toLowerCase()) {
      case 'approved':
      case 'returned':
      case 'refunded':
        return const Color(0xFF3D743A);
      case 'rejected':
        return const Color(0xFFB42318);
      case 'pending':
      default:
        return const Color(0xFF9A6700);
    }
  }

  String _requestStatusLabel(String rawStatus) {
    switch (rawStatus.trim().toLowerCase()) {
      case 'approved':
        return _isArabic ? 'تمت الموافقة' : 'Approved';
      case 'rejected':
        return _isArabic ? 'مرفوض' : 'Rejected';
      case 'returned':
        return _isArabic ? 'تم الاسترداد' : 'Refunded';
      case 'refunded':
        return _isArabic ? 'تم الاسترداد' : 'Refunded';
      case 'pending':
      default:
        return _isArabic ? 'قيد المراجعة' : 'Pending Review';
    }
  }

  String _effectiveReturnStatus(ReturnRequestModel request) {
    final requestStatus = request.status.trim().toLowerCase();
    final orderStatus = (request.order?.status ?? _order?.wcOrderStatus ?? '')
        .trim()
        .toLowerCase();

    // Backend can keep return-request status as pending while order is already returned.
    if (orderStatus == 'returned' || orderStatus == 'refunded') {
      return 'refunded';
    }
    return requestStatus;
  }

  bool _canUploadMoreEvidence(ReturnRequestModel request) {
    return _effectiveReturnStatus(request) == 'pending';
  }

  List<OrderStatusItemModel> _buildReturnStatuses(ReturnRequestModel request) {
    final requestedAt = request.createdAt ?? DateTime.now();
    final hasEvidence = request.evidence.isNotEmpty;
    final effectiveStatus = _effectiveReturnStatus(request);
    final isPending = effectiveStatus == 'pending';
    final isApproved = effectiveStatus == 'approved';
    final isRejected = effectiveStatus == 'rejected';
    final isRefunded = effectiveStatus == 'refunded';
    final reviewCompleted = isApproved || isRejected || isRefunded;

    return [
      OrderStatusItemModel(
        title: _isArabic ? 'تم طلب الإرجاع' : 'Return Requested',
        subtitle: _isArabic
            ? 'تم إرسال طلب الإرجاع بنجاح.'
            : 'Your return request has been submitted successfully.',
        time: requestedAt,
        isCompleted: true,
        isActive: !hasEvidence && isPending,
      ),
      OrderStatusItemModel(
        title: _isArabic ? 'تم إرسال الأدلة' : 'Evidence Submitted',
        subtitle: hasEvidence
            ? (_isArabic
                  ? 'تم رفع الصور المطلوبة.'
                  : 'Required photo evidence has been uploaded.')
            : (_isArabic
                  ? 'أضف صورًا لدعم طلب الإرجاع.'
                  : 'Upload photo evidence to support the request.'),
        time: requestedAt,
        isCompleted: hasEvidence,
        isActive: hasEvidence && isPending,
      ),
      OrderStatusItemModel(
        title: isRejected
            ? (_isArabic ? 'تم رفض الطلب' : 'Request Rejected')
            : (_isArabic ? 'مراجعة الإدارة' : 'Admin Review'),
        subtitle: isRejected
            ? (request.adminNote?.trim().isNotEmpty == true
                  ? request.adminNote!.trim()
                  : (_isArabic
                        ? 'تم رفض طلب الإرجاع من فريق الإدارة.'
                        : 'The return request was rejected by the admin team.'))
            : (_isArabic
                  ? 'فريق الإدارة يراجع طلب الإرجاع.'
                  : 'The admin team is reviewing your return request.'),
        time: request.updatedAt ?? requestedAt,
        isCompleted: reviewCompleted,
        isActive: isPending && hasEvidence,
      ),
      OrderStatusItemModel(
        title: _isArabic ? 'تمت الموافقة على الاسترداد' : 'Refund Approved',
        subtitle: _isArabic
            ? 'تمت الموافقة على الاسترداد وبدء الإجراءات.'
            : 'Your refund has been approved and initiated.',
        time: request.updatedAt ?? requestedAt,
        isCompleted: isApproved || isRefunded,
        isActive: isApproved && !isRefunded,
      ),
      OrderStatusItemModel(
        title: _isArabic ? 'اكتمل الاسترداد' : 'Refund Completed',
        subtitle: _isArabic
            ? 'اكتملت عملية الاسترداد بنجاح.'
            : 'The refund has been completed successfully.',
        time: request.updatedAt ?? requestedAt,
        isCompleted: isRefunded,
        isActive: isRefunded,
      ),
    ];
  }

  Future<void> _pickEvidenceImage() async {
    try {
      final source = await _pickEvidenceSource();
      if (!mounted || source == null) return;
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (file == null || !mounted) return;
      setState(() {
        _selectedEvidence.add(file);
      });
    } on PlatformException catch (_) {
      if (!mounted) return;
      AppToast.show(
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        msg: _isArabic
            ? 'يرجى السماح بالوصول للكاميرا/الصور من إعدادات iOS.'
            : 'Please allow camera/photos access in iOS Settings.',
      );
    } catch (_) {
      if (!mounted) return;
      AppToast.show(
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        msg: _isArabic
            ? 'تعذر فتح المعرض حالياً. يرجى المحاولة مرة أخرى.'
            : 'Unable to open gallery right now. Please try again.',
      );
    }
  }

  Future<ImageSource?> _pickEvidenceSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(_isArabic ? 'التقاط صورة' : 'Take Photo'),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(
                  _isArabic ? 'اختيار من المعرض' : 'Choose from Gallery',
                ),
                onTap: () =>
                    Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
              ListTile(
                title: Text(
                  _isArabic ? 'إلغاء' : 'Cancel',
                  textAlign: TextAlign.center,
                ),
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitReturnRequest() async {
    final order = _order;
    final reasonDetail = _reasonDetailController.text.trim();
    if (order == null) return;
    if (!_canCreateReturnRequest) {
      AppToast.show(
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        msg: _isArabic
            ? 'يمكن تقديم طلبات الإرجاع فقط للطلبات التي تم تسليمها.'
            : 'Return requests can only be submitted for delivered orders.',
      );
      return;
    }
    if (reasonDetail.isEmpty) {
      AppToast.show(
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        msg: _isArabic
            ? 'يرجى توضيح سبب الإرجاع.'
            : 'Please explain the return issue.',
      );
      return;
    }
    if (_selectedEvidence.isEmpty) {
      AppToast.show(
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        msg: _isArabic ? 'إرفاق صورة مطلوب.' : 'Photo evidence is required.',
      );
      return;
    }
    if (!_isFullOrderReturn &&
        (_selectedOrderItemUuid ?? '').trim().isEmpty &&
        order.items.isNotEmpty) {
      AppToast.show(
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        msg: _isArabic
            ? 'يرجى اختيار العنصر الذي تريد إرجاعه.'
            : 'Please select the item you want to return.',
      );
      return;
    }

    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    if (token == null || token.trim().isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    final repo = sl<OrderStatusRepository>();
    final createResult = await repo.createReturnRequest(
      token: token,
      orderUuid: order.id,
      orderItemUuid: _isFullOrderReturn ? null : _selectedOrderItemUuid,
      reason: _selectedReason,
      reasonDetail: reasonDetail,
    );

    await createResult.fold(
      (error) async {
        if (!mounted) return;
        AppToast.show(
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.red,
          msg: error.message,
        );
      },
      (request) async {
        await _uploadEvidenceForRequest(
          token: token,
          requestUuid: request.uuid,
        );
        await _loadData(forceSingleRequest: true);
        if (!mounted) return;
        AppToast.show(
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.green,
          msg: _isArabic
              ? 'تم إرسال طلب الإرجاع بنجاح.'
              : 'Return request submitted successfully.',
        );
        setState(() {
          _selectedEvidence.clear();
          _reasonDetailController.clear();
        });
      },
    );

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
    });
  }

  Future<void> _uploadEvidenceForRequest({
    required String token,
    required String requestUuid,
  }) async {
    if (_selectedEvidence.isEmpty) return;

    setState(() {
      _isUploadingEvidence = true;
    });

    final repo = sl<OrderStatusRepository>();
    for (final file in _selectedEvidence) {
      final rawPath = file.path.trim();
      if (rawPath.isEmpty || !File(rawPath).existsSync()) {
        continue;
      }
      final normalizedPath = rawPath.replaceAll('\\', '/');
      if (_isVideoFile(file, normalizedPath)) {
        if (mounted) {
          AppToast.show(
            gravity: ToastGravity.TOP,
            backgroundColor: Colors.red,
            msg: _isArabic
                ? 'الفيديو غير مسموح. يرجى رفع صور فقط.'
                : 'Videos are not allowed. Please upload images only.',
          );
        }
        continue;
      }
      final inferredFileName = file.name.trim().isNotEmpty
          ? file.name.trim()
          : normalizedPath.split('/').last;
      final mediaType = _resolveEvidenceMediaType(file, normalizedPath);

      final result = await repo.uploadReturnRequestEvidence(
        token: token,
        requestUuid: requestUuid,
        formData: FormData.fromMap({
          'file': await MultipartFile.fromFile(
            normalizedPath,
            filename: inferredFileName,
            contentType: mediaType,
          ),
        }),
      );
      final failed = result.isLeft();
      if (failed) {
        final error = result.fold((left) => left, (_) => null);
        if (!mounted) return;
        AppToast.show(
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.red,
          msg:
              error?.message ??
              (_isArabic ? 'فشل في رفع الأدلة.' : 'Failed to upload evidence.'),
        );
        break;
      }
    }

    if (!mounted) return;
    setState(() {
      _isUploadingEvidence = false;
    });
  }

  DioMediaType _resolveEvidenceMediaType(XFile file, String normalizedPath) {
    final explicitMime = (file.mimeType ?? '').trim().toLowerCase();
    if (explicitMime.isNotEmpty && !explicitMime.startsWith('video/')) {
      return DioMediaType.parse(explicitMime);
    }

    final lowerPath = normalizedPath.toLowerCase();
    if (lowerPath.endsWith('.png')) return DioMediaType.parse('image/png');
    if (lowerPath.endsWith('.webp')) return DioMediaType.parse('image/webp');
    return DioMediaType.parse('image/jpeg');
  }

  bool _isVideoFile(XFile file, String normalizedPath) {
    final explicitMime = (file.mimeType ?? '').trim().toLowerCase();
    if (explicitMime.startsWith('video/')) return true;
    final lowerPath = normalizedPath.toLowerCase();
    return lowerPath.endsWith('.mp4') ||
        lowerPath.endsWith('.mov') ||
        lowerPath.endsWith('.webm') ||
        lowerPath.endsWith('.mkv');
  }

  Future<void> _uploadAdditionalEvidence() async {
    final request = _returnRequest;
    if (request == null || !_canUploadMoreEvidence(request)) {
      AppToast.show(
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        msg: _isArabic
            ? 'لا يمكن رفع أدلة إضافية بعد اكتمال حالة الإرجاع.'
            : 'You cannot upload more evidence after return completion.',
      );
      return;
    }
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    final requestUuid = request.uuid.trim();
    if (token == null || token.trim().isEmpty || requestUuid.isEmpty) {
      return;
    }
    if (_selectedEvidence.isEmpty) {
      AppToast.show(
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        msg: _isArabic
            ? 'يرجى اختيار صورة أولًا.'
            : 'Please choose photo evidence first.',
      );
      return;
    }
    await _uploadEvidenceForRequest(token: token, requestUuid: requestUuid);
    await _loadData(forceSingleRequest: true);
    if (!mounted) return;
    setState(() {
      _selectedEvidence.clear();
    });
  }

  Widget _buildEvidencePickerCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFE7E7E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isArabic ? 'الأدلة' : 'Evidence',
            style: TextStyle(
              color: AppColors.black,
              fontSize: 15.sp,
              fontFamily: 'Montes',
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            _isArabic
                ? 'إرفاق صورة إلزامي لكل طلب إرجاع.'
                : 'Photo evidence is mandatory for every return request.',
            style: TextStyle(
              color: const Color(0xFF666666),
              fontSize: 12.sp,
              fontFamily: 'Montes',
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : _pickEvidenceImage,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? 'إضافة صورة'
                        : 'Add Photo',
                  ),
                ),
              ),
            ],
          ),
          if (_selectedEvidence.isNotEmpty) ...[
            SizedBox(height: 14.h),
            ..._selectedEvidence.asMap().entries.map((entry) {
              final index = entry.key;
              final file = entry.value;
              return Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: const Color(0xFFE7E7E7)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.image_outlined,
                      color: AppColors.primaryColor,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        file.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.black,
                          fontSize: 12.sp,
                          fontFamily: 'Montes',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _isSubmitting
                          ? null
                          : () {
                              setState(() {
                                _selectedEvidence.removeAt(index);
                              });
                            },
                      child: const Icon(Icons.close, color: Color(0xFF888888)),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildCreateReturnRequestView(OrderModel order) {
    final items = order.items;
    if (!_isFullOrderReturn &&
        (_selectedOrderItemUuid ?? '').trim().isEmpty &&
        items.isNotEmpty) {
      _selectedOrderItemUuid = items.first.id;
    }

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 40.h),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildReturnSummaryCard(order: order, request: null),
          SizedBox(height: 18.h),
          if (!_canCreateReturnRequest)
            _buildNotEligibleCard(
              _isArabic
                  ? 'يمكن طلب الإرجاع فقط بعد تسليم الطلب.'
                  : 'Returns can only be requested after the order is delivered.',
            )
          else ...[
            _buildPolicyCard(),
            SizedBox(height: 18.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: const Color(0xFFE7E7E7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isArabic ? 'هدف الإرجاع' : 'Return Target',
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 15.sp,
                      fontFamily: 'Montes',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              Localizations.localeOf(context).languageCode ==
                                      'ar'
                                  ? 'إرجاع الطلب بالكامل'
                                  : 'Return the full order',
                              style: TextStyle(
                                color: const Color(0xFF333333),
                                fontSize: 14.sp,
                                fontFamily: 'Montes',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              _isArabic
                                  ? 'أوقف الخيار لتقديم إرجاع لعنصر واحد فقط.'
                                  : 'Turn off to submit a return for one item only.',
                              style: TextStyle(
                                color: const Color(0xFF666666),
                                fontSize: 12.sp,
                                fontFamily: 'Montes',
                                fontWeight: FontWeight.w400,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Switch.adaptive(
                        value: _isFullOrderReturn,
                        onChanged: _isSubmitting
                            ? null
                            : (value) {
                                setState(() {
                                  _isFullOrderReturn = value;
                                  if (!value &&
                                      items.isNotEmpty &&
                                      (_selectedOrderItemUuid ?? '').isEmpty) {
                                    _selectedOrderItemUuid = items.first.id;
                                  }
                                });
                              },
                      ),
                    ],
                  ),
                  if (!_isFullOrderReturn && items.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: (_selectedOrderItemUuid ?? '').trim().isEmpty
                          ? items.first.id
                          : _selectedOrderItemUuid,
                      decoration: InputDecoration(
                        labelText:
                            Localizations.localeOf(context).languageCode == 'ar'
                            ? 'اختر العنصر'
                            : 'Select item',
                        border: OutlineInputBorder(),
                      ),
                      items: items
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item.id,
                              child: Text(
                                item.title.trim().isNotEmpty
                                    ? item.title
                                    : (_isArabic ? 'عنصر الطلب' : 'Order item'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      selectedItemBuilder: (context) {
                        return items.map((item) {
                          final title = item.title.trim().isNotEmpty
                              ? item.title
                              : (_isArabic ? 'عنصر الطلب' : 'Order item');
                          return Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList();
                      },
                      onChanged: _isSubmitting
                          ? null
                          : (value) {
                              setState(() {
                                _selectedOrderItemUuid = value;
                              });
                            },
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 18.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: const Color(0xFFE7E7E7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isArabic ? 'سبب الإرجاع' : 'Eligible Reason',
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 15.sp,
                      fontFamily: 'Montes',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  ..._reasonOptions.map((option) {
                    final isSelected = _selectedReason == option.value;
                    return InkWell(
                      onTap: _isSubmitting
                          ? null
                          : () {
                              setState(() {
                                _selectedReason = option.value;
                              });
                            },
                      borderRadius: BorderRadius.circular(12.r),
                      child: Container(
                        margin: EdgeInsets.only(bottom: 10.h),
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFFF1F1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryColor
                                : const Color(0xFFE7E7E7),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 20.w,
                              height: 20.w,
                              margin: EdgeInsets.only(top: 2.h),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryColor
                                      : const Color(0xFFBDBDBD),
                                  width: 1.5,
                                ),
                              ),
                              child: isSelected
                                  ? Center(
                                      child: Container(
                                        width: 10.w,
                                        height: 10.w,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFFCB262E),
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isArabic
                                        ? option.arabicTitle
                                        : option.title,
                                    style: TextStyle(
                                      color: AppColors.black,
                                      fontSize: 14.sp,
                                      fontFamily: 'Montes',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    _isArabic
                                        ? option.arabicDescription
                                        : option.description,
                                    style: TextStyle(
                                      color: const Color(0xFF666666),
                                      fontSize: 12.sp,
                                      fontFamily: 'Montes',
                                      fontWeight: FontWeight.w400,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: _reasonDetailController,
                    minLines: 4,
                    maxLines: 5,
                    enabled: !_isSubmitting,
                    decoration: InputDecoration(
                      labelText:
                          Localizations.localeOf(context).languageCode == 'ar'
                          ? 'تفاصيل السبب'
                          : 'Reason details',
                      hintText: _isArabic
                          ? 'اشرح بالتفصيل المشكلة في الطلب.'
                          : 'Describe exactly what was wrong with the order.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 18.h),
            _buildEvidencePickerCard(),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReturnRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCB262E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  _isSubmitting
                      ? (_isArabic ? 'جارٍ الإرسال...' : 'Submitting...')
                      : (_isArabic
                            ? 'إرسال طلب الإرجاع'
                            : 'Submit Return Request'),
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontFamily: 'Montes',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _buildTrackingView(ReturnRequestModel request) {
    final canUploadMoreEvidence = _canUploadMoreEvidence(request);
    final statuses = _buildReturnStatuses(request);
    final refund = request.refundAmount;
    final refundText = refund == null
        ? '-'
        : formatMoneyForDisplay(
            context,
            refund.decimalAmount,
            resolveCurrencyCode([refund.currencyCode]),
          );

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 40.h),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildReturnSummaryCard(order: _order, request: request),
          SizedBox(height: 18.h),
          if (request.reasonDetail.trim().isNotEmpty || refund != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: const Color(0xFFE7E7E7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isArabic ? 'تفاصيل الطلب' : 'Request Details',
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 16.sp,
                      fontFamily: 'Montes',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _DetailRow(
                    label: _isArabic ? 'السبب' : 'Reason',
                    value: _reasonLabel(request.reason),
                  ),
                  SizedBox(height: 10.h),
                  _DetailRow(
                    label: _isArabic ? 'تفاصيل السبب' : 'Reason Details',
                    value: request.reasonDetail.trim().isEmpty
                        ? '-'
                        : request.reasonDetail.trim(),
                  ),
                  SizedBox(height: 10.h),
                  _DetailRow(
                    label: _isArabic ? 'مبلغ الاسترداد' : 'Refund Amount',
                    value: refundText,
                  ),
                  if ((request.adminNote ?? '').trim().isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    _DetailRow(
                      label: _isArabic ? 'ملاحظة الإدارة' : 'Admin Note',
                      value: request.adminNote!.trim(),
                    ),
                  ],
                ],
              ),
            ),
          SizedBox(height: 18.h),
          Text(
            _isArabic ? 'حالة الإرجاع' : 'Return Status',
            style: TextStyle(
              color: AppColors.black,
              fontSize: 18.sp,
              fontFamily: 'Montes',
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 18.h),
          ...List.generate(statuses.length, (index) {
            final item = statuses[index];
            final isCurrent =
                item.isActive ||
                (!item.isCompleted &&
                    index > 0 &&
                    statuses[index - 1].isCompleted);
            return OrderStatusItemWidget(
              item: item,
              isFirst: index == 0,
              isLast: index == statuses.length - 1,
              isCurrent: isCurrent,
            );
          }),
          SizedBox(height: 24.h),
          _buildExistingEvidenceCard(request),
          if (canUploadMoreEvidence) ...[
            SizedBox(height: 18.h),
            _buildEvidencePickerCard(),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: _isUploadingEvidence
                    ? null
                    : _uploadAdditionalEvidence,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCB262E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  _isUploadingEvidence
                      ? (_isArabic ? 'جارٍ الرفع...' : 'Uploading...')
                      : (_isArabic
                            ? 'رفع المزيد من الأدلة'
                            : 'Upload More Evidence'),
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontFamily: 'Montes',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _buildReturnSummaryCard({
    required OrderModel? order,
    required ReturnRequestModel? request,
  }) {
    final subjectTitle = request?.subjectTitle.trim().isNotEmpty == true
        ? request!.subjectTitle.trim()
        : widget.productTitle.trim().isNotEmpty
        ? widget.productTitle.trim()
        : (order?.items.isNotEmpty == true
              ? order!.items.first.title
              : (_isArabic ? 'عنصر الإرجاع' : 'Return item'));
    final statusSource = request == null
        ? (order?.wcOrderStatus ?? '')
        : _effectiveReturnStatus(request);
    final displayImage =
        request?.orderItem?.displayImageUrl.trim().isNotEmpty == true
        ? request!.orderItem!.displayImageUrl.trim()
        : widget.productImage.trim();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFE7E7E7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReturnPreviewImage(imageUrl: displayImage),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isArabic
                      ? 'رقم الطلب $_displayOrderNumber'
                      : 'Order #$_displayOrderNumber',
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 14.sp,
                    fontFamily: 'Montes',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  subjectTitle,
                  style: TextStyle(
                    color: const Color(0xFF666666),
                    fontSize: 12.sp,
                    fontFamily: 'Montes',
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: request == null
                        ? _statusBackgroundColor(statusSource)
                        : _requestStatusBackgroundColor(statusSource),
                    borderRadius: BorderRadius.circular(100.r),
                  ),
                  child: Text(
                    request == null
                        ? orderStatusLabelByLocale(
                            statusSource,
                            isArabic: _isArabic,
                          )
                        : _requestStatusLabel(statusSource),
                    style: TextStyle(
                      color: request == null
                          ? _statusTextColor(statusSource)
                          : _requestStatusTextColor(statusSource),
                      fontSize: 12.sp,
                      fontFamily: 'Montes',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExistingEvidenceCard(ReturnRequestModel request) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFE7E7E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isArabic ? 'الأدلة المرفوعة' : 'Submitted Evidence',
            style: TextStyle(
              color: AppColors.black,
              fontSize: 15.sp,
              fontFamily: 'Montes',
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.h),
          if (request.evidence.isEmpty)
            Text(
              _isArabic ? 'لم يتم رفع أدلة بعد.' : 'No evidence uploaded yet.',
              style: TextStyle(
                color: const Color(0xFF666666),
                fontSize: 12.sp,
                fontFamily: 'Montes',
                fontWeight: FontWeight.w400,
              ),
            )
          else
            ...request.evidence.map((evidence) {
              final evidenceUrl = ImageUrlTransformer.getTransformedImageUrl(
                evidence.url,
                AppConfig.instance.assetsHost,
              );
              final resolvedEvidenceUrl = evidenceUrl.isNotEmpty
                  ? evidenceUrl
                  : evidence.url.trim();
              return Container(
                margin: EdgeInsets.only(bottom: 10.h),
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFE7E7E7)),
                ),
                child: Row(
                  children: [
                    if (!evidence.isVideo && resolvedEvidenceUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: CachedNetworkImage(
                          imageUrl: resolvedEvidenceUrl,
                          width: 54.w,
                          height: 54.w,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            width: 54.w,
                            height: 54.w,
                            color: const Color(0xFFF1F1F1),
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 54.w,
                        height: 54.w,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F1F1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          evidence.isVideo
                              ? Icons.videocam_outlined
                              : Icons.attachment_outlined,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            evidence.isVideo
                                ? (_isArabic ? 'دليل فيديو' : 'Video Evidence')
                                : (_isArabic ? 'دليل صورة' : 'Photo Evidence'),
                            style: TextStyle(
                              color: AppColors.black,
                              fontSize: 12.sp,
                              fontFamily: 'Montes',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            evidence.mimeType,
                            style: TextStyle(
                              color: const Color(0xFF666666),
                              fontSize: 11.sp,
                              fontFamily: 'Montes',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildPolicyCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFF3D59A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isArabic ? 'أسباب الإرجاع المقبولة' : 'Eligible Return Reasons',
            style: TextStyle(
              color: AppColors.black,
              fontSize: 15.sp,
              fontFamily: 'Montes',
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10.h),
          ..._reasonOptions.map(
            (option) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Text(
                _isArabic
                    ? '• ${option.arabicTitle}: ${option.arabicDescription}'
                    : '• ${option.title}: ${option.description}',
                style: TextStyle(
                  color: const Color(0xFF6A5A2A),
                  fontSize: 12.sp,
                  fontFamily: 'Montes',
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
            ),
          ),
          Text(
            _isArabic
                ? 'طلبات التراجع عن الشراء أو شكاوى الجودة المطابقة للوصف غير مؤهلة للإرجاع.'
                : 'Requests for buyer\'s remorse or quality complaints that match the description are not eligible.',
            style: TextStyle(
              color: const Color(0xFF6A5A2A),
              fontSize: 12.sp,
              fontFamily: 'Montes',
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotEligibleCard(String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFF1C4C4)),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: const Color(0xFF9D2D2D),
          fontSize: 13.sp,
          fontFamily: 'Montes',
          fontWeight: FontWeight.w500,
          height: 1.5,
        ),
      ),
    );
  }

  Color _statusBackgroundColor(String rawStatus) {
    switch (orderStatusFromRaw(rawStatus)) {
      case OrderStatus.delivered:
      case OrderStatus.paymentSuccessful:
      case OrderStatus.returned:
        return const Color(0xFFE3FFD5);
      case OrderStatus.confirmed:
      case OrderStatus.dispatched:
        return const Color(0xFFEAF1FF);
      case OrderStatus.returnRequested:
      case OrderStatus.pending:
      case OrderStatus.paymentPending:
      case OrderStatus.unknown:
        return const Color(0xFFFFF2D9);
      case OrderStatus.cancelled:
      case OrderStatus.paymentRejected:
        return const Color(0xFFFFE8E8);
    }
  }

  Color _statusTextColor(String rawStatus) {
    switch (orderStatusFromRaw(rawStatus)) {
      case OrderStatus.delivered:
      case OrderStatus.paymentSuccessful:
      case OrderStatus.returned:
        return const Color(0xFF3D743A);
      case OrderStatus.confirmed:
      case OrderStatus.dispatched:
        return const Color(0xFF24419B);
      case OrderStatus.returnRequested:
      case OrderStatus.pending:
      case OrderStatus.paymentPending:
      case OrderStatus.unknown:
        return const Color(0xFF9A6700);
      case OrderStatus.cancelled:
      case OrderStatus.paymentRejected:
        return const Color(0xFFB42318);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = _isArabic;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: CustomScrollView(
        slivers: [
          CustomSliverAppBar(
            appBarHeight: 50.h,
            centerTitle: false,
            isShownDivider: false,
            isShownActions: false,
            title: Text(
              isArabic ? 'الإرجاع والاسترداد' : 'Return & Refund',
              style: TextStyle(
                color: AppColors.black,
                fontSize: 20.sp,
                fontFamily: 'Montes',
                fontWeight: FontWeight.w500,
                height: 2,
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null && _errorMessage!.trim().isNotEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFFB42318),
                      fontSize: 14.sp,
                      fontFamily: 'Montes',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            )
          else if (_returnRequest != null)
            _buildTrackingView(_returnRequest!)
          else if (_order != null)
            _buildCreateReturnRequestView(_order!)
          else
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  isArabic
                      ? 'معلومات الإرجاع غير متاحة لهذا الطلب.'
                      : 'Return information is not available for this order.',
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 14.sp,
                    fontFamily: 'Montes',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReturnReasonOption {
  const _ReturnReasonOption({
    required this.value,
    required this.title,
    required this.description,
    required this.arabicTitle,
    required this.arabicDescription,
  });

  final String value;
  final String title;
  final String description;
  final String arabicTitle;
  final String arabicDescription;
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 98.w,
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.black,
              fontSize: 12.sp,
              fontFamily: 'Montes',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: const Color(0xFF666666),
              fontSize: 12.sp,
              fontFamily: 'Montes',
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReturnPreviewImage extends StatelessWidget {
  const _ReturnPreviewImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return Container(
        width: 68.w,
        height: 68.w,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F1F1),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: const Icon(Icons.inventory_2_outlined),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: 68.w,
        height: 68.w,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => Container(
          width: 68.w,
          height: 68.w,
          color: const Color(0xFFF1F1F1),
          child: const Icon(Icons.image_not_supported_outlined),
        ),
      ),
    );
  }
}
