// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:camion/config/localization/cubit/localizations_cubit.dart';
// import 'package:camion/features/currency/presentation/logic/cubit/currency_cubit.dart';
// import 'package:camion/config/widgets/custom_expansion_tile.dart';
// import 'package:camion/config/widgets/custom_sliver_app_bar.dart';
// import 'package:camion/config/widgets/custom_text_form_field.dart';
// import 'package:camion/core/utils/app_colors.dart';
// import 'package:camion/core/utils/app_images.dart';
// import 'package:camion/core/utils/app_style.dart';
// import 'package:camion/features/cart/presentation/logic/cubit/add_cart_cubit/add_cart_cubit.dart';
// import 'package:camion/features/cart/presentation/logic/cubit/get_cart_cubit/get_cart_cubit.dart';
// import 'package:camion/features/home/data/models/all_products_model/all_products_model.dart';
// import 'package:camion/features/home/data/models/all_products_model/sub_models/product_variations.dart';
// import 'package:camion/features/home/presentation/logic/cubit/create_review_cubit/create_review_cubit.dart';
// import 'package:camion/features/home/presentation/logic/cubit/get_review_cubit/get_review_cubit.dart';
// import 'package:camion/features/home/presentation/logic/cubit/product_id_detailscubit/product_id_details_cubit.dart';
// import 'package:camion/features/home/presentation/logic/cubit/toggle_product_id_images/toggle_product_id_images_cubit.dart';
// import 'package:camion/features/home/presentation/screens/home_screen.dart';
// import 'package:camion/features/home/presentation/widgets/product_id_image_skeletonizer.dart';
// import 'package:camion/features/home/presentation/widgets/products_options.dart';
// import 'package:camion/features/home/presentation/widgets/review_container.dart';
// import 'package:camion/features/wish_list/presentation/logic/cubit/add_to_wish_list/wish_list_cubit.dart';
// import 'package:camion/features/wish_list/presentation/logic/cubit/get_wish_listcubit/get_wish_list_cubit.dart';
// import 'package:camion/features/wish_list/presentation/screens/wish_list_screen.dart';
// import 'package:camion/generated/l10n.dart';
// import 'package:camion/routing/app_router.dart';
// import 'package:camion/core/cache/secure_cache_storage.dart';
// import 'package:camion/core/services/service_locator.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_rating_bar/flutter_rating_bar.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:camion/core/utils/app_toast.dart';
// import 'package:go_router/go_router.dart';
// import 'package:photo_view/photo_view.dart';
// import 'package:photo_view/photo_view_gallery.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:skeletonizer/skeletonizer.dart';
//
// // class ProductDetails extends StatelessWidget {
// //   ProductDetails({super.key, required this.productId});
// //   final String productId;
//
// //   final GlobalKey<ProductDetailsBodyState> productKey =
// //       GlobalKey<ProductDetailsBodyState>();
// //   @override
// //   Widget build(BuildContext context) {
// //     return ProductDetailsBody(productId: productId , key: productKey,);
// //   }
// // }
//
// class ProductDetails extends StatefulWidget {
//   const ProductDetails({super.key, required this.productId});
//   final String productId;
//   @override
//   State<ProductDetails> createState() => _ProductDetailsState();
// }
//
// class _ProductDetailsState extends State<ProductDetails> {
//   final pageController = PageController();
//   double _rating = 0.0;
//
//   @override
//   void initState() {
//     BlocProvider.of<ProductIdDetailsCubit>(
//       context,
//     ).getProductDetails(widget.productId, context.read<LocalizationsCubit>().state.languageCode);
//     sl<SecureCacheHelper>().getData(key: 'token').then((token) {
//       if (token != null && token.isNotEmpty) {
//         BlocProvider.of<GetWishListCubit>(context).getWishList();
//       }
//     });
//     super.initState();
//     BlocProvider.of<GetCartCubit>(context).getCart(context.read<LocalizationsCubit>().state.languageCode);
//     super.initState();
//
//     context.read<GetReviewCubit>().getReviews(
//       lang: context.read<LocalizationsCubit>().state.languageCode,
//       productId: widget.productId,
//     );
//   }
//
//   void refreshGetCart() {
//     BlocProvider.of<GetCartCubit>(context).getCart(context.read<LocalizationsCubit>().state.languageCode);
//   }
//
//   final TextEditingController _reviewController = TextEditingController();
//
//   @override
//   void dispose() {
//     pageController.dispose();
//     _reviewController.dispose();
//     super.dispose();
//   }
//
//   // late AllProductModel prodcut;
//
//   Map<String, String> chosenAttributes = {};
//   int chosenQuantity = 1;
//   ProductVariations? selectedVariation;
//
//   Map<String, dynamic> _getDisplayData(AllProductModel product) {
//     if (selectedVariation != null) {
//       return {
//         'price': selectedVariation!.price.toString(),
//         'regularPrice': selectedVariation!.regularPrice.toString(),
//         'image': selectedVariation!.image,
//         'stockQuantity': selectedVariation!.stockQuantity,
//         'stockStatus': selectedVariation!.stockStatus,
//         'isInStock': selectedVariation!.stockStatus == 'instock',
//       };
//     }
//
//     return {
//       'price': product.prices.salePrice,
//       'regularPrice': product.prices.regularPrice,
//       'image': product.images.isNotEmpty ? product.images[0].thumbnail : '',
//       'stockQuantity': 100,
//       'stockStatus': product.isInStock ? 'instock' : 'outofstock',
//       'isInStock': product.isInStock,
//     };
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       resizeToAvoidBottomInset: false,
//       backgroundColor: Colors.white,
//       body: RefreshIndicator(
//         onRefresh: () async {
//           setState(() {
//             selectedVariation = null;
//             chosenAttributes.clear();
//             chosenQuantity = 1;
//           });
//           BlocProvider.of<ProductIdDetailsCubit>(context).getProductDetails(
//             widget.productId,
//             context.read<LocalizationsCubit>().state.languageCode,
//             forceRefresh: true,
//           );
//         },
//         child: CustomScrollView(
//           slivers: [
//             CustomSliverAppBar(
//               appBarHeight: 70.h,
//               title: Text(
//                 S.of(context).product_details,
//                 style: AppStyle.styleRegular18(context).copyWith(color: AppColors.black, fontWeight: FontWeight.w500),
//               ),
//               leading: GestureDetector(
//                 onTap: () {
//                   GoRouter.of(context).pop(context);
//                 },
//                 child: Icon(Icons.arrow_back, color: AppColors.black, size: 25.sp),
//               ),
//
//               isShownDivider: true,
//             ),
//
//             SliverToBoxAdapter(child: SizedBox(height: 15.h)),
//
//             SliverToBoxAdapter(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Container(
//                     height: 400.h,
//                     width: double.infinity,
//                     decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(16)),
//                     child: BlocBuilder<ProductIdDetailsCubit, ProductIdDetailsState>(
//                       builder: (context, state) {
//                         if (state is ProductIdDetailsLoading) {
//                           return const Skeletonizer(enabled: true, child: ProductImageSkeleton());
//                         }
//
//                         if (state is ProductIdDetailsLoaded) {
//                           final product = state.productIdDetailsModel;
//                           // final displayData = _getDisplayData(product);
//                           return Stack(
//                             children: [
//                               selectedVariation != null && selectedVariation!.image!.isNotEmpty
//                                   ? GestureDetector(
//                                       onTap: () {
//                                         GoRouter.of(
//                                           context,
//                                         ).push(AppRouter.fullScreenImage, extra: selectedVariation!.image);
//                                       },
//                                       child: PhotoView(
//                                         imageProvider: CachedNetworkImageProvider(selectedVariation!.image!),
//                                         backgroundDecoration: const BoxDecoration(color: Colors.transparent),
//                                         loadingBuilder: (context, event) => Skeletonizer(
//                                           enabled: true,
//                                           child: SizedBox(
//                                             height: 400.h,
//                                             width: double.infinity,
//                                             child: Image.asset(Assets.imagesShoes, fit: BoxFit.fill),
//                                           ),
//                                         ),
//                                         errorBuilder: (context, error, stackTrace) =>
//                                             const Center(child: Icon(Icons.error, color: Colors.white, size: 50)),
//                                       ),
//                                     )
//                                   : PhotoViewGallery.builder(
//                                       itemCount: product.images.length,
//
//                                       builder: (context, index) {
//                                         return PhotoViewGalleryPageOptions(
//                                           onTapUp: (context, details, controllerValue) {
//                                             GoRouter.of(
//                                               context,
//                                             ).push(AppRouter.fullScreenImage, extra: product.images[index].thumbnail);
//                                           },
//                                           imageProvider: CachedNetworkImageProvider(product.images[index].thumbnail),
//                                           minScale: PhotoViewComputedScale.contained,
//                                           maxScale: PhotoViewComputedScale.covered * 2, // zoom ×2
//                                         );
//                                       },
//                                       pageController: pageController,
//
//                                       backgroundDecoration: const BoxDecoration(color: Colors.transparent),
//                                       loadingBuilder: (context, event) => Skeletonizer(
//                                         enabled: true,
//                                         child: SizedBox(
//                                           height: 400.h,
//                                           width: double.infinity,
//                                           child: Image.asset(Assets.imagesShoes, fit: BoxFit.fill),
//                                         ),
//                                       ),
//                                       onPageChanged: (index) {
//                                         context.read<ToggleProductIdImagesCubit>().toggle(index);
//                                       },
//                                     ),
//
//                               Positioned(
//                                 left: 16.w,
//                                 top: 16.h,
//                                 child: BlocBuilder<GetWishListCubit, GetWishListState>(
//                                   builder: (context, wishListState) {
//                                     return BlocBuilder<ProductIdDetailsCubit, ProductIdDetailsState>(
//                                       builder: (context, productState) {
//                                         if (productState is! ProductIdDetailsLoaded) {
//                                           return Container();
//                                         }
//
//                                         final product = productState.productIdDetailsModel;
//                                         bool isInWishList = false;
//
//                                         if (wishListState is GetWishListSuccess) {
//                                           isInWishList = wishListState.wishLists.any(
//                                             (item) => item.productId == widget.productId,
//                                           );
//                                         } else {
//                                           isInWishList = product.isInwishList ?? false;
//                                         }
//
//                                         return InkWell(
//                                           onTap: () async {
//                                             final token = await sl<SecureCacheHelper>().getData(key: 'token');
//                                             if (token == null || token.isEmpty) {
//                                               if (mounted) {
//                                                 final next = Uri.encodeComponent(
//                                                   '${AppRouter.productDetails}?id=${widget.productId}',
//                                                 );
//                                                 GoRouter.of(context).push('${AppRouter.login}?next=$next');
//                                               }
//                                               return;
//                                             }
//                                             if (isInWishList) {
//                                               await context.read<GetWishListCubit>().removeFromWishList(
//                                                 productId: widget.productId,
//                                               );
//
//                                               context.read<GetWishListCubit>().getWishList();
//
//                                               WishListScreen.wishListKey.currentState?.refreshGetWishList();
//                                               HomeScreen.homeKey.currentState?.refreshWishListAndCartList();
//                                             } else {
//                                               await context.read<AddToWishListCubit>().addtoWishList(
//                                                 productId: product.id.toString(),
//                                                 title: product.name,
//                                                 price: product.prices.price,
//                                                 image: product.images[0].thumbnail,
//                                               );
//
//                                               context.read<GetWishListCubit>().getWishList();
//                                               WishListScreen.wishListKey.currentState?.refreshGetWishList();
//                                               HomeScreen.homeKey.currentState?.refreshWishListAndCartList();
//                                             }
//                                           },
//                                           child: Container(
//                                             width: 35,
//                                             height: 35,
//                                             decoration: BoxDecoration(
//                                               color: Colors.white,
//                                               shape: BoxShape.circle,
//                                               boxShadow: [
//                                                 BoxShadow(
//                                                   color: Colors.black.withAlpha(15),
//                                                   spreadRadius: 2,
//                                                   blurRadius: 4,
//                                                   offset: Offset(0, 2.h),
//                                                 ),
//                                               ],
//                                             ),
//                                             child: Center(
//                                               child: SvgPicture.asset(
//                                                 isInWishList
//                                                     ? Assets.imagesIconsNewwwActiveHeart
//                                                     : Assets.imagesIconsNewwwInactiveHeart,
//                                                 width: 25.w,
//                                                 height: 25.h,
//                                               ),
//                                             ),
//                                           ),
//                                         );
//                                       },
//                                     );
//                                   },
//                                 ),
//                               ),
//
//                               Positioned(
//                                 right: 6.w,
//                                 bottom: 6.h,
//                                 child: InkWell(
//                                   onTap: () {
//                                     final productLink =
//                                         "https://camion-app.com/en/shop/${state.productIdDetailsModel.id}";
//                                     Share.share(productLink, subject: state.productIdDetailsModel.name);
//                                   },
//                                   child: SvgPicture.asset(Assets.imagesShareProduct, fit: BoxFit.cover),
//                                 ),
//                               ),
//                             ],
//                           );
//                         }
//
//                         if (state is ProductIdDetailsError) {
//                           return Center(
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               crossAxisAlignment: CrossAxisAlignment.center,
//                               children: [
//                                 Icon(state.error.icon, color: Colors.red, size: 50),
//
//                                 SizedBox(height: 20.h),
//                                 Text(
//                                   state.error.message,
//                                   style: TextStyle(fontSize: 16.sp, color: Colors.red),
//                                   textAlign: TextAlign.center,
//                                 ),
//
//                                 SizedBox(height: 10.h),
//
//                                 ElevatedButton(
//                                   onPressed: () {
//                                     context.read<ProductIdDetailsCubit>().getProductDetails(
//                                       widget.productId,
//                                       context.read<LocalizationsCubit>().state.languageCode,
//                                     );
//                                     ();
//                                   },
//                                   child: Text(S.of(context).retry, style: TextStyle(fontSize: 16.sp)),
//                                 ),
//                               ],
//                             ),
//                           );
//                         }
//
//                         return Container();
//                       },
//                     ),
//                   ),
//
//                   const SizedBox(height: 20),
//
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 12.0),
//                     child: Column(
//                       children: [
//                         BlocBuilder<ProductIdDetailsCubit, ProductIdDetailsState>(
//                           builder: (context, state) {
//                             if (state is ProductIdDetailsLoading) {
//                               return const Skeletonizer(enabled: true, child: ProductInfoSkeleton());
//                             }
//                             if (state is ProductIdDetailsLoaded) {
//                               final product = state.productIdDetailsModel;
//                               final displayData = _getDisplayData(product);
//                               return Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   if (selectedVariation == null)
//                                     Center(
//                                       child: Row(
//                                         mainAxisAlignment: MainAxisAlignment.center,
//                                         children: List.generate(
//                                           product.images.length,
//                                           (index) =>
//                                               BlocBuilder<ToggleProductIdImagesCubit, ToggleProductIdImagesState>(
//                                                 builder: (context, toggleState) {
//                                                   return Container(
//                                                     margin: EdgeInsets.symmetric(horizontal: 4.w),
//                                                     width: toggleState.index == index ? 20.w : 8.w,
//                                                     height: 8.h,
//                                                     decoration: BoxDecoration(
//                                                       color: toggleState.index == index
//                                                           ? const Color(0xFFD32F2F)
//                                                           : Colors.grey.shade400,
//                                                       borderRadius: BorderRadius.circular(4.r),
//                                                     ),
//                                                   );
//                                                 },
//                                               ),
//                                         ),
//                                       ),
//                                     ),
//
//                                   SizedBox(height: 15.h),
//
//                                   Row(
//                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                     children: [
//                                       Expanded(child: Text(product.name, style: AppStyle.styleBold18(context))),
//                                     ],
//                                   ),
//
//                                   SizedBox(height: 8.h),
//
//                                   Row(
//                                     children: [
//                                       Builder(
//                                         builder: (context) {
//                                           final cubit = context.watch<CurrencyCubit>();
//                                           final priceQAR = double.tryParse(displayData['price'].toString()) ?? 0.0;
//                                           final converted = cubit.convertFromQARToString(priceQAR);
//                                           return Text(
//                                             converted,
//                                             style: AppStyle.styleBold20(
//                                               context,
//                                             ).copyWith(color: AppColors.primaryColor),
//                                           );
//                                         },
//                                       ),
//
//                                       SizedBox(width: 4.w),
//
//                                       Builder(
//                                         builder: (context) {
//                                           final isArabic =
//                                               context.read<LocalizationsCubit>().state.languageCode == 'ar';
//                                           final cubit = context.watch<CurrencyCubit>();
//                                           final selected = cubit.selectedCurrency;
//                                           final hasRate = selected == null
//                                               ? false
//                                               : (selected.code.toUpperCase() == 'QAR' ||
//                                                     cubit.rates.containsKey(selected.code.toUpperCase()));
//                                           final String display = isArabic
//                                               ? (hasRate ? selected.symbol : product.prices.currencySymbol)
//                                               : (hasRate ? selected.code : product.prices.currencyCode);
//                                           return Text(
//                                             display,
//                                             style: AppStyle.styleRegular16(
//                                               context,
//                                             ).copyWith(fontWeight: FontWeight.w900, color: AppColors.primaryColor),
//                                           );
//                                         },
//                                       ),
//
//                                       SizedBox(width: 8.w),
//                                       displayData['price'] == displayData['regularPrice']
//                                           ? const SizedBox()
//                                           : Builder(
//                                               builder: (context) {
//                                                 final cubit = context.watch<CurrencyCubit>();
//                                                 final regularQAR =
//                                                     double.tryParse(displayData['regularPrice'].toString()) ?? 0.0;
//                                                 final converted = cubit.convertFromQARToString(regularQAR);
//                                                 final isArabic =
//                                                     context.read<LocalizationsCubit>().state.languageCode == 'ar';
//                                                 final selected = cubit.selectedCurrency;
//                                                 final hasRate = selected == null
//                                                     ? false
//                                                     : (selected.code.toUpperCase() == 'QAR' ||
//                                                           cubit.rates.containsKey(selected.code.toUpperCase()));
//                                                 final String unit = isArabic
//                                                     ? (hasRate ? selected.symbol : product.prices.currencySymbol)
//                                                     : (hasRate ? selected.code : product.prices.currencyCode);
//                                                 return Text(
//                                                   "$converted $unit",
//                                                   style: AppStyle.styleRegular15(context).copyWith(
//                                                     color: AppColors.gray,
//                                                     decoration: TextDecoration.lineThrough,
//                                                   ),
//                                                 );
//                                               },
//                                             ),
//                                     ],
//                                   ),
//
//                                   SizedBox(height: 5.h),
//
//                                   Row(
//                                     children: [
//                                       Text(
//                                         product.averageRating,
//                                         style: AppStyle.styleRegular14(context).copyWith(color: Colors.grey.shade600),
//                                       ),
//                                       SizedBox(width: 5.w),
//                                       ...List.generate(5, (index) {
//                                         int rating = 0;
//                                         try {
//                                           rating = double.parse(product.averageRating).toInt();
//                                         } catch (e) {
//                                           rating = 0;
//                                         }
//                                         return Icon(
//                                           index < rating ? Icons.star : Icons.star_border,
//                                           color: Colors.amber,
//                                           size: 20.r,
//                                         );
//                                       }),
//                                     ],
//                                   ),
//
//                                   SizedBox(height: 5.h),
//
//                                   Row(
//                                     children: [
//                                       Text(
//                                         product.reviewCount.toString(),
//                                         style: AppStyle.styleRegular14(context).copyWith(color: AppColors.gray),
//                                       ),
//                                       SizedBox(width: 5.w),
//                                       Icon(Icons.visibility, color: AppColors.gray, size: 15.r),
//                                     ],
//                                   ),
//
//                                   SizedBox(height: 10.h),
//
//                                   // حالة المخزون المحدثة
//                                   displayData['isInStock']
//                                       ? Container(
//                                           padding: EdgeInsets.all(8.r),
//                                           decoration: BoxDecoration(
//                                             color: AppColors.primaryColor,
//                                             borderRadius: BorderRadius.circular(25.r),
//                                           ),
//                                           child: Row(
//                                             mainAxisSize: MainAxisSize.min,
//                                             children: [
//                                               Text(
//                                                 S.of(context).in_stock,
//                                                 style: AppStyle.styleRegular12(context).copyWith(color: Colors.white),
//                                               ),
//                                               // if (selectedVariation !=
//                                               //     null) ...[
//                                               //   Text(
//                                               //     " (${displayData['stockQuantity']} available)",
//                                               //     style:
//                                               //         AppStyle.styleRegular10(
//                                               //           context,
//                                               //         ).copyWith(
//                                               //           color: Colors.white70,
//                                               //         ),
//                                               //   ),
//                                               // ],
//                                             ],
//                                           ),
//                                         )
//                                       : Container(
//                                           padding: EdgeInsets.all(12.r),
//                                           decoration: BoxDecoration(
//                                             color: Colors.red,
//                                             borderRadius: BorderRadius.circular(12.r),
//                                           ),
//                                           child: Text(
//                                             S.of(context).out_of_stock,
//                                             style: AppStyle.styleRegular14(context).copyWith(color: Colors.white),
//                                           ),
//                                         ),
//
//                                   const SizedBox(height: 20),
//
//                                   ProductsSelectionOptions(
//                                     variations: product.productVariations,
//                                     onSelectionChanged: (attributes, quantity, matchedVariation) {
//                                       setState(() {
//                                         chosenAttributes = attributes;
//                                         chosenQuantity = quantity;
//                                         selectedVariation = matchedVariation;
//                                       });
//                                     },
//                                   ),
//
//                                   SizedBox(height: 20.h),
//
//                                   CustomExpansionTile(
//                                     title: S.of(context).description,
//                                     content: product.description.replaceAll(
//                                       RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true),
//                                       '',
//                                     ),
//                                   ),
//
//                                   SizedBox(height: 30.h),
//
//                                   BlocBuilder<GetReviewCubit, GetReviewState>(
//                                     builder: (context, state) {
//                                       if (state is GetReviewSuccess) {
//                                         return SizedBox(
//                                           height: state.reviews.isEmpty ? 0 : 180.h,
//                                           child: ListView.builder(
//                                             scrollDirection: Axis.horizontal,
//                                             shrinkWrap: true,
//                                             itemCount: state.reviews.length,
//                                             itemBuilder: (context, index) {
//                                               final review = state.reviews[index];
//                                               return Padding(
//                                                 padding: const EdgeInsets.all(8.0),
//                                                 child: ReviewContainer(
//                                                   userName: review.reviewer,
//                                                   reviewText: review.review,
//                                                   reviewDate: review.dateCreated,
//                                                   rating: review.rating,
//                                                 ),
//                                               );
//                                             },
//                                           ),
//                                         );
//                                       }
//                                       return const SizedBox();
//                                     },
//                                   ),
//
//                                   SizedBox(height: 30.h),
//
//                                   Align(
//                                     alignment: context.read<LocalizationsCubit>().state.languageCode == 'ar'
//                                         ? Alignment.centerRight
//                                         : Alignment.centerLeft,
//                                     child: RatingBar.builder(
//                                       unratedColor: AppColors.paleGray,
//                                       initialRating: _rating,
//                                       minRating: 0.5,
//
//                                       direction: Axis.horizontal,
//                                       allowHalfRating: true,
//                                       itemCount: 5,
//                                       itemSize: 25.sp,
//                                       itemPadding: EdgeInsets.symmetric(horizontal: 4.w),
//                                       itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
//                                       onRatingUpdate: (rating) {
//                                         setState(() {
//                                           _rating = rating;
//                                         });
//                                       },
//                                     ),
//                                   ),
//                                   SizedBox(height: 10.h),
//
//                                   BlocConsumer<CreateReviewCubit, CreateReviewState>(
//                                     listener: (context, state) {
//                                       if (state is CreateReviewSuccess) {
//                                         _reviewController.clear();
//                                         setState(() {
//                                           _rating = 0.0;
//                                         });
//                                         AppToast.show(
//                                           gravity: ToastGravity.TOP,
//                                           backgroundColor: Colors.green,
//                                           msg: S.of(context).Review_Added_Successfully,
//                                         );
//                                       }
//
//                                       if (state is CreateReviewError) {
//                                         AppToast.show(
//                                           gravity: ToastGravity.TOP,
//                                           backgroundColor: Colors.red,
//                                           msg: state.error.message,
//                                         );
//                                       }
//                                     },
//                                     builder: (context, state) {
//                                       return CustomTextFormField(
//                                         controller: _reviewController,
//                                         maxLines: 2,
//                                         // maxLength: 2000,
//                                         hintText: S.of(context).add_review,
//
//                                         suffixIcon: GestureDetector(
//                                           child: state is CreateReviewLoading
//                                               ? Padding(
//                                                   padding: EdgeInsets.all(12.r),
//                                                   child: const CircularProgressIndicator(color: AppColors.primaryColor),
//                                                 )
//                                               : const Icon(Icons.send, color: AppColors.primaryColor),
//                                           onTap: () async {
//                                             if (_reviewController.text.isNotEmpty) {
//                                               await context.read<CreateReviewCubit>().createReview(
//                                                 productId: product.id,
//                                                 review: _reviewController.text,
//                                                 rating: _rating,
//                                               );
//
//                                               context.read<GetReviewCubit>().getReviews(
//                                                 lang: context.read<LocalizationsCubit>().state.languageCode,
//                                                 productId: product.id.toString(),
//                                               );
//                                             }
//                                           },
//                                         ),
//                                       );
//                                     },
//                                   ),
//
//                                   // const CustomExpansionTile(
//                                   //   title: "طريقة الاستعمال",
//                                   //   content:
//                                   //       "هذه حقيقة مثبتة لا يمكن تغييرها هذه حقيقة مثبتة لا يمكن تغييرها هذه حقيقة مثبتة لا يمكن تغييرها هذه حقيقة مثبتة لا يمكن تغييرها هذه حقيقة مثبتة هذه حقيقة مثبتة لا يمكن تغييرها هذه حقيقة مثبتة لا يمكن تغييرها هذه حقيقة مثبتة لا يمكن تغييرها هذه حقيقة مثبتة لا يمكن تغييرها هذه حقيقة مثبتة",
//                                   // ),
//
//                                   // SizedBox(height: 20.h),
//
//                                   // Image.asset(
//                                   //   Assets.imagesProductRate,
//
//                                   //   // width: double.infinity,
//                                   //   // height: 120.h,
//                                   // ),
//                                   SizedBox(height: 30.h),
//                                   SizedBox(
//                                     width: double.infinity,
//                                     child: BlocConsumer<AddCartCubit, AddCartState>(
//                                       listener: (context, state) {
//                                         if (state is AddCartError) {
//                                           AppToast.show(
//                                             gravity: ToastGravity.TOP,
//                                             backgroundColor: AppColors.primaryColor,
//                                             msg: state.error.message,
//                                           );
//                                         }
//                                       },
//                                       builder: (context, state) {
//                                         return product.isInCart!
//                                             ? ElevatedButton(
//                                                 onPressed: () {
//                                                   GoRouter.of(context).push(AppRouter.myCart);
//                                                 },
//                                                 style: ElevatedButton.styleFrom(
//                                                   padding: EdgeInsets.symmetric(vertical: 16.h),
//                                                   backgroundColor: AppColors.blueC3,
//                                                   shape: RoundedRectangleBorder(
//                                                     borderRadius: BorderRadius.circular(16.r),
//                                                   ),
//                                                 ),
//                                                 child: Row(
//                                                   mainAxisAlignment: MainAxisAlignment.center,
//                                                   children: [
//                                                     Text(
//                                                       S.of(context).go_to_cart,
//                                                       style: AppStyle.styleRegular15(
//                                                         context,
//                                                       ).copyWith(color: Colors.white),
//                                                     ),
//
//                                                     SizedBox(width: 6.w),
//
//                                                     SvgPicture.asset(
//                                                       Assets.imagesShoppingCartWhite,
//                                                       width: 22.w,
//                                                       height: 22.h,
//                                                     ),
//                                                   ],
//                                                 ),
//                                               )
//                                             : state is AddCartSuccess
//                                             ? ElevatedButton(
//                                                 onPressed: () {
//                                                   GoRouter.of(context).push(AppRouter.myCart);
//                                                 },
//                                                 style: ElevatedButton.styleFrom(
//                                                   padding: EdgeInsets.symmetric(vertical: 16.h),
//                                                   backgroundColor: AppColors.blueC3,
//                                                   shape: RoundedRectangleBorder(
//                                                     borderRadius: BorderRadius.circular(16.r),
//                                                   ),
//                                                 ),
//                                                 child: Row(
//                                                   mainAxisAlignment: MainAxisAlignment.center,
//                                                   children: [
//                                                     Text(
//                                                       S.of(context).go_to_cart,
//                                                       style: AppStyle.styleRegular15(
//                                                         context,
//                                                       ).copyWith(color: Colors.white),
//                                                     ),
//
//                                                     SizedBox(width: 6.w),
//
//                                                     SvgPicture.asset(
//                                                       Assets.imagesShoppingCartWhite,
//                                                       width: 22.w,
//                                                       height: 22.h,
//                                                     ),
//                                                   ],
//                                                 ),
//                                               )
//                                             : ElevatedButton(
//                                                 onPressed: () async {
//                                                   final variations = chosenAttributes.entries.map((entry) {
//                                                     return {"attribute": entry.key.toLowerCase(), "value": entry.value};
//                                                   }).toList();
//
//                                                   await context.read<AddCartCubit>().addToCart(
//                                                     productId: product.id.toString(),
//                                                     variations: variations,
//                                                     quantity: chosenQuantity,
//                                                   );
//
//                                                   if (mounted) {
//                                                     context.read<GetCartCubit>().getCart(
//                                                       context.read<LocalizationsCubit>().state.languageCode,
//                                                     );
//                                                   }
//                                                   // MyCartScreen
//                                                   //     .cartKey
//                                                   //     .currentState
//                                                   //     ?.refreshGetCart();
//                                                   HomeScreen.homeKey.currentState?.refreshWishListAndCartList();
//                                                 },
//                                                 style: ElevatedButton.styleFrom(
//                                                   padding: EdgeInsets.symmetric(vertical: 16.h),
//                                                   backgroundColor: AppColors.primaryColor,
//                                                   shape: RoundedRectangleBorder(
//                                                     borderRadius: BorderRadius.circular(16.r),
//                                                   ),
//                                                 ),
//                                                 child: Row(
//                                                   mainAxisAlignment: MainAxisAlignment.center,
//                                                   children: state is AddCartLoading
//                                                       ? [const CircularProgressIndicator(color: Colors.white)]
//                                                       : [
//                                                           Text(
//                                                             S.of(context).add_to_cart,
//                                                             style: AppStyle.styleRegular15(
//                                                               context,
//                                                             ).copyWith(color: Colors.white),
//                                                           ),
//                                                           SizedBox(width: 6.w),
//                                                           SvgPicture.asset(
//                                                             Assets.imagesShoppingCartWhite,
//                                                             width: 18.w,
//                                                             height: 18.h,
//                                                           ),
//                                                         ],
//                                                 ),
//                                               );
//                                       },
//                                     ),
//                                   ),
//                                 ],
//                               );
//                             }
//
//                             if (state is ProductIdDetailsError) {
//                               return Center(
//                                 child: Column(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   crossAxisAlignment: CrossAxisAlignment.center,
//                                   children: [
//                                     Icon(state.error.icon, color: Colors.red, size: 50),
//
//                                     SizedBox(height: 20.h),
//                                     Text(
//                                       state.error.message,
//                                       style: TextStyle(fontSize: 16.sp, color: Colors.red),
//                                       textAlign: TextAlign.center,
//                                     ),
//
//                                     SizedBox(height: 10.h),
//
//                                     ElevatedButton(
//                                       onPressed: () {
//                                         context.read<ProductIdDetailsCubit>().getProductDetails(
//                                           widget.productId,
//                                           context.read<LocalizationsCubit>().state.languageCode,
//                                         );
//                                         ();
//                                       },
//                                       child: Text(S.of(context).retry, style: TextStyle(fontSize: 16.sp)),
//                                     ),
//                                   ],
//                                 ),
//                               );
//                             }
//
//                             return Container();
//                           },
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   SizedBox(height: 20.h),
//                 ],
//               ),
//             ),
//
//             SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).viewInsets.bottom)),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:camion/config/localization/cubit/localizations_cubit.dart';
import 'package:camion/features/currency/presentation/logic/cubit/currency_cubit.dart';
import 'package:camion/config/widgets/custom_elevated_button.dart';
import 'package:camion/config/widgets/discount_percentage_badge.dart';
import 'package:camion/config/widgets/formatted_price_text.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_images.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/core/utils/currency_display_utils.dart';
import 'package:camion/core/utils/navigation_utils.dart';
import 'dart:async';

import 'package:camion/core/services/appsflyer_service.dart';
import 'package:camion/core/utils/product_description_formatter.dart';
import 'package:camion/core/services/cart_refresh_notifier.dart';
import 'package:camion/core/services/tiktok_business_service.dart';
import 'package:camion/core/services/transient_extras_store.dart';
import 'package:camion/features/cart/data/repository/cart_repo.dart';
import 'package:camion/features/cart/presentation/logic/cubit/add_cart_cubit/add_cart_cubit.dart';
import 'package:camion/features/home/data/models/all_products_model/all_products_model.dart';
import 'package:camion/features/home/data/models/all_products_model/sub_models/add_to_cart.dart';
import 'package:camion/features/home/data/models/all_products_model/sub_models/attribute.dart';
import 'package:camion/features/home/data/models/all_products_model/sub_models/brand.dart';
import 'package:camion/features/home/data/models/all_products_model/sub_models/category.dart';
import 'package:camion/features/home/data/models/all_products_model/sub_models/prices_model.dart';
import 'package:camion/features/home/data/models/all_products_model/sub_models/product_image.dart';
import 'package:camion/features/home/data/models/all_products_model/sub_models/product_variations.dart';
import 'package:camion/features/home/data/models/all_products_model/sub_models/stock_availability.dart';
import 'package:camion/features/home/data/models/all_products_model/sub_models/variation.dart';
import 'package:camion/features/home/data/models/home_graphql/home_graphql_models.dart';
import 'package:camion/features/home/data/models/reviews_model/review_model.dart';
import 'package:camion/features/home/data/repository/home_repo.dart';
import 'package:camion/features/home/presentation/logic/cubit/product_id_detailscubit/product_id_details_cubit.dart';
import 'package:camion/features/home/presentation/logic/cubit/toggle_product_id_images/toggle_product_id_images_cubit.dart';
import 'package:camion/features/home/presentation/screens/home_screen.dart';
import 'package:camion/features/home/presentation/widgets/product_collection_card.dart';
import 'package:camion/features/home/presentation/widgets/product_id_image_skeletonizer.dart';
import 'package:camion/features/home/presentation/widgets/products_options.dart';
import 'package:camion/features/searching/presentation/widgets/recent_search_sheet.dart';
import 'package:camion/features/wish_list/data/models/get_wish_list_model.dart';
import 'package:camion/features/wish_list/presentation/logic/cubit/add_to_wish_list/wish_list_cubit.dart';
import 'package:camion/features/wish_list/presentation/logic/cubit/get_wish_listcubit/get_wish_list_cubit.dart';
import 'package:camion/features/wish_list/presentation/screens/wish_list_screen.dart';
import 'package:camion/generated/l10n.dart';
import 'package:camion/routing/app_router.dart';
import 'package:camion/core/api/api_error_model.dart';
import 'package:camion/core/api/api_locale_mapper.dart';
import 'package:camion/core/api/end_points.dart';
import 'package:camion/core/cache/cache_helper.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/api/local_status_codes.dart';
import 'package:camion/core/config/app_config.dart';
import 'package:camion/core/constants/app_defaults.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/utils/image_url_transformer.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:camion/core/utils/app_toast.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:skeletonizer/skeletonizer.dart';

double _parseTikTokMoney(dynamic rawValue) {
  final text = rawValue?.toString().trim() ?? '';
  if (text.isEmpty) return 0.0;
  return double.tryParse(text.replaceAll(RegExp(r'[^0-9.\-]'), '')) ?? 0.0;
}

class _CheckoutThresholds {
  const _CheckoutThresholds({
    required this.minimumOrderAmount,
    required this.freeShippingAmount,
  });

  final double minimumOrderAmount;
  final double? freeShippingAmount;
}

class ProductDetails extends StatefulWidget {
  const ProductDetails({
    super.key,
    required this.productId,
    this.productSlug = '',
    this.initialVariantUuid = '',
  });
  final String productId;
  final String productSlug;
  final String initialVariantUuid;
  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  static const Set<String> _supportedGraphqlCurrencies = {
    'qar',
    'aed',
    'sar',
    'kwd',
    'omr',
    'bhd',
    'usd',
  };

  final pageController = PageController();
  bool _isSimilarProductsGridView = true;
  bool _isRelatedLoading = false;
  bool _isGraphqlProductLoading = false;
  String _relatedSlug = '';
  String _graphqlProductSlug = '';
  List<HomeGraphqlProduct> _relatedProducts = const <HomeGraphqlProduct>[];
  List<ReviewModel> _graphqlReviews = const <ReviewModel>[];
  HomeGraphqlProduct? _graphqlProductDetail;
  String _currentCustomerUuid = '';
  int _selectionVersion = 0;
  String? _lastLocaleCode;
  int _loadSequence = 0;
  bool _isShowingAddedToCartPreviewSheet = false;
  bool _hasTrackedTikTokViewContent = false;
  bool _isBuyNowLoading = false;
  bool _isWishlistBusy = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentCustomerUuid();
    AppNavigator.isAuthenticatedCustomer().then((isAuthenticated) {
      if (!mounted) return;
      if (isAuthenticated) {
        BlocProvider.of<GetWishListCubit>(context).getWishList();
      }
    });
    _reloadProductDetail();
    final contentId = widget.productId.trim().isNotEmpty
        ? widget.productId.trim()
        : widget.productSlug.trim();
    if (contentId.isNotEmpty) {
      unawaited(
        sl<AppsFlyerService>().logProductView(
          productId: contentId,
          productSlug: widget.productSlug.trim(),
        ),
      );
    }
  }

  double _parseTikTokPrice(dynamic rawValue) {
    final text = rawValue?.toString().trim() ?? '';
    if (text.isEmpty) return 0.0;
    return double.tryParse(text.replaceAll(RegExp(r'[^0-9.\-]'), '')) ?? 0.0;
  }

  Future<void> _trackTikTokViewContent({
    required String contentId,
    required String contentName,
    required String description,
    required String currency,
    required double value,
    String? brand,
  }) async {
    if (_hasTrackedTikTokViewContent) return;
    _hasTrackedTikTokViewContent = true;
    try {
      await TikTokBusinessService.viewContent(
        contentId: contentId,
        description: description,
        contentType: 'product',
        value: value.toStringAsFixed(2),
        currency: currency,
        contents: [
          {
            'contentId': contentId,
            'contentName': contentName,
            if (brand != null && brand.trim().isNotEmpty) 'brand': brand.trim(),
            'price': value,
            'quantity': 1,
          },
        ],
      );
    } catch (error, stackTrace) {
      debugPrint('[TIKTOK][VIEW_CONTENT] tracking failed: $error');
      debugPrint(stackTrace.toString());
    }
  }

  Future<void> _trackLegacyProductView(AllProductModel product) async {
    final contentId = product.id.toString();
    final contentName = product.name.trim();
    final description = product.shortDescription.trim().isNotEmpty
        ? product.shortDescription.trim()
        : product.description.trim();
    final currency = product.prices.currencyCode.trim().isNotEmpty
        ? product.prices.currencyCode.trim().toUpperCase()
        : 'USD';
    final brand = product.brands.isNotEmpty ? product.brands.first.name : null;
    final value = _parseTikTokPrice(product.prices.price);
    await _trackTikTokViewContent(
      contentId: contentId,
      contentName: contentName,
      description: description,
      currency: currency,
      value: value,
      brand: brand,
    );
  }

  String _fallbackProductShareUrl() {
    final shareSlug = (_graphqlProductDetail?.slug ?? widget.productSlug)
        .trim();
    final languageCode = Localizations.localeOf(context).languageCode == 'ar'
        ? 'ar'
        : 'en';
    return shareSlug.isNotEmpty
        ? 'https://camion-app.com/$languageCode/shop/$shareSlug'
        : 'https://camion-app.com/$languageCode/shop/${widget.productId}';
  }

  Future<void> _shareProduct() async {
    final shareSlug = (_graphqlProductDetail?.slug ?? widget.productSlug)
        .trim();
    final selectedVariantUuid = widget.initialVariantUuid.trim();
    final shareLink =
        sl<AppsFlyerService>().buildProductShareLink(
          productId: widget.productId,
          productSlug: shareSlug.isNotEmpty ? shareSlug : null,
          variantUuid: selectedVariantUuid.isNotEmpty
              ? selectedVariantUuid
              : null,
        ) ??
        _fallbackProductShareUrl();

    final renderBox = context.findRenderObject() as RenderBox?;
    final shareOrigin = renderBox != null
        ? renderBox.localToGlobal(Offset.zero) & renderBox.size
        : null;
    unawaited(
      sl<AppsFlyerService>().logConversionEvent(
        'share_product',
        eventParams: {
          'product_id': widget.productId.trim(),
          'variant_id': selectedVariantUuid,
          'category': 'product',
        },
      ),
    );
    await SharePlus.instance.share(
      ShareParams(
        text: shareLink,
        subject: _graphqlProductDetail?.title ?? widget.productSlug,
        sharePositionOrigin: shareOrigin,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localeCode = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase();
    if (_lastLocaleCode == null) {
      _lastLocaleCode = localeCode;
      return;
    }
    if (_lastLocaleCode == localeCode) {
      return;
    }
    _lastLocaleCode = localeCode;
    setState(() {
      selectedVariation = null;
      chosenAttributes.clear();
      chosenQuantity = 1;
      _graphqlProductDetail = null;
      _graphqlReviews = const <ReviewModel>[];
      _relatedProducts = const <HomeGraphqlProduct>[];
      _graphqlProductSlug = '';
      _relatedSlug = '';
      _isGraphqlProductLoading = true;
      _isRelatedLoading = true;
    });
    _reloadProductDetail(forceRefresh: true);
  }

  Future<void> _loadCurrentCustomerUuid() async {
    final userId = await sl<SecureCacheHelper>().getData(key: 'id');
    if (!mounted) return;
    setState(() {
      _currentCustomerUuid = (userId ?? '').toString().trim();
    });
  }

  Future<void> _loadGraphqlProductAndRelated({
    required String slug,
    bool forceRefresh = false,
  }) async {
    final normalizedSlug = slug.trim();
    if (normalizedSlug.isEmpty) return;
    if (!forceRefresh &&
        (_isGraphqlProductLoading || _isRelatedLoading) &&
        _graphqlProductSlug == normalizedSlug &&
        _relatedSlug == normalizedSlug) {
      return;
    }

    final loadVersion = ++_loadSequence;
    setState(() {
      _isGraphqlProductLoading = true;
      _isRelatedLoading = true;
      _graphqlProductSlug = normalizedSlug;
      _relatedSlug = normalizedSlug;
    });
    context.read<ProductIdDetailsCubit>().setLoading();

    final appLanguageCode = _activeLanguageCode();
    final language = ApiLocaleMapper.toGraphqlLocale(appLanguageCode);
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    final productResult = await sl<HomeRepository>().getProductGraphql(
      token: token,
      slug: normalizedSlug,
      language: language,
    );

    if (!mounted || loadVersion != _loadSequence) return;

    await productResult.fold<Future<void>>(
      (error) async {
        if (!mounted || loadVersion != _loadSequence) return;
        context.read<ProductIdDetailsCubit>().setError(error);
        setState(() {
          _graphqlProductDetail = null;
          _relatedProducts = const <HomeGraphqlProduct>[];
          _graphqlReviews = const <ReviewModel>[];
          _isGraphqlProductLoading = false;
          _isRelatedLoading = false;
        });
        return;
      },
      (product) async {
        if (!mounted || loadVersion != _loadSequence) return;
        final legacyProduct = _mapGraphqlProductToLegacy(product);
        final mappedReviews = _mapGraphqlReviews(product);
        final preselectedVariation = _resolveInitialSelectedVariation(
          product: product,
          mappedVariations: legacyProduct.productVariations,
        );
        final preselectedAttributes = preselectedVariation == null
            ? <String, String>{}
            : {
                for (final attribute in preselectedVariation.attributes)
                  attribute.name: attribute.option,
              };
        context.read<ProductIdDetailsCubit>().setProductDetails(legacyProduct);
        setState(() {
          _graphqlProductDetail = product;
          _graphqlReviews = mappedReviews;
          selectedVariation = preselectedVariation;
          chosenAttributes = preselectedAttributes;
          chosenQuantity = 1;
          _selectionVersion += 1;
          _isGraphqlProductLoading = false;
        });

        final relatedResult = await sl<HomeRepository>()
            .getRelatedGraphqlProducts(
              token: token,
              language: language,
              slug: normalizedSlug,
              pageNumber: 1,
              itemsPerPage: 8,
            );
        if (!mounted || loadVersion != _loadSequence) return;

        final relatedProducts = relatedResult.fold(
          (_) => const <HomeGraphqlProduct>[],
          (items) => items,
        );
        setState(() {
          _relatedProducts = relatedProducts;
          _isRelatedLoading = false;
        });
      },
    );
  }

  ProductVariations? _resolveInitialSelectedVariation({
    required HomeGraphqlProduct product,
    required List<ProductVariations> mappedVariations,
  }) {
    final targetVariantUuid = widget.initialVariantUuid.trim();
    if (targetVariantUuid.isEmpty ||
        product.options.isEmpty ||
        product.variants.isEmpty ||
        mappedVariations.isEmpty) {
      return null;
    }

    HomeGraphqlProductVariant? targetVariant;
    for (final variant in product.variants) {
      if (variant.uuid.trim() == targetVariantUuid) {
        targetVariant = variant;
        break;
      }
    }
    if (targetVariant == null) {
      return null;
    }

    final optionValueByUuid = <String, ({String key, String value})>{};
    for (final option in product.options) {
      final optionKey = _normalizeAttributeKey(option.name);
      if (optionKey.isEmpty) continue;
      for (final value in option.values) {
        final optionValueUuid = value.uuid.trim();
        final optionValue = _normalizeAttributeValue(value.value);
        if (optionValueUuid.isEmpty || optionValue.isEmpty) continue;
        optionValueByUuid[optionValueUuid] = (
          key: optionKey,
          value: optionValue,
        );
      }
    }

    final targetAttributes = <String, String>{};
    for (final ref in targetVariant.optionValues) {
      final mapped = optionValueByUuid[ref.optionValueUuid.trim()];
      if (mapped != null) {
        targetAttributes[mapped.key] = mapped.value;
      }
    }
    if (targetAttributes.isEmpty) {
      return null;
    }

    for (final variation in mappedVariations) {
      final variationAttributes = <String, String>{};
      for (final attribute in variation.attributes) {
        final key = _normalizeAttributeKey(attribute.name);
        final value = _normalizeAttributeValue(attribute.option);
        if (key.isEmpty || value.isEmpty) continue;
        variationAttributes[key] = value;
      }
      if (variationAttributes.isEmpty) continue;

      final allMatch = targetAttributes.entries.every(
        (entry) => variationAttributes[entry.key] == entry.value,
      );
      final sameLength = targetAttributes.length == variationAttributes.length;
      if (allMatch && sameLength) {
        return variation;
      }
    }

    return null;
  }

  Future<void> _reloadProductDetail({bool forceRefresh = false}) async {
    final candidate = (_graphqlProductDetail?.slug ?? _graphqlProductSlug)
        .trim();
    final routeSlug = widget.productSlug.trim();
    final fallback = widget.productId.trim();
    final slug = candidate.isNotEmpty
        ? candidate
        : (routeSlug.isNotEmpty ? routeSlug : fallback);
    if (slug.isEmpty) {
      context.read<ProductIdDetailsCubit>().setError(
        ApiErrorModel(message: 'Product identifier is missing'),
      );
      return;
    }
    await _loadGraphqlProductAndRelated(slug: slug, forceRefresh: forceRefresh);
  }

  Future<void> _refreshReviewsAfterMutation({
    ReviewModel? updatedReview,
    String? removedReviewId,
  }) async {
    final productId = _graphqlProductDetail?.uuid.trim() ?? '';
    if (productId.isEmpty) return;

    final reviewsResult = await sl<HomeRepository>().getReviews(
      productId: productId,
      lang: _activeLanguageCode(),
    );
    if (!mounted) return;

    reviewsResult.fold(
      (_) {
        setState(() {
          var nextReviews = _graphqlReviews;
          if (removedReviewId != null && removedReviewId.trim().isNotEmpty) {
            nextReviews = nextReviews
                .where((item) => item.id != removedReviewId.trim())
                .toList(growable: false);
          }
          if (updatedReview != null) {
            final existingIndex = nextReviews.indexWhere(
              (item) => item.id == updatedReview.id,
            );
            if (existingIndex >= 0) {
              nextReviews = nextReviews
                  .map(
                    (item) =>
                        item.id == updatedReview.id ? updatedReview : item,
                  )
                  .toList(growable: false);
            } else {
              nextReviews = [...nextReviews, updatedReview];
            }
          }
          _graphqlReviews = nextReviews;
        });
      },
      (freshReviews) {
        setState(() {
          _graphqlReviews = freshReviews;
        });
      },
    );
  }

  Future<ReviewModel?> _openReviewComposer({
    ReviewModel? existingReview,
  }) async {
    final productId = _graphqlProductDetail?.uuid.trim() ?? '';
    if (productId.isEmpty) return null;
    return showDialog<ReviewModel>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ProductReviewComposerDialog(
        productId: productId,
        existingReview: existingReview,
      ),
    );
  }

  Future<void> _openEditReviewComposer(ReviewModel review) async {
    final saved = await _openReviewComposer(existingReview: review);
    if (saved == null || !mounted) return;
    await _refreshReviewsAfterMutation(updatedReview: saved);
    if (!mounted) return;
    AppToast.show(
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.green,
      msg: Localizations.localeOf(context).languageCode == 'ar'
          ? 'تم تحديث التقييم بنجاح'
          : 'Review updated successfully',
    );
  }

  Future<void> _confirmAndDeleteReview(ReviewModel review) async {
    final productId = _graphqlProductDetail?.uuid.trim() ?? '';
    if (productId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            Localizations.localeOf(context).languageCode == 'ar'
                ? 'حذف التقييم'
                : 'Delete Review',
          ),
          content: Text(
            Localizations.localeOf(context).languageCode == 'ar'
                ? 'هل أنت متأكد أنك تريد حذف هذا التقييم؟'
                : 'Are you sure you want to delete this review?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                Localizations.localeOf(context).languageCode == 'ar'
                    ? 'لا'
                    : 'No',
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                Localizations.localeOf(context).languageCode == 'ar'
                    ? 'نعم'
                    : 'Yes',
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    final result = await sl<HomeRepository>().deleteReview(
      productId: productId,
      reviewId: review.id,
    );
    if (!mounted) return;
    result.fold(
      (error) {
        AppToast.show(
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.red,
          msg: error.message,
        );
      },
      (_) {
        final deletedId = review.id.trim();
        if (deletedId.isNotEmpty) {
          setState(() {
            _graphqlReviews = _graphqlReviews
                .where((item) => item.id.trim() != deletedId)
                .toList(growable: false);
          });
        }
        AppToast.show(
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.green,
          msg: Localizations.localeOf(context).languageCode == 'ar'
              ? 'تم حذف التقييم بنجاح'
              : 'Review deleted successfully',
        );
      },
    );
  }

  Future<void> _openCartAndHandleReturn(String productId) async {
    HomeScreen.homeKey.currentState?.refreshWishListAndCartList();
    CartRefreshNotifier.requestRefresh();
    if (!mounted) return;
    AppNavigator.rememberCartBackTarget(context);
    GoRouter.of(context).go(AppRouter.selectingFromBottomNavBarCartTab);
  }

  double _parseCheckoutConfigAmount(dynamic rawConfig) {
    if (rawConfig is! Map) return 0.0;
    final map = Map<String, dynamic>.from(rawConfig);
    for (final key in const ['decimalValue', 'integerValue', 'stringValue']) {
      final raw = map[key];
      final parsed = raw is num
          ? raw.toDouble()
          : double.tryParse((raw ?? '').toString().trim());
      if (parsed != null && parsed > 0) {
        return parsed;
      }
    }
    return 0.0;
  }

  String _checkoutCurrencyCode(AllProductModel product) {
    final saved = sl<CacheHelper>().getDataString(key: 'currencyCode');
    if (saved != null && saved.trim().isNotEmpty) {
      return saved.trim().toUpperCase();
    }

    final productCurrency = product.prices.currencyCode.trim();
    if (productCurrency.isNotEmpty) {
      return productCurrency.toUpperCase();
    }

    return AppDefaults.defaultCurrencyCode.toUpperCase();
  }

  double _buyNowUnitPrice(AllProductModel product) {
    final selected = selectedVariation;
    if (selected != null) {
      final salePrice = selected.salePrice.toDouble();
      if (salePrice > 0) return salePrice;
      return selected.price.toDouble();
    }

    final salePrice = double.tryParse(product.prices.salePrice.trim()) ?? 0;
    if (salePrice > 0) return salePrice;
    return double.tryParse(product.prices.price.trim()) ?? 0;
  }

  Future<_CheckoutThresholds?> _fetchCheckoutThresholds({
    required String currencyCode,
  }) async {
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'x-allow-graphql-partial-data': 'true',
      if ((token ?? '').trim().isNotEmpty) 'Authorization': 'Bearer $token',
    };

    const query = r'''
      query GetBuyNowCheckoutThresholds($currency: String) {
        getMinimumOrderValue(currency: $currency) {
          integerValue
          decimalValue
          stringValue
        }
        getFreeShippingValue(currency: $currency) {
          integerValue
          decimalValue
          stringValue
        }
      }
    ''';

    final response = await sl<Dio>().post(
      EndPoints.graphql,
      data: {
        'query': query,
        'variables': {'currency': currencyCode.toLowerCase()},
      },
      options: Options(
        headers: headers,
        responseType: ResponseType.json,
        validateStatus: (status) =>
            status != null && status >= 200 && status < 500,
      ),
    );

    final code = response.statusCode ?? 0;
    if (code < 200 || code >= 300 || response.data is! Map) {
      return null;
    }

    final dataMap = Map<String, dynamic>.from(response.data as Map);
    final data = dataMap['data'] is Map
        ? Map<String, dynamic>.from(dataMap['data'] as Map)
        : const <String, dynamic>{};
    return _CheckoutThresholds(
      minimumOrderAmount: _parseCheckoutConfigAmount(
        data['getMinimumOrderValue'],
      ),
      freeShippingAmount: (() {
        final value = _parseCheckoutConfigAmount(data['getFreeShippingValue']);
        return value > 0 ? value : null;
      })(),
    );
  }

  Future<bool> _ensureBuyNowMinimumOrderReached({
    required AllProductModel product,
    required String productUuid,
    required String variantUuid,
  }) async {
    final currencyCode = _checkoutCurrencyCode(product);
    final lineTotal = _buyNowUnitPrice(product) * chosenQuantity;
    final thresholds = await _fetchCheckoutThresholds(
      currencyCode: currencyCode,
    );

    if (!mounted) return false;
    if (thresholds == null) {
      AppToast.show(
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        msg: Localizations.localeOf(context).languageCode == 'ar'
            ? 'تعذر التحقق من الحد الأدنى للطلب. يرجى المحاولة مرة أخرى.'
            : 'Unable to verify minimum order amount. Please try again.',
      );
      return false;
    }

    final minimumAmount = thresholds.minimumOrderAmount;
    if (minimumAmount <= 0 || lineTotal >= minimumAmount) {
      unawaited(
        sl<AppsFlyerService>().logConversionEvent(
          'minimum_order_reached',
          eventParams: {
            'product_id': productUuid,
            'variant_id': variantUuid,
            'category': 'buy_now',
            'quantity': chosenQuantity,
            'cart_value': lineTotal,
            'currency': currencyCode,
          },
        ),
      );
      final freeShippingAmount = thresholds.freeShippingAmount;
      if (freeShippingAmount != null && lineTotal >= freeShippingAmount) {
        unawaited(
          sl<AppsFlyerService>().logConversionEvent(
            'free_shipping_reached',
            eventParams: {
              'product_id': productUuid,
              'variant_id': variantUuid,
              'category': 'buy_now',
              'quantity': chosenQuantity,
              'cart_value': lineTotal,
              'currency': currencyCode,
            },
          ),
        );
      }
      return true;
    }

    unawaited(
      sl<AppsFlyerService>().logConversionEvent(
        'minimum_order_not_reached',
        eventParams: {
          'product_id': productUuid,
          'variant_id': variantUuid,
          'category': 'buy_now',
          'quantity': chosenQuantity,
          'cart_value': lineTotal,
          'currency': currencyCode,
        },
      ),
    );

    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    final addResult = await sl<CartRepository>().addToCart(
      token: token,
      productUuid: productUuid,
      variantUuid: variantUuid,
      quantity: chosenQuantity,
    );

    var addedToCart = false;
    addResult.fold((_) => addedToCart = false, (_) => addedToCart = true);
    if (!mounted) return false;
    if (!addedToCart) {
      AppToast.show(
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        msg: _buyNowFailureMessage(''),
      );
      return false;
    }

    HomeScreen.homeKey.currentState?.refreshWishListAndCartList();
    CartRefreshNotifier.requestRefresh();

    await _showBuyNowMinimumOrderDialog(
      currentTotal: lineTotal,
      minimumAmount: minimumAmount,
      freeShippingAmount: thresholds.freeShippingAmount,
      currencyCode: currencyCode,
    );
    return false;
  }

  Future<void> _showBuyNowMinimumOrderDialog({
    required double currentTotal,
    required double minimumAmount,
    required double? freeShippingAmount,
    required String currencyCode,
  }) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final remainingMinimum = (minimumAmount - currentTotal)
        .clamp(0, double.infinity)
        .toDouble();
    final freeShippingRemaining = freeShippingAmount == null
        ? 0.0
        : (freeShippingAmount - currentTotal)
              .clamp(0, double.infinity)
              .toDouble();
    final progress = minimumAmount <= 0
        ? 1.0
        : (currentTotal / minimumAmount).clamp(0.0, 1.0).toDouble();
    final currency = currencyCode.toUpperCase();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 14.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34.w,
                      height: 34.w,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFFF4EA),
                      ),
                      child: Icon(
                        Icons.shopping_cart_checkout_rounded,
                        color: const Color(0xFFD97706),
                        size: 19.sp,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        isArabic
                            ? 'الحد الأدنى للطلب'
                            : 'Minimum order required',
                        style: TextStyle(
                          color: const Color(0xFF111827),
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Montes',
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99.r),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7.h,
                    backgroundColor: const Color(0xFFFFF4EA),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFD97706),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  isArabic
                      ? 'أضف ${formatMoneyForDisplay(context, remainingMinimum, currency)} إضافية للوصول إلى الحد الأدنى للطلب ${formatMoneyForDisplay(context, minimumAmount, currency)}.'
                      : 'Add ${formatMoneyForDisplay(context, remainingMinimum, currency)} more to place this order. Minimum order value is ${formatMoneyForDisplay(context, minimumAmount, currency)}.',
                  style: TextStyle(
                    color: const Color(0xFF374151),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Montes',
                    height: 1.35,
                  ),
                ),
                if (freeShippingAmount != null &&
                    freeShippingAmount > currentTotal) ...[
                  SizedBox(height: 8.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 9.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF9F2),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: const Color(0xFFB7E4CF)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_shipping_rounded,
                          color: const Color(0xFF0E9F6E),
                          size: 17.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            isArabic
                                ? 'أضف ${formatMoneyForDisplay(context, freeShippingRemaining, currency)} للحصول على الشحن المجاني.'
                                : 'Add ${formatMoneyForDisplay(context, freeShippingRemaining, currency)} more to unlock free shipping.',
                            style: TextStyle(
                              color: const Color(0xFF374151),
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Montes',
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 14.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      minimumSize: Size.fromHeight(42.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: Text(isArabic ? 'أضف المزيد' : 'Add More'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleBuyNow(AllProductModel product) async {
    if (_isBuyNowLoading) return;

    final currentProductId = _resolveCartProductId(product).trim();
    unawaited(
      sl<AppsFlyerService>().logConversionEvent(
        'buy_now_click',
        eventParams: {
          'product_id': currentProductId,
          'category': 'product',
          'quantity': chosenQuantity,
          'item_value': _buyNowUnitPrice(product),
          'currency': _checkoutCurrencyCode(product),
        },
      ),
    );
    if (currentProductId.isEmpty || currentProductId == '0') {
      AppToast.show(
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        msg: 'Unable to identify product for checkout. Please retry.',
      );
      return;
    }

    if (!_validateVariationSelection(product)) {
      return;
    }

    final selected = selectedVariation;
    if (selected != null) {
      final inStock = _isVariationStockAvailable(selected.stockStatus);
      if (!inStock) {
        AppToast.show(
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.red,
          msg: S.of(context).out_of_stock,
        );
        return;
      }
      if (selected.stockQuantity > 0 &&
          chosenQuantity > selected.stockQuantity) {
        AppToast.show(
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.red,
          msg: 'Only ${selected.stockQuantity} item(s) available.',
        );
        return;
      }
    } else if (product.isInStock == false) {
      AppToast.show(
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        msg: S.of(context).out_of_stock,
      );
      return;
    }

    final variantUuid = _resolveCartVariantUuid(product).trim();
    if (variantUuid.isEmpty) {
      unawaited(
        sl<AppsFlyerService>().logConversionEvent(
          'buy_now_variant_missing',
          eventParams: {
            'product_id': currentProductId,
            'category': 'product',
            'quantity': chosenQuantity,
            'item_value': _buyNowUnitPrice(product),
            'currency': _checkoutCurrencyCode(product),
            'error_stage': 'variant_selection',
          },
        ),
      );
      AppToast.show(
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        msg: 'Please select a valid variant.',
      );
      return;
    }

    setState(() => _isBuyNowLoading = true);
    try {
      final minimumReached = await _ensureBuyNowMinimumOrderReached(
        product: product,
        productUuid: currentProductId,
        variantUuid: variantUuid,
      );
      if (!minimumReached) {
        return;
      }

      final token = await sl<SecureCacheHelper>().getData(key: 'token');
      final result = await sl<CartRepository>().addToCart(
        token: token,
        productUuid: currentProductId,
        variantUuid: variantUuid,
        quantity: chosenQuantity,
      );

      if (!mounted) return;

      await result.fold(
        (error) async {
          AppToast.show(
            gravity: ToastGravity.TOP,
            backgroundColor: Colors.red,
            msg: _buyNowFailureMessage(''),
          );
        },
        (response) async {
          final cartItemUuid = _extractCartItemUuid(response);
          if (cartItemUuid.isEmpty) {
            AppToast.show(
              gravity: ToastGravity.TOP,
              backgroundColor: Colors.red,
              msg: _buyNowFailureMessage(''),
            );
            return;
          }

          HomeScreen.homeKey.currentState?.refreshWishListAndCartList();
          CartRefreshNotifier.requestRefresh();

          final payload = <String, dynamic>{
            'buyNow': true,
            'cartItemUuid': cartItemUuid,
            'cartItemUuids': <String>[cartItemUuid],
            'subTotal': 0.0,
            'shipping': 0.0,
            'discountTotal': 0.0,
            'total': 0.0,
            'itemsDiscount': 0.0,
            'couponDiscount': 0.0,
          };

          final isAuthenticated = await AppNavigator.isAuthenticatedCustomer();
          if (!mounted) return;

          if (isAuthenticated) {
            GoRouter.of(
              context,
            ).push(AppRouter.confirmShippingAddressScreen, extra: payload);
            return;
          }

          unawaited(
            sl<AppsFlyerService>().logConversionEvent(
              'login_required',
              eventParams: {
                'product_id': currentProductId,
                'variant_id': variantUuid,
                'category': 'buy_now',
              },
            ),
          );
          final extraKey = sl<TransientExtrasStore>().put(payload);
          final next = Uri.encodeComponent(
            Uri(
              path: AppRouter.confirmShippingAddressScreen,
              queryParameters: {'extraKey': extraKey},
            ).toString(),
          );
          GoRouter.of(context).push('${AppRouter.login}?next=$next');
        },
      );
    } catch (_) {
      if (!mounted) return;
      AppToast.show(
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        msg: _buyNowFailureMessage(''),
      );
    } finally {
      if (mounted) {
        setState(() => _isBuyNowLoading = false);
      }
    }
  }

  String _buyNowFailureMessage(String message) {
    final normalized = message.trim();
    if (normalized.isNotEmpty) return normalized;
    return Localizations.localeOf(context).languageCode == 'ar'
        ? 'يرجى المحاولة مرة أخرى لاحقًا.'
        : 'Please try again later.';
  }

  String _extractCartItemUuid(dynamic response) {
    if (response is Map) {
      final direct = (response['uuid'] ?? response['id'])?.toString().trim();
      if (direct != null && direct.isNotEmpty) return direct;
      for (final key in const ['data', 'cartItem', 'item', 'createdCartItem']) {
        final nested = _extractCartItemUuid(response[key]);
        if (nested.isNotEmpty) return nested;
      }
    }
    return '';
  }

  Future<void> _showAddedToCartPreviewSheet(AllProductModel product) async {
    if (_isShowingAddedToCartPreviewSheet || !mounted) {
      return;
    }
    _isShowingAddedToCartPreviewSheet = true;

    try {
      final selected = selectedVariation;
      final resolvedImage = (selected?.image ?? '').trim().isNotEmpty
          ? (selected!.image ?? '').trim()
          : product.primaryImageUrl.trim();

      final optionPairs =
          selected?.attributes
              .map(
                (attribute) => (attribute.name.trim(), attribute.option.trim()),
              )
              .where((pair) => pair.$1.isNotEmpty || pair.$2.isNotEmpty)
              .toList(growable: false) ??
          chosenAttributes.entries
              .map((entry) => (entry.key.trim(), entry.value.trim()))
              .where((pair) => pair.$1.isNotEmpty || pair.$2.isNotEmpty)
              .toList(growable: false);

      final unitPrice = selected != null
          ? (selected.salePrice > 0 ? selected.salePrice : selected.price)
                .toDouble()
          : double.tryParse(product.prices.salePrice) ??
                double.tryParse(product.prices.price) ??
                0.0;
      final totalPrice = unitPrice * chosenQuantity;
      final currency = product.prices.currencyCode.trim().isNotEmpty
          ? product.prices.currencyCode.trim().toUpperCase()
          : AppDefaults.defaultCurrencyCode.toUpperCase();
      final title = product.name.trim().isNotEmpty
          ? product.name.trim()
          : product.slug.trim();
      final isArabic = Localizations.localeOf(context).languageCode == 'ar';

      await showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return Container(
            margin: EdgeInsets.only(top: 24.h),
            padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 18.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 42.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(99.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 42.w,
                        height: 42.w,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F7F9),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        alignment: Alignment.center,
                        child: SvgPicture.asset(
                          Assets.imagesIconsInCartSuccess,
                          width: 24.w,
                          height: 24.w,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isArabic
                                  ? 'تمت الإضافة إلى السلة'
                                  : 'Added to cart',
                              style: TextStyle(
                                color: const Color(0xFF111827),
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Montes',
                                height: 1.2,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              isArabic
                                  ? 'يمكنك الاستمرار في التسوق أو الانتقال إلى السلة.'
                                  : 'You can continue shopping or go to your cart.',
                              style: TextStyle(
                                color: const Color(0xFF6B7280),
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w400,
                                fontFamily: 'Montes',
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(sheetContext).pop(),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 34.w,
                          height: 34.w,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(999.r),
                          ),
                          child: Icon(
                            Icons.close,
                            size: 18.sp,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 18.h),
                  Container(
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14.r),
                          child: Container(
                            width: 92.w,
                            height: 92.w,
                            color: const Color(0xFFE9EEF3),
                            child: resolvedImage.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: resolvedImage,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      color: const Color(0xFFE9EEF3),
                                    ),
                                    errorWidget: (_, __, ___) => Image.asset(
                                      Assets.imagesShoes,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Image.asset(
                                    Assets.imagesShoes,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: const Color(0xFF111827),
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Montes',
                                  height: 1.25,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              if (optionPairs.isNotEmpty)
                                Wrap(
                                  spacing: 6.w,
                                  runSpacing: 6.h,
                                  children: optionPairs.map((pair) {
                                    final label = pair.$1.isNotEmpty
                                        ? '${pair.$1}: '
                                        : '';
                                    return Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10.w,
                                        vertical: 6.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          999.r,
                                        ),
                                        border: Border.all(
                                          color: const Color(0xFFE5E7EB),
                                        ),
                                      ),
                                      child: Text(
                                        '$label${pair.$2}',
                                        style: TextStyle(
                                          color: const Color(0xFF374151),
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Montes',
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              SizedBox(height: 10.h),
                              Row(
                                children: [
                                  _PreviewStatPill(
                                    label: isArabic ? 'الكمية' : 'Qty',
                                    value: formatLocalizedNumber(
                                      context,
                                      chosenQuantity,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  _PreviewStatPill(
                                    label: isArabic ? 'السعر' : 'Price',
                                    value: formatMoneyForDisplay(
                                      context,
                                      unitPrice,
                                      currency,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                '${isArabic ? 'الإجمالي' : 'Total'}: ${formatMoneyForDisplay(context, totalPrice, currency)}',
                                style: TextStyle(
                                  color: const Color(0xFF111827),
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Montes',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 18.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: Icon(Icons.shopping_bag_outlined, size: 18.sp),
                          label: Text(
                            isArabic ? 'متابعة التسوق' : 'Continue shopping',
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFD1D5DB)),
                            foregroundColor: const Color(0xFF111827),
                            minimumSize: Size.fromHeight(48.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            textStyle: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Montes',
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            _openCartAndHandleReturn(product.id.toString());
                          },
                          icon: Icon(Icons.shopping_cart_outlined, size: 18.sp),
                          label: Text(
                            isArabic ? 'اذهب إلى السلة' : 'Go to cart',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            minimumSize: Size.fromHeight(48.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            textStyle: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Montes',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    } finally {
      _isShowingAddedToCartPreviewSheet = false;
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  // late AllProductModel prodcut;

  Map<String, String> chosenAttributes = {};
  int chosenQuantity = 1;
  ProductVariations? selectedVariation;

  bool _isVariationStockAvailable(String? status) {
    final normalized = (status ?? '').trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return normalized == 'instock' ||
        normalized == 'in_stock' ||
        normalized == 'in stock' ||
        normalized == 'available';
  }

  Map<String, dynamic> _getDisplayData(AllProductModel product) {
    if (selectedVariation != null) {
      return {
        'price': selectedVariation!.price.toString(),
        'regularPrice': selectedVariation!.regularPrice.toString(),
        'image': selectedVariation!.image,
        'stockQuantity': selectedVariation!.stockQuantity,
        'stockStatus': selectedVariation!.stockStatus,
        'isInStock': _isVariationStockAvailable(selectedVariation!.stockStatus),
      };
    }

    return {
      'price': product.prices.salePrice,
      'regularPrice': product.prices.regularPrice,
      'image': product.images.isNotEmpty ? product.images[0].thumbnail : '',
      'stockQuantity': 0,
      'stockStatus': product.isInStock ? 'instock' : 'outofstock',
      'isInStock': product.isInStock,
    };
  }

  String _resolveProductDescription(AllProductModel product) {
    final graphqlDescription = (_graphqlProductDetail?.description ?? '')
        .trim();
    final graphqlDescriptionHtml =
        (_graphqlProductDetail?.descriptionHtml ?? '').trim();
    return ProductDescriptionFormatter.resolveFull(
      descriptionHtml: graphqlDescriptionHtml.isNotEmpty
          ? graphqlDescriptionHtml
          : null,
      description: graphqlDescription.isNotEmpty
          ? graphqlDescription
          : product.description,
      shortDescription: product.shortDescription,
      fallback: Localizations.localeOf(context).languageCode == 'ar'
          ? 'الوصف غير متاح لهذا المنتج.'
          : 'Description is not available for this product.',
    );
  }

  String _resolveProductTitle(AllProductModel product) {
    final legacyTitle = product.name.trim();
    if (legacyTitle.isNotEmpty) return legacyTitle;

    final graphqlTitle = (_graphqlProductDetail?.title ?? '').trim();
    if (graphqlTitle.isNotEmpty) return graphqlTitle;

    final slugTitle =
        (widget.productSlug.trim().isNotEmpty
                ? widget.productSlug.trim()
                : widget.productId.trim())
            .replaceAll('-', ' ')
            .trim();
    if (slugTitle.isNotEmpty) return slugTitle;

    return 'Product';
  }

  String _resolveProductCategoryName(AllProductModel product) {
    final graphqlCategory = _graphqlProductDetail?.categoryNames
        .where((name) => name.trim().isNotEmpty)
        .cast<String?>()
        .firstWhere((name) => name != null, orElse: () => null);
    if (graphqlCategory != null && graphqlCategory.trim().isNotEmpty) {
      return graphqlCategory.trim();
    }

    final legacyCategory = product.categories
        .where((category) => category.name.trim().isNotEmpty)
        .cast<Category?>()
        .firstWhere((category) => category != null, orElse: () => null);
    if (legacyCategory != null && legacyCategory.name.trim().isNotEmpty) {
      return legacyCategory.name.trim();
    }

    return '';
  }

  bool _isConnectivityErrorStatus(int? statusCode) {
    return statusCode == LocalStatusCodes.connectionError ||
        statusCode == LocalStatusCodes.connectionTimeout ||
        statusCode == LocalStatusCodes.sendTimeout ||
        statusCode == LocalStatusCodes.receiveTimeout;
  }

  String _activeCurrencyCode(CurrencyCubit cubit) {
    final apiCurrency = (_graphqlProductDetail?.formattedCurrencyCode ?? '')
        .trim();
    if (apiCurrency.isNotEmpty) {
      return apiCurrency.toUpperCase();
    }

    final selectedCode = cubit.selectedCurrency?.code.trim();
    if (selectedCode != null && selectedCode.isNotEmpty) {
      return selectedCode.toUpperCase();
    }

    final savedCode = sl<CacheHelper>().getDataString(key: 'currencyCode');
    if (savedCode != null && savedCode.trim().isNotEmpty) {
      return savedCode.trim().toUpperCase();
    }

    return AppDefaults.defaultCurrencyCode;
  }

  String _activeLanguageCode() {
    final localized = context
        .read<LocalizationsCubit>()
        .state
        .languageCode
        .trim();
    if (localized.isNotEmpty) {
      return localized.toLowerCase();
    }

    final saved = sl<CacheHelper>().getDataString(key: 'languageCode');
    if (saved != null && saved.trim().isNotEmpty) {
      return saved.trim().toLowerCase();
    }

    return AppDefaults.defaultLanguageCode.toLowerCase();
  }

  String _fallbackCurrencyCodeFromProfile() {
    final saved = sl<CacheHelper>().getDataString(key: 'currencyCode');
    if (saved != null && saved.trim().isNotEmpty) {
      final normalized = saved.trim().toLowerCase();
      if (_supportedGraphqlCurrencies.contains(normalized)) {
        return normalized.toUpperCase();
      }
    }
    return AppDefaults.defaultCurrencyCode.toUpperCase();
  }

  String _normalizeAttributeKey(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return '';

    final lower = value.toLowerCase();
    if (lower.startsWith('attribute_')) {
      value = value.substring('attribute_'.length);
    } else if (lower.startsWith('pa_')) {
      value = value.substring('pa_'.length);
    }

    value = value.replaceAll('_', ' ').replaceAll('-', ' ');
    value = value.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
    return value;
  }

  String _normalizeAttributeValue(String raw) {
    return raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _formatVariationAttributeLabel(String raw) {
    final normalized = _normalizeAttributeKey(raw);
    if (normalized.isEmpty) return raw.trim();
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  List<String> _requiredVariationAttributeNames(AllProductModel product) {
    final variations = _effectiveProductVariations(product);
    final namesByNormalized = <String, String>{};
    for (final variation in variations) {
      for (final attribute in variation.attributes) {
        final normalizedName = _normalizeAttributeKey(attribute.name);
        if (normalizedName.isNotEmpty &&
            !namesByNormalized.containsKey(normalizedName)) {
          namesByNormalized[normalizedName] = _formatVariationAttributeLabel(
            attribute.name,
          );
        }
      }
    }
    return namesByNormalized.values.toList();
  }

  List<String> _missingVariationAttributeNames(AllProductModel product) {
    final requiredNames = _requiredVariationAttributeNames(product);
    if (requiredNames.isEmpty) return const [];

    final selected = <String>{};
    for (final entry in chosenAttributes.entries) {
      final key = _normalizeAttributeKey(entry.key);
      final value = _normalizeAttributeValue(entry.value);
      if (key.isNotEmpty && value.isNotEmpty) {
        selected.add(key);
      }
    }

    return requiredNames
        .where((name) => !selected.contains(name.toLowerCase()))
        .toList();
  }

  bool _validateVariationSelection(AllProductModel product) {
    final missingAttributes = _missingVariationAttributeNames(product);
    if (missingAttributes.isEmpty) return true;

    final missingText = missingAttributes.join(', ');
    AppToast.show(
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.red,
      msg: "Please select: $missingText",
    );
    return false;
  }

  String _resolveCartProductId(AllProductModel product) {
    final graphqlUuid = (_graphqlProductDetail?.uuid ?? '').trim();
    if (graphqlUuid.isNotEmpty) {
      return graphqlUuid;
    }

    final routeProductId = widget.productId.trim();
    if (routeProductId.isNotEmpty) {
      return routeProductId;
    }

    if (product.id > 0) {
      return product.id.toString();
    }

    return '0';
  }

  bool _matchesWishlistEntry({
    required GetWishListModel item,
    required String resolvedProductId,
    required String routeProductId,
    required String routeProductSlug,
    required String graphqlSlug,
  }) {
    final wishlistProductId = (item.productId ?? '').trim();
    final wishlistSlug = (item.productSlug ?? '').trim().toLowerCase();
    final normalizedResolvedId = resolvedProductId.trim();
    final normalizedRouteId = routeProductId.trim();
    final normalizedRouteSlug = routeProductSlug.trim().toLowerCase();
    final normalizedGraphqlSlug = graphqlSlug.trim().toLowerCase();

    if (wishlistProductId.isNotEmpty) {
      if (normalizedResolvedId.isNotEmpty &&
          wishlistProductId == normalizedResolvedId) {
        return true;
      }
      if (normalizedRouteId.isNotEmpty &&
          wishlistProductId == normalizedRouteId) {
        return true;
      }
    }

    if (wishlistSlug.isNotEmpty) {
      if (normalizedGraphqlSlug.isNotEmpty &&
          wishlistSlug == normalizedGraphqlSlug) {
        return true;
      }
      if (normalizedRouteSlug.isNotEmpty &&
          wishlistSlug == normalizedRouteSlug) {
        return true;
      }
    }

    return false;
  }

  String _resolveCartVariantUuid(AllProductModel product) {
    final graphql = _graphqlProductDetail;
    if (graphql != null) {
      final selected = <String, String>{};
      for (final entry in chosenAttributes.entries) {
        final key = _normalizeAttributeKey(entry.key);
        final value = _normalizeAttributeValue(entry.value);
        if (key.isNotEmpty && value.isNotEmpty) {
          selected[key] = value;
        }
      }

      if (selected.isNotEmpty) {
        final optionValueByUuid = <String, ({String key, String value})>{};
        for (final option in graphql.options) {
          final optionKey = _normalizeAttributeKey(option.name);
          if (optionKey.isEmpty) continue;
          for (final value in option.values) {
            final valueUuid = value.uuid.trim();
            final optionValue = _normalizeAttributeValue(value.value);
            if (valueUuid.isEmpty || optionValue.isEmpty) continue;
            optionValueByUuid[valueUuid] = (key: optionKey, value: optionValue);
          }
        }

        for (final variant in graphql.variants) {
          final variantSelection = <String, String>{};
          for (final ref in variant.optionValues) {
            final mapped = optionValueByUuid[ref.optionValueUuid.trim()];
            if (mapped != null) {
              variantSelection[mapped.key] = mapped.value;
            }
          }

          if (variantSelection.isEmpty) continue;
          final allMatch = variantSelection.entries.every(
            (entry) => selected[entry.key] == entry.value,
          );
          final sameLength = selected.length == variantSelection.length;
          if (allMatch && sameLength) {
            return variant.uuid.trim();
          }
        }
      }

      if (graphql.variantUuid?.trim().isNotEmpty == true) {
        return graphql.variantUuid!.trim();
      }
      if (graphql.displayableVariants.length == 1) {
        return graphql.displayableVariants.first.uuid.trim();
      }
    }

    if (selectedVariation != null && selectedVariation!.id > 0) {
      return selectedVariation!.id.toString();
    }
    return '';
  }

  List<ProductImage> _mapGraphqlImagesToLegacy(HomeGraphqlProduct product) {
    final images = <ProductImage>[];
    final seen = <String>{};
    var index = 0;

    final primaryImage = product.primaryVariantImageUrl.trim();
    if (primaryImage.isNotEmpty) {
      index += 1;
      images.add(
        ProductImage(
          id: index,
          src: primaryImage,
          thumbnail: primaryImage,
          srcset: '',
          sizes: '',
          name: product.title,
          alt: product.title,
        ),
      );
      seen.add('primary|$primaryImage|$primaryImage');
    }

    for (final variant in product.variants) {
      for (final image in variant.images) {
        final thumbnail = image.thumbnailUrl.trim().isNotEmpty
            ? image.thumbnailUrl.trim()
            : image.imageUrl.trim();
        final source = image.imageUrl.trim().isNotEmpty
            ? image.imageUrl.trim()
            : thumbnail;
        if (source.isEmpty && thumbnail.isEmpty) continue;

        final key = '${image.uuid}|$source|$thumbnail';
        if (!seen.add(key)) continue;

        index += 1;
        images.add(
          ProductImage(
            id: index,
            src: source,
            thumbnail: thumbnail.isEmpty ? source : thumbnail,
            srcset: '',
            sizes: '',
            name: image.alt.trim(),
            alt: image.alt.trim(),
          ),
        );
      }
    }

    if (images.isEmpty) {
      final fallback = product.primaryVariantImageUrl.trim();
      if (fallback.isNotEmpty) {
        images.add(
          ProductImage(
            id: 1,
            src: fallback,
            thumbnail: fallback,
            srcset: '',
            sizes: '',
            name: product.title,
            alt: product.title,
          ),
        );
      }
    }

    return images;
  }

  List<ReviewModel> _mapGraphqlReviews(HomeGraphqlProduct product) {
    return product.reviews
        .map(
          (review) => ReviewModel(
            id: review.uuid,
            customerId: review.customer?.uuid.trim() ?? '',
            dateCreated: DateTime.now(),
            reviewer: (review.customer?.fullName.trim().isNotEmpty ?? false)
                ? review.customer!.fullName.trim()
                : 'Anonymous',
            review: review.comment,
            rating: review.rating.toInt(),
            verified: false,
            isEdited: false,
            images: review.images
                .map(
                  (image) => ReviewImageModel(
                    id: image.uuid,
                    thumbnailUrl: image.thumbnailUrl,
                    imageUrl: image.imageUrl,
                  ),
                )
                .toList(growable: false),
          ),
        )
        .toList(growable: false);
  }

  AllProductModel _mapGraphqlProductToLegacy(HomeGraphqlProduct product) {
    final firstVariant = product.preferredPricingVariant;
    final regularPriceAmount =
        firstVariant?.price?.decimalAmount ??
        (product.originalPriceAmount > 0
            ? product.originalPriceAmount
            : product.priceAmount);
    final discountedPriceAmount =
        firstVariant?.discountedPrice?.decimalAmount ?? 0;
    final hasTwoDistinctPrices =
        discountedPriceAmount > 0 &&
        regularPriceAmount > 0 &&
        discountedPriceAmount != regularPriceAmount;
    final effectivePriceAmount = hasTwoDistinctPrices
        ? discountedPriceAmount
        : (regularPriceAmount > 0
              ? regularPriceAmount
              : (discountedPriceAmount > 0
                    ? discountedPriceAmount
                    : product.priceAmount));
    final cutoutPriceAmount = hasTwoDistinctPrices
        ? regularPriceAmount
        : regularPriceAmount;
    final priceText = effectivePriceAmount > 0
        ? effectivePriceAmount.toString()
        : '';
    final regularPriceText = cutoutPriceAmount > 0
        ? cutoutPriceAmount.toString()
        : '';
    final salePriceText = effectivePriceAmount > 0
        ? effectivePriceAmount.toString()
        : '';
    final rawCurrency =
        (firstVariant?.discountedPrice?.currencyCode ??
                firstVariant?.price?.currencyCode ??
                product.currencyCode)
            .trim();
    final currencyCode = rawCurrency.isEmpty
        ? _fallbackCurrencyCodeFromProfile()
        : rawCurrency.toUpperCase();
    final images = _mapGraphqlImagesToLegacy(product);
    final mappedVariations = _mapGraphqlVariationsToLegacy(
      product: product,
      fallbackImage: images.isNotEmpty ? images.first.thumbnail : '',
    );
    final mappedCategories = product.categoryNames
        .where((name) => name.trim().isNotEmpty)
        .toSet()
        .toList()
        .asMap()
        .entries
        .map(
          (entry) => Category(
            id: entry.value.hashCode.abs(),
            name: entry.value,
            slug: entry.value.toLowerCase().replaceAll(' ', '-'),
          ),
        )
        .toList();

    final resolvedTitle = product.title.trim().isNotEmpty
        ? product.title.trim()
        : product.slug.trim().replaceAll('-', ' ');

    return AllProductModel(
      id: product.uuid.hashCode.abs(),
      name: resolvedTitle,
      slug: product.slug,
      parent: 0,
      type: 'simple',
      variation: '',
      permalink: '',
      sku: firstVariant?.sku ?? '',
      shortDescription: product.brief.trim().isNotEmpty
          ? product.brief
          : resolvedTitle,
      description: product.description.trim().isNotEmpty
          ? product.description
          : product.descriptionHtml,
      onSale: hasTwoDistinctPrices,
      prices: Prices(
        price: priceText,
        regularPrice: regularPriceText,
        salePrice: salePriceText,
        currencyCode: currencyCode,
        currencySymbol: currencyCode,
        currencyMinorUnit: 2,
        currencyDecimalSeparator: '.',
        currencyThousandSeparator: ',',
        currencyPrefix: '',
        currencySuffix: '',
      ),
      priceHtml: '',
      averageRating: product.averageRatingText,
      reviewCount: product.reviewsCount,
      images: images,
      categories: mappedCategories,
      tags: const <Category>[],
      brands: const <Brand>[],
      attributes: const <Attribute>[],
      variations: const <Variation>[],
      productVariations: mappedVariations,
      hasOptions: product.options.isNotEmpty,
      isPurchasable: true,
      isInStock: true,
      isOnBackorder: false,
      stockAvailability: StockAvailability(text: '', className: ''),
      soldIndividually: false,
      addToCart: AddToCart(
        text: '',
        description: '',
        url: '',
        singleText: '',
        minimum: 1,
        maximum: 100,
        multipleOf: 1,
      ),
      isInCart: false,
      isInwishList: false,
      campaign: product.campaign == null
          ? null
          : AllProductCampaign(
              uuid: product.campaign!.uuid,
              name: product.campaign!.name,
              brief: product.campaign!.brief,
              slug: product.campaign!.slug,
              discountPercentage: product.campaign!.discountPercentage,
              startsAt: product.campaign!.startsAt,
              finishesAt: product.campaign!.finishesAt,
            ),
    );
  }

  List<ProductVariations> _effectiveProductVariations(AllProductModel product) {
    if (product.productVariations.isNotEmpty) {
      return product.productVariations;
    }

    final graphql = _graphqlProductDetail;
    if (graphql == null) {
      return const <ProductVariations>[];
    }

    final fallbackImage = product.images.isNotEmpty
        ? product.images.first.thumbnail
        : '';
    return _mapGraphqlVariationsToLegacy(
      product: graphql,
      fallbackImage: fallbackImage,
    );
  }

  List<ProductVariations> _mapGraphqlVariationsToLegacy({
    required HomeGraphqlProduct product,
    required String fallbackImage,
  }) {
    if (product.variants.isEmpty) {
      return const <ProductVariations>[];
    }

    final options = [...product.options]
      ..sort((a, b) => a.position.compareTo(b.position));
    final optionValueByUuid =
        <String, ({ProductAttribute attribute, int position})>{};
    for (final option in options) {
      final sortedValues = [...option.values]
        ..sort((a, b) => a.position.compareTo(b.position));
      for (final value in sortedValues) {
        final valueUuid = value.uuid.trim();
        if (valueUuid.isEmpty) continue;
        final optionName = option.name.trim();
        final optionValue = value.value.trim();
        if (optionName.isEmpty || optionValue.isEmpty) continue;
        optionValueByUuid[valueUuid] = (
          attribute: ProductAttribute(name: optionName, option: optionValue),
          position: option.position,
        );
      }
    }

    final mapped = <ProductVariations>[];
    for (final variant in product.variants) {
      final attributesWithPosition =
          <({ProductAttribute attribute, int position})>[];
      for (final ref in variant.optionValues) {
        final mappedAttributeWithPosition =
            optionValueByUuid[ref.optionValueUuid.trim()];
        final mappedAttribute = mappedAttributeWithPosition?.attribute;
        if (mappedAttribute != null &&
            mappedAttribute.name.isNotEmpty &&
            mappedAttribute.option.isNotEmpty) {
          attributesWithPosition.add((
            attribute: mappedAttribute,
            position: mappedAttributeWithPosition!.position,
          ));
        }
      }

      if (attributesWithPosition.isEmpty) {
        continue;
      }

      final variantRegularPrice = variant.price?.decimalAmount ?? 0;
      final variantDiscountedPrice = variant.discountedPrice?.decimalAmount ?? 0;
      final hasValidRegular = variantRegularPrice > 0;
      final hasValidDiscounted = variantDiscountedPrice > 0;
      if (!hasValidRegular && !hasValidDiscounted) {
        continue;
      }

      attributesWithPosition.sort((a, b) => a.position.compareTo(b.position));
      final attributes = attributesWithPosition
          .map((e) => e.attribute)
          .toList();

      final isVariantOnSale =
          hasValidRegular &&
          hasValidDiscounted &&
          variantDiscountedPrice != variantRegularPrice;
      final variantPrice = isVariantOnSale
          ? variantDiscountedPrice
          : (hasValidRegular ? variantRegularPrice : variantDiscountedPrice);
      final variantCutoutPrice = isVariantOnSale
          ? variantRegularPrice
          : variantPrice;
      if (variantPrice <= 0) {
        continue;
      }
      final variantImage = variant.bestImageUrl.isNotEmpty
          ? variant.bestImageUrl
          : (product.primaryVariantImageUrl.isNotEmpty
                ? product.primaryVariantImageUrl
                : fallbackImage);
      mapped.add(
        ProductVariations(
          id: variant.uuid.hashCode.abs(),
          attributes: attributes,
          image: variantImage,
          price: variantPrice,
          regularPrice: variantCutoutPrice,
          salePrice: variantPrice,
          // Stock quantity is unknown in the current GraphQL product payload.
          stockQuantity: 0,
          stockStatus: 'instock',
        ),
      );
    }

    return mapped;
  }

  List<String> _legacyImageUrls(AllProductModel product) {
    final urls = <String>[];
    final seen = <String>{};

    final featuredThumbnailUrl = product.featuredThumbnailUrl.trim();
    if (featuredThumbnailUrl.isNotEmpty && seen.add(featuredThumbnailUrl)) {
      urls.add(featuredThumbnailUrl);
    }

    final featuredImageUrl = product.featuredImageUrl.trim();
    if (featuredImageUrl.isNotEmpty && seen.add(featuredImageUrl)) {
      urls.add(featuredImageUrl);
    }

    for (final image in product.images) {
      final url = image.thumbnail.trim().isNotEmpty
          ? image.thumbnail.trim()
          : image.src.trim();
      if (url.isEmpty || !seen.add(url)) continue;
      urls.add(url);
    }
    return urls;
  }

  bool _isColorAttributeKey(String key) {
    final normalized = _normalizeAttributeKey(key);
    return normalized == 'color' ||
        normalized.contains('color') ||
        normalized.contains('colour') ||
        normalized.contains('spec');
  }

  String _selectedColorToken() {
    for (final entry in chosenAttributes.entries) {
      if (_isColorAttributeKey(entry.key)) {
        final value = _normalizeAttributeValue(entry.value);
        if (value.isNotEmpty) {
          return value;
        }
      }
    }
    return '';
  }

  Map<String, String> _graphqlVariantAttributeMap(
    HomeGraphqlProduct product,
    HomeGraphqlProductVariant variant,
  ) {
    final optionValueByUuid = <String, ({String key, String value})>{};
    for (final option in product.options) {
      final optionKey = _normalizeAttributeKey(option.name);
      if (optionKey.isEmpty) continue;
      for (final value in option.values) {
        final optionValueUuid = value.uuid.trim();
        final optionValue = _normalizeAttributeValue(value.value);
        if (optionValueUuid.isEmpty || optionValue.isEmpty) continue;
        optionValueByUuid[optionValueUuid] = (
          key: optionKey,
          value: optionValue,
        );
      }
    }

    final variantSelection = <String, String>{};
    for (final ref in variant.optionValues) {
      final mapped = optionValueByUuid[ref.optionValueUuid.trim()];
      if (mapped != null) {
        variantSelection[mapped.key] = mapped.value;
      }
    }
    return variantSelection;
  }

  HomeGraphqlProductVariant? _resolveColorDrivenGraphqlVariant(
    AllProductModel product,
  ) {
    final graphql = _graphqlProductDetail;
    if (graphql == null || graphql.variants.isEmpty) {
      return null;
    }

    final selectedColor = _selectedColorToken();
    if (selectedColor.isEmpty) {
      return _resolveSelectedGraphqlVariant(product);
    }

    for (final variant in graphql.variants) {
      final attributes = _graphqlVariantAttributeMap(graphql, variant);
      final variantColor = attributes.entries
          .where((entry) => _isColorAttributeKey(entry.key))
          .map((entry) => entry.value)
          .cast<String?>()
          .firstWhere((value) => value != null, orElse: () => null);
      if (variantColor == null || variantColor.isEmpty) continue;
      if (variantColor == selectedColor) {
        return variant;
      }
    }

    return _resolveSelectedGraphqlVariant(product);
  }

  HomeGraphqlProductVariant? _resolveSelectedGraphqlVariant(
    AllProductModel product,
  ) {
    final graphql = _graphqlProductDetail;
    if (graphql == null || graphql.variants.isEmpty) {
      return null;
    }

    final selectedVariantUuid = _resolveCartVariantUuid(product).trim();
    if (selectedVariantUuid.isEmpty) {
      return null;
    }

    for (final variant in graphql.variants) {
      if (variant.uuid.trim() == selectedVariantUuid) {
        return variant;
      }
    }
    return null;
  }

  List<String> _graphqlVariantImageUrls(HomeGraphqlProductVariant variant) {
    if (variant.images.isEmpty) return const <String>[];

    final sorted = [...variant.images]
      ..sort((a, b) {
        if (a.isFeatured != b.isFeatured) {
          return a.isFeatured ? -1 : 1;
        }
        return a.position.compareTo(b.position);
      });

    final urls = <String>[];
    final seen = <String>{};
    for (final image in sorted) {
      final url = image.bestUrl.trim();
      if (url.isEmpty || !seen.add(url)) continue;
      urls.add(url);
    }
    return urls;
  }

  List<String> _resolveActiveGalleryUrls(AllProductModel product) {
    final legacyUrls = _legacyImageUrls(product);
    if (legacyUrls.isNotEmpty) {
      return legacyUrls;
    }

    final selectedVariant = _resolveColorDrivenGraphqlVariant(product);
    if (selectedVariant != null) {
      final selectedVariantUrls = _graphqlVariantImageUrls(selectedVariant);
      if (selectedVariantUrls.isNotEmpty) {
        return selectedVariantUrls;
      }
    }

    final selectedVariationImage = (selectedVariation?.image ?? '').trim();
    if (selectedVariationImage.isNotEmpty) {
      return <String>[selectedVariationImage];
    }

    final graphqlFallbackImage =
        (_graphqlProductDetail?.primaryVariantImageUrl ?? '').trim();
    if (graphqlFallbackImage.isNotEmpty) {
      return <String>[graphqlFallbackImage];
    }

    return const <String>[];
  }

  String _resolveSelectedImageUrl(AllProductModel product) {
    final selectedVariant = _resolveColorDrivenGraphqlVariant(product);
    if (selectedVariant != null) {
      final selectedVariantUrls = _graphqlVariantImageUrls(selectedVariant);
      if (selectedVariantUrls.isNotEmpty) {
        return selectedVariantUrls.first;
      }
    }

    final selectedVariationImage = (selectedVariation?.image ?? '').trim();
    if (selectedVariationImage.isNotEmpty) {
      return selectedVariationImage;
    }

    return '';
  }

  void _focusSelectedVariationImage(AllProductModel product) {
    final gallery = _resolveActiveGalleryUrls(product);
    if (gallery.isEmpty) {
      return;
    }

    final preferredImage = _resolveSelectedImageUrl(product);
    var targetIndex = 0;
    if (preferredImage.isNotEmpty) {
      targetIndex = gallery.indexWhere(
        (url) => url.trim() == preferredImage.trim(),
      );
      if (targetIndex < 0) {
        targetIndex = gallery.indexWhere(
          (url) =>
              url.trim().contains(preferredImage.trim()) ||
              preferredImage.trim().contains(url.trim()),
        );
      }
      if (targetIndex < 0) {
        targetIndex = 0;
      }
    }

    if (pageController.hasClients) {
      pageController.jumpToPage(targetIndex);
    }
    context.read<ToggleProductIdImagesCubit>().toggle(targetIndex);
  }

  void _openAllSimilarProducts() {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    GoRouter.of(context).push(
      AppRouter.homeSectionDetails,
      extra: {
        'title': isArabic ? 'منتجات مشابهة' : 'Similar Products',
        'section': 'related',
        'slug': _relatedSlug,
      },
    );
  }

  void _handleBackNavigation() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    context.go('${AppRouter.selectingFromBottomNavBar}?tab=1');
  }

  void _openCommitmentsPage() {
    GoRouter.of(context).push(AppRouter.camionCommitments);
  }

  Future<void> _showShippingInfoSheet() {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
          ),
          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 22.h),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(99.r),
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isArabic ? 'الشحن' : 'Shipping',
                        style: TextStyle(
                          fontFamily: 'Montes',
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF121212),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: Icon(Icons.close_rounded, size: 22.sp),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: const Color(0xFFF7C3C8)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.flash_on_rounded,
                        color: const Color(0xFFD72631),
                        size: 16.sp,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          isArabic
                              ? 'أسرع توصيل خلال 4 أيام عمل'
                              : 'Fastest delivery in 4 business days',
                          style: TextStyle(
                            color: const Color(0xFFB4232A),
                            fontFamily: 'Montes',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FB),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFFE6EAF0)),
                  ),
                  child: Column(
                    children: [
                      _ShippingInfoRow(
                        label: isArabic ? 'وقت التوصيل' : 'Delivery time',
                        value: isArabic
                            ? 'تقريبًا 4-11 يوم عمل'
                            : '≈ 4-11 business days',
                        icon: Icons.schedule_rounded,
                      ),
                      SizedBox(height: 8.h),
                      _ShippingInfoRow(
                        label: isArabic ? 'التكلفة' : 'Costs',
                        value: isArabic ? 'مجاني' : 'FREE',
                        highlight: true,
                        icon: Icons.local_offer_outlined,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 10.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FB),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFFE6EAF0)),
                  ),
                  child: const _ShippingSpeedBars(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        bottomNavigationBar:
            BlocBuilder<ProductIdDetailsCubit, ProductIdDetailsState>(
              builder: (context, productState) {
                if (productState is! ProductIdDetailsLoaded) {
                  return const SizedBox.shrink();
                }

                return _ProductBottomCartBar(
                  product: productState.productIdDetailsModel,
                  productId: _resolveCartProductId(
                    productState.productIdDetailsModel,
                  ),
                  onOpenCart: _openCartAndHandleReturn,
                  onAddToCartSuccess: () => _showAddedToCartPreviewSheet(
                    productState.productIdDetailsModel,
                  ),
                  onBuyNow: _handleBuyNow,
                  isBuyNowLoading: _isBuyNowLoading,
                  onValidateVariation: _validateVariationSelection,
                  resolveVariantUuid: _resolveCartVariantUuid,
                  chosenAttributes: chosenAttributes,
                  chosenQuantity: chosenQuantity,
                  selectedVariation: selectedVariation,
                );
              },
            ),
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              selectedVariation = null;
              chosenAttributes.clear();
              chosenQuantity = 1;
              _graphqlProductDetail = null;
              _graphqlProductSlug = '';
              _isGraphqlProductLoading = false;
            });
            await _reloadProductDetail(forceRefresh: true);
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 558.h,
                      width: double.infinity,
                      decoration: const BoxDecoration(color: Color(0xFFF5F5F5)),
                      child: BlocBuilder<ProductIdDetailsCubit, ProductIdDetailsState>(
                        builder: (context, state) {
                          if (state is ProductIdDetailsLoading) {
                            return const Skeletonizer(
                              enabled: true,
                              child: ProductImageSkeleton(),
                            );
                          }

                          if (state is ProductIdDetailsLoaded) {
                            final product = state.productIdDetailsModel;
                            unawaited(_trackLegacyProductView(product));
                            final isArabic =
                                Localizations.localeOf(context).languageCode ==
                                'ar';
                            final activeGalleryUrls = _resolveActiveGalleryUrls(
                              product,
                            );
                            final wishlistBottomOffset =
                                activeGalleryUrls.isNotEmpty ? 112.h : 26.h;
                            final backAction = Directionality(
                              textDirection: isArabic
                                  ? TextDirection.rtl
                                  : TextDirection.ltr,
                              child: _TopImageAction(
                                assetPath: Assets.imagesProductBack,
                                backgroundColor: const Color(0x33000000),
                                flipInRtl: true,
                                onTap: _handleBackNavigation,
                              ),
                            );
                            final trailingActions = Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _TopImageAction(
                                  assetPath: 'assets/images/searchicon.png',
                                  colorFilter: const ColorFilter.mode(
                                    Colors.black,
                                    BlendMode.srcIn,
                                  ),
                                  onTap: () => openRecentSearchSheet(context),
                                ),
                                SizedBox(width: 12.w),
                                _TopImageAction(
                                  assetPath: Assets.imagesThreeDots,
                                  backgroundColor: const Color(0x33000000),
                                  onTap: _shareProduct,
                                ),
                              ],
                            );
                            return Stack(
                              children: [
                                Column(
                                  children: [
                                    Expanded(
                                      child: activeGalleryUrls.isNotEmpty
                                          ? PageView.builder(
                                              controller: pageController,
                                              itemCount:
                                                  activeGalleryUrls.length,
                                              onPageChanged: (index) {
                                                context
                                                    .read<
                                                      ToggleProductIdImagesCubit
                                                    >()
                                                    .toggle(index);
                                              },
                                              itemBuilder: (context, index) {
                                                final imageUrl =
                                                    activeGalleryUrls[index];
                                                return GestureDetector(
                                                  behavior:
                                                      HitTestBehavior.opaque,
                                                  onTap: () {
                                                    GoRouter.of(context).push(
                                                      AppRouter.fullScreenImage,
                                                      extra: {
                                                        'imageUrls':
                                                            activeGalleryUrls,
                                                        'initialIndex': index,
                                                      },
                                                    );
                                                  },
                                                  onDoubleTap: () {
                                                    GoRouter.of(context).push(
                                                      AppRouter.fullScreenImage,
                                                      extra: {
                                                        'imageUrls':
                                                            activeGalleryUrls,
                                                        'initialIndex': index,
                                                      },
                                                    );
                                                  },
                                                  child: Padding(
                                                    padding: EdgeInsets.only(
                                                      top: 56.h,
                                                      bottom: 14.h,
                                                    ),
                                                    child: Center(
                                                      child: CachedNetworkImage(
                                                        imageUrl: imageUrl,
                                                        fit: BoxFit.contain,
                                                        width: double.infinity,
                                                        height: double.infinity,
                                                        errorWidget:
                                                            (
                                                              _,
                                                              __,
                                                              ___,
                                                            ) => SizedBox.expand(
                                                              child: Image.asset(
                                                                Assets
                                                                    .imagesShoes,
                                                                fit: BoxFit
                                                                    .contain,
                                                              ),
                                                            ),
                                                        placeholder: (_, __) =>
                                                            Skeletonizer(
                                                              enabled: true,
                                                              child: SizedBox(
                                                                height: 558.h,
                                                                width: double
                                                                    .infinity,
                                                                child: Image.asset(
                                                                  Assets
                                                                      .imagesShoes,
                                                                  fit: BoxFit
                                                                      .contain,
                                                                ),
                                                              ),
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            )
                                          : Center(
                                              child: SizedBox.expand(
                                                child: Image.asset(
                                                  Assets.imagesShoes,
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            ),
                                    ),
                                    if (activeGalleryUrls.isNotEmpty)
                                      Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.fromLTRB(
                                          18.w,
                                          0,
                                          18.w,
                                          18.h,
                                        ),
                                        color: Colors.white,
                                        child:
                                            BlocBuilder<
                                              ToggleProductIdImagesCubit,
                                              ToggleProductIdImagesState
                                            >(
                                              builder: (context, toggleState) {
                                                final imageCount =
                                                    activeGalleryUrls.length;
                                                final activeIndex = toggleState
                                                    .index
                                                    .clamp(0, imageCount - 1);
                                                final visibleUrls =
                                                    activeGalleryUrls.length > 4
                                                    ? activeGalleryUrls
                                                          .take(4)
                                                          .toList(
                                                            growable: false,
                                                          )
                                                    : activeGalleryUrls;
                                                return Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    SizedBox(height: 8.h),
                                                    SizedBox(
                                                      height: 74.w,
                                                      child: ListView.separated(
                                                        scrollDirection:
                                                            Axis.horizontal,
                                                        itemCount:
                                                            visibleUrls.length,
                                                        separatorBuilder:
                                                            (_, __) => SizedBox(
                                                              width: 8.w,
                                                            ),
                                                        itemBuilder: (context, index) {
                                                          final imageUrl =
                                                              visibleUrls[index];
                                                          final realIndex =
                                                              activeGalleryUrls
                                                                  .indexWhere(
                                                                    (url) =>
                                                                        url
                                                                            .trim() ==
                                                                        imageUrl
                                                                            .trim(),
                                                                  );
                                                          final isActive =
                                                              realIndex ==
                                                              activeIndex;
                                                          return GestureDetector(
                                                            onTap: () {
                                                              context
                                                                  .read<
                                                                    ToggleProductIdImagesCubit
                                                                  >()
                                                                  .toggle(
                                                                    realIndex >=
                                                                            0
                                                                        ? realIndex
                                                                        : 0,
                                                                  );
                                                              if (pageController
                                                                  .hasClients) {
                                                                pageController
                                                                    .jumpToPage(
                                                                      realIndex >=
                                                                              0
                                                                          ? realIndex
                                                                          : 0,
                                                                    );
                                                              }
                                                            },
                                                            child: AnimatedContainer(
                                                              duration:
                                                                  const Duration(
                                                                    milliseconds:
                                                                        180,
                                                                  ),
                                                              width: 68.w,
                                                              height: 68.w,
                                                              padding:
                                                                  EdgeInsets.all(
                                                                    3.r,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color: Colors
                                                                    .white,
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12.r,
                                                                    ),
                                                                border: Border.all(
                                                                  color:
                                                                      isActive
                                                                      ? const Color(
                                                                          0xFFCB262E,
                                                                        )
                                                                      : const Color(
                                                                          0xFFE1E1E1,
                                                                        ),
                                                                  width:
                                                                      isActive
                                                                      ? 1.5
                                                                      : 1,
                                                                ),
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                    color: Colors
                                                                        .black
                                                                        .withValues(
                                                                          alpha:
                                                                              0.04,
                                                                        ),
                                                                    blurRadius:
                                                                        8,
                                                                    offset:
                                                                        const Offset(
                                                                          0,
                                                                          3,
                                                                        ),
                                                                  ),
                                                                ],
                                                              ),
                                                              child: ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      9.r,
                                                                    ),
                                                                child: CachedNetworkImage(
                                                                  imageUrl:
                                                                      imageUrl,
                                                                  fit: BoxFit
                                                                      .cover,
                                                                  errorWidget:
                                                                      (
                                                                        _,
                                                                        __,
                                                                        ___,
                                                                      ) => Image.asset(
                                                                        Assets
                                                                            .imagesShoes,
                                                                        fit: BoxFit
                                                                            .contain,
                                                                      ),
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                      ),
                                  ],
                                ),
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  child: SafeArea(
                                    bottom: false,
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        24.w,
                                        8.h,
                                        24.w,
                                        0,
                                      ),
                                      child: Directionality(
                                        textDirection: TextDirection.ltr,
                                        child: Row(
                                          children: isArabic
                                              ? [
                                                  trailingActions,
                                                  const Spacer(),
                                                  backAction,
                                                ]
                                              : [
                                                  backAction,
                                                  const Spacer(),
                                                  trailingActions,
                                                ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                Positioned(
                                  right: 24.w,
                                  bottom: wishlistBottomOffset,
                                  child: BlocBuilder<GetWishListCubit, GetWishListState>(
                                    builder: (context, wishListState) {
                                      return BlocBuilder<
                                        ProductIdDetailsCubit,
                                        ProductIdDetailsState
                                      >(
                                        builder: (context, productState) {
                                          if (productState
                                              is! ProductIdDetailsLoaded) {
                                            return Container();
                                          }

                                          final product = productState
                                              .productIdDetailsModel;
                                          final resolvedProductId =
                                              _resolveCartProductId(
                                                product,
                                              ).trim();
                                          final routeProductId = widget
                                              .productId
                                              .trim();
                                          final routeProductSlug = widget
                                              .productSlug
                                              .trim();
                                          final graphqlSlug =
                                              (_graphqlProductDetail?.slug ??
                                                      '')
                                                  .trim();
                                          bool isInWishList = false;
                                          GetWishListModel? matchedWishlistItem;

                                          if (wishListState
                                              is GetWishListSuccess) {
                                            for (final item
                                                in wishListState.wishLists) {
                                              final isMatch =
                                                  _matchesWishlistEntry(
                                                    item: item,
                                                    resolvedProductId:
                                                        resolvedProductId,
                                                    routeProductId:
                                                        routeProductId,
                                                    routeProductSlug:
                                                        routeProductSlug,
                                                    graphqlSlug: graphqlSlug,
                                                  );
                                              if (isMatch) {
                                                matchedWishlistItem = item;
                                                isInWishList = true;
                                                break;
                                              }
                                            }
                                          } else {
                                            isInWishList =
                                                product.isInwishList ?? false;
                                          }

                                          return InkWell(
                                            borderRadius: BorderRadius.circular(
                                              24.r,
                                            ),
                                            onTap: () async {
                                              if (_isWishlistBusy) {
                                                return;
                                              }
                                              setState(() {
                                                _isWishlistBusy = true;
                                              });
                                              try {
                                                final nextId = widget.productId
                                                    .trim();
                                                final nextSlug =
                                                    (_graphqlProductDetail
                                                                ?.slug ??
                                                            widget.productSlug)
                                                        .trim();
                                                final nextRoute = Uri(
                                                  path:
                                                      AppRouter.productDetails,
                                                  queryParameters: {
                                                    if (nextId.isNotEmpty)
                                                      'id': nextId,
                                                    if (nextSlug.isNotEmpty)
                                                      'slug': nextSlug,
                                                  },
                                                ).toString();
                                                final getWishListCubit = context
                                                    .read<GetWishListCubit>();
                                                final addToWishListCubit =
                                                    context
                                                        .read<
                                                          AddToWishListCubit
                                                        >();
                                                final canProceed =
                                                    await AppNavigator.ensureAuthenticatedCustomer(
                                                      context,
                                                      nextRoute: nextRoute,
                                                    );
                                                if (!canProceed) {
                                                  return;
                                                }
                                                if (!mounted) {
                                                  return;
                                                }
                                                if (isInWishList) {
                                                  final removeTargetId =
                                                      (matchedWishlistItem
                                                                  ?.id ??
                                                              '')
                                                          .trim()
                                                          .isNotEmpty
                                                      ? matchedWishlistItem!.id!
                                                            .trim()
                                                      : resolvedProductId;
                                                  await getWishListCubit
                                                      .removeFromWishList(
                                                        productId:
                                                            removeTargetId,
                                                      );

                                                  final removeState =
                                                      getWishListCubit.state;
                                                  if (removeState
                                                      is RemoveWishListSuccess) {
                                                    AppToast.show(
                                                      gravity: ToastGravity.TOP,
                                                      msg:
                                                          'Removed from wishlist',
                                                    );
                                                  }

                                                  getWishListCubit
                                                      .getWishList();
                                                  WishListScreen
                                                      .wishListKey
                                                      .currentState
                                                      ?.refreshGetWishList();
                                                } else {
                                                  final selectedVariantUuid =
                                                      _resolveCartVariantUuid(
                                                        product,
                                                      ).trim();
                                                  await addToWishListCubit.addtoWishList(
                                                    productId:
                                                        resolvedProductId,
                                                    variantUuid:
                                                        selectedVariantUuid
                                                            .isEmpty
                                                        ? null
                                                        : selectedVariantUuid,
                                                    title: product.name,
                                                    price: product.prices.price,
                                                    image:
                                                        (selectedVariation
                                                                    ?.image ??
                                                                '')
                                                            .trim()
                                                            .isNotEmpty
                                                        ? selectedVariation!
                                                              .image!
                                                        : (_graphqlProductDetail
                                                                      ?.primaryVariantImageUrl ??
                                                                  '')
                                                              .trim()
                                                              .isNotEmpty
                                                        ? _graphqlProductDetail!
                                                              .primaryVariantImageUrl
                                                        : (product
                                                                  .images
                                                                  .isNotEmpty
                                                              ? product
                                                                    .images[0]
                                                                    .thumbnail
                                                              : ''),
                                                  );

                                                  final addState =
                                                      addToWishListCubit.state;
                                                  if (addState
                                                          is WishListError &&
                                                      addState
                                                              .error
                                                              .statusCode ==
                                                          409) {
                                                    await getWishListCubit
                                                        .removeFromWishList(
                                                          productId:
                                                              resolvedProductId,
                                                        );
                                                    final removeState =
                                                        getWishListCubit.state;
                                                    if (removeState
                                                        is RemoveWishListSuccess) {
                                                      AppToast.show(
                                                        gravity:
                                                            ToastGravity.TOP,
                                                        msg:
                                                            'Removed from wishlist',
                                                      );
                                                    }
                                                  } else if (addState
                                                      is WishListSuccess) {
                                                    AppToast.show(
                                                      gravity: ToastGravity.TOP,
                                                      msg: 'Added to wishlist',
                                                    );
                                                  }

                                                  getWishListCubit
                                                      .getWishList();
                                                  WishListScreen
                                                      .wishListKey
                                                      .currentState
                                                      ?.refreshGetWishList();
                                                }
                                              } finally {
                                                if (mounted) {
                                                  setState(() {
                                                    _isWishlistBusy = false;
                                                  });
                                                }
                                              }
                                            },
                                            child: Container(
                                              width: 48.w,
                                              height: 48.w,
                                              decoration: BoxDecoration(
                                                color: isInWishList
                                                    ? Colors.white
                                                    : const Color(0xE6FFFFFF),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isInWishList
                                                      ? const Color(0xFFCB262E)
                                                      : const Color(0xFFE5E7EB),
                                                  width: 1,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(
                                                          alpha: 0.14,
                                                        ),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Center(
                                                child: _isWishlistBusy
                                                    ? SizedBox(
                                                        width: 18.w,
                                                        height: 18.w,
                                                        child:
                                                            const CircularProgressIndicator(
                                                              color: Color(
                                                                0xFFCB262E,
                                                              ),
                                                              strokeWidth: 2,
                                                            ),
                                                      )
                                                    : isInWishList
                                                    ? SvgPicture.asset(
                                                        Assets
                                                            .imagesIconsNewwwActiveHeart,
                                                        width: 28.w,
                                                        height: 28.h,
                                                      )
                                                    : Image.asset(
                                                        Assets
                                                            .imagesIconsWishlistOutlineHeart,
                                                        width: 34.w,
                                                        height: 34.h,
                                                        fit: BoxFit.contain,
                                                      ),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          }

                          if (state is ProductIdDetailsError) {
                            if (_isConnectivityErrorStatus(
                              state.error.statusCode,
                            )) {
                              return const SizedBox.shrink();
                            }
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    state.error.icon,
                                    color: Colors.red,
                                    size: 50,
                                  ),

                                  SizedBox(height: 20.h),
                                  Text(
                                    state.error.message,
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      color: Colors.red,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),

                                  SizedBox(height: 10.h),

                                  ElevatedButton(
                                    onPressed: () {
                                      _reloadProductDetail(forceRefresh: true);
                                    },
                                    child: Text(
                                      S.of(context).retry,
                                      style: TextStyle(fontSize: 16.sp),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return Container();
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    BlocBuilder<ProductIdDetailsCubit, ProductIdDetailsState>(
                      builder: (context, campaignState) {
                        if (campaignState is! ProductIdDetailsLoaded ||
                            campaignState
                                    .productIdDetailsModel
                                    .campaign
                                    ?.finishesAt ==
                                null) {
                          return const SizedBox.shrink();
                        }

                        return Column(
                          children: [
                            _ProductCampaignBanner(
                              campaign:
                                  campaignState.productIdDetailsModel.campaign!,
                            ),
                            SizedBox(height: 14.h),
                          ],
                        );
                      },
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Column(
                        children: [
                          BlocBuilder<
                            ProductIdDetailsCubit,
                            ProductIdDetailsState
                          >(
                            builder: (context, state) {
                              if (state is ProductIdDetailsLoading) {
                                return const Skeletonizer(
                                  enabled: true,
                                  child: ProductInfoSkeleton(),
                                );
                              }
                              if (state is ProductIdDetailsLoaded) {
                                final product = state.productIdDetailsModel;
                                final categoryName =
                                    _resolveProductCategoryName(product);
                                final effectiveVariations =
                                    _effectiveProductVariations(product);
                                final displayData = _getDisplayData(product);
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (categoryName.trim().isNotEmpty) ...[
                                      Text(
                                        categoryName,
                                        style: TextStyle(
                                          color: AppColors.black.withValues(
                                            alpha: 0.8,
                                          ),
                                          fontSize: 12.sp,
                                          fontFamily: 'Montes',
                                          fontWeight: FontWeight.w400,
                                          height: 18 / 12,
                                        ),
                                      ),
                                      SizedBox(height: 6.h),
                                    ],

                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _resolveProductTitle(product),
                                            style: TextStyle(
                                              color: AppColors.black,
                                              fontSize: 16.sp,
                                              fontFamily: 'Montes',
                                              fontWeight: FontWeight.w500,
                                              height: 24 / 16,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 16.w),
                                        _ProductPriceLabel(
                                          price: displayData['price']
                                              .toString(),
                                          regularPrice:
                                              displayData['regularPrice']
                                                  .toString(),
                                          currencyCode: _activeCurrencyCode(
                                            context.watch<CurrencyCubit>(),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8.h),

                                    Row(
                                      children: [
                                        Text(
                                          product.reviewCount > 0
                                              ? formatLocalizedNumber(
                                                  context,
                                                  product.averageRating,
                                                  fractionDigits: 1,
                                                )
                                              : formatLocalizedNumber(
                                                  context,
                                                  0,
                                                ),
                                          style: TextStyle(
                                            color: AppColors.black,
                                            fontSize: 12.sp,
                                            fontFamily: 'Montes',
                                            fontWeight: FontWeight.w400,
                                            height: 18 / 12,
                                          ),
                                        ),
                                        SizedBox(width: 5.w),
                                        ...List.generate(5, (index) {
                                          int rating = 0;
                                          if (product.reviewCount > 0) {
                                            try {
                                              rating = double.parse(
                                                product.averageRating,
                                              ).round();
                                            } catch (e) {
                                              rating = 0;
                                            }
                                          }
                                          return Icon(
                                            index < rating
                                                ? Icons.star
                                                : Icons.star_border,
                                            color: const Color(0xFFF7C95F),
                                            size: 14.r,
                                          );
                                        }),
                                        SizedBox(width: 8.w),
                                        Text(
                                          '·  ${formatLocalizedNumber(context, product.reviewCount)} ${S.of(context).reviews}',
                                          style: TextStyle(
                                            color: AppColors.black,
                                            fontSize: 12.sp,
                                            fontFamily: 'Montes',
                                            fontWeight: FontWeight.w400,
                                            height: 18 / 12,
                                          ),
                                        ),
                                      ],
                                    ),

                                    Row(
                                      children: [
                                        Icon(
                                          Icons.favorite,
                                          color: AppColors.primaryColor,
                                          size: 14.sp,
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          formatLocalizedNumber(
                                            context,
                                            product.likesCount,
                                          ),
                                          style: TextStyle(
                                            color: AppColors.black,
                                            fontSize: 12.sp,
                                            fontFamily: 'Montes',
                                            fontWeight: FontWeight.w400,
                                            height: 12 / 12,
                                          ),
                                        ),
                                        SizedBox(width: 6.w),
                                        Text(
                                          '•',
                                          style: TextStyle(
                                            color: AppColors.black,
                                            fontSize: 12.sp,
                                            fontFamily: 'Montes',
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        SizedBox(width: 6.w),
                                        Text(
                                          S.of(context).favorites,
                                          style: TextStyle(
                                            color: AppColors.black,
                                            fontSize: 12.sp,
                                            fontFamily: 'Montes',
                                            fontWeight: FontWeight.w600,
                                            height: 12 / 12,
                                          ),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 16.h),

                                    _StockStatusBadge(
                                      isInStock:
                                          (displayData['isInStock'] as bool?) ??
                                          false,
                                      stockQuantity:
                                          (displayData['stockQuantity']
                                              as int?) ??
                                          0,
                                    ),

                                    const SizedBox(height: 20),

                                    ProductsSelectionOptions(
                                      key: ValueKey(
                                        'selection-$_selectionVersion',
                                      ),
                                      variations: effectiveVariations,
                                      initialSelectedAttributes:
                                          chosenAttributes,
                                      initialQuantity: chosenQuantity,
                                      onSelectionChanged:
                                          (
                                            attributes,
                                            quantity,
                                            matchedVariation,
                                          ) {
                                            setState(() {
                                              chosenAttributes = attributes;
                                              chosenQuantity = quantity;
                                              selectedVariation =
                                                  matchedVariation;
                                            });
                                            _focusSelectedVariationImage(
                                              product,
                                            );
                                          },
                                    ),

                                    SizedBox(height: 20.h),

                                    if ((_graphqlProductDetail?.sizechartUrl ??
                                            '')
                                        .trim()
                                        .isNotEmpty) ...[
                                      _SizeGuideSection(
                                        imageUrl: _graphqlProductDetail!
                                            .sizechartUrl
                                            .trim(),
                                      ),
                                      SizedBox(height: 16.h),
                                    ],

                                    _ShippingQuickCard(
                                      onTap: _showShippingInfoSheet,
                                    ),

                                    SizedBox(height: 12.h),

                                    _CamionCommitmentsQuickCard(
                                      onTap: _openCommitmentsPage,
                                    ),

                                    SizedBox(height: 16.h),

                                    _DescriptionSection(
                                      title: S.of(context).description,
                                      content: _resolveProductDescription(
                                        product,
                                      ),
                                    ),

                                    if ((_graphqlProductDetail?.attachments ??
                                            const [])
                                        .isNotEmpty) ...[
                                      SizedBox(height: 18.h),
                                      _ProductAttachmentsSection(
                                        attachments:
                                            _graphqlProductDetail!.attachments,
                                      ),
                                    ],

                                    SizedBox(height: 20.h),

                                    _ReviewsSectionContent(
                                      averageRating:
                                          double.tryParse(
                                            product.averageRating,
                                          ) ??
                                          0,
                                      reviewCount: product.reviewCount,
                                      reviews: _graphqlReviews,
                                      currentCustomerUuid: _currentCustomerUuid,
                                      onEditReview: _openEditReviewComposer,
                                      onDeleteReview: _confirmAndDeleteReview,
                                    ),

                                    SizedBox(height: 30.h),

                                    Builder(
                                      builder: (context) {
                                        if (_isRelatedLoading) {
                                          return const Skeletonizer(
                                            enabled: true,
                                            child:
                                                _SimilarProductsSectionSkeleton(),
                                          );
                                        }

                                        return _SimilarProductsSection(
                                          products: _relatedProducts,
                                          isGridView:
                                              _isSimilarProductsGridView,
                                          onToggleGridView: (isGridView) {
                                            setState(() {
                                              _isSimilarProductsGridView =
                                                  isGridView;
                                            });
                                          },
                                          onMoreTap: _openAllSimilarProducts,
                                        );
                                      },
                                    ),

                                    SizedBox(height: 12.h),

                                    // const CustomExpansionTile(
                                    //   title: "طريقة الاستعمال",
                                    //   content:
                                    //       "هذه حقيقة مثبتة لا يمكن تغييرها هذه حقيقة مثبتة لا يمكن تغييرها هذه حقيقة مثبتة لا يمكن تغييرها هذه حقيقة مثبتة لا يمكن تغييرها هذه حقيقة مثبتة هذه حقيقة مثبتة لا يمكن تغييرها هذه حقيقة مثبتة لا يمكن تغييرها هذه حقيقة مثبتة لا يمكن تغييرها هذه حقيقة مثبتة لا يمكن تغييرها هذه حقيقة مثبتة",
                                    // ),

                                    // SizedBox(height: 20.h),

                                    // Image.asset(
                                    //   Assets.imagesProductRate,

                                    //   // width: double.infinity,
                                    //   // height: 120.h,
                                    // ),
                                  ],
                                );
                              }

                              if (state is ProductIdDetailsError) {
                                if (_isConnectivityErrorStatus(
                                  state.error.statusCode,
                                )) {
                                  return const SizedBox.shrink();
                                }
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(
                                        state.error.icon,
                                        color: Colors.red,
                                        size: 50,
                                      ),

                                      SizedBox(height: 20.h),
                                      Text(
                                        state.error.message,
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          color: Colors.red,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),

                                      SizedBox(height: 10.h),

                                      ElevatedButton(
                                        onPressed: () {
                                          _reloadProductDetail(
                                            forceRefresh: true,
                                          );
                                        },
                                        child: Text(
                                          S.of(context).retry,
                                          style: TextStyle(fontSize: 16.sp),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return Container();
                            },
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20.h),
                  ],
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height:
                      88.h +
                      MediaQuery.of(context).viewInsets.bottom +
                      MediaQuery.of(context).padding.bottom +
                      20.h,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopImageAction extends StatelessWidget {
  const _TopImageAction({
    required this.assetPath,
    required this.onTap,
    this.colorFilter,
    this.backgroundColor,
    this.flipInRtl = false,
  });

  final String assetPath;
  final VoidCallback onTap;
  final ColorFilter? colorFilter;
  final Color? backgroundColor;
  final bool flipInRtl;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final shouldFlip = flipInRtl && isRtl;
    final isSvg = assetPath.toLowerCase().endsWith('.svg');
    final image = isSvg
        ? SvgPicture.asset(
            assetPath,
            width: 40.w,
            height: 40.h,
            fit: BoxFit.contain,
            colorFilter: colorFilter,
          )
        : colorFilter == null
        ? Image.asset(assetPath, width: 40.w, height: 40.h, fit: BoxFit.contain)
        : ColorFiltered(
            colorFilter: colorFilter!,
            child: Image.asset(
              assetPath,
              width: 40.w,
              height: 40.h,
              fit: BoxFit.contain,
            ),
          );
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 40.w,
        height: 40.w,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: shouldFlip
                ? Transform.flip(flipX: true, child: image)
                : image,
          ),
        ),
      ),
    );
  }
}

class _ProductPriceLabel extends StatelessWidget {
  const _ProductPriceLabel({
    required this.price,
    required this.regularPrice,
    required this.currencyCode,
  });

  final String price;
  final String regularPrice;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final parsedCurrent = double.tryParse(price) ?? 0;
    if (parsedCurrent <= 0) {
      return const SizedBox.shrink();
    }
    final current = parsedCurrent.toStringAsFixed(2);
    final parsedRegular = double.tryParse(regularPrice) ?? 0;
    final regular = parsedRegular.toStringAsFixed(2);
    final hasDiscount =
        parsedRegular > 0 && parsedCurrent > 0 && regular != current;
    final discountPercentage = hasDiscount
        ? (((parsedRegular - parsedCurrent) / parsedRegular) * 100).round()
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (discountPercentage > 0) ...[
          DiscountPercentageBadge(percentage: discountPercentage),
          SizedBox(height: 6.h),
        ],
        if (hasDiscount)
          FormattedPriceText(
            amountText: regular,
            currencyText: '',
            textAlign: TextAlign.right,
            mainStyle: TextStyle(
              color: AppColors.gray,
              fontSize: 12.sp,
              fontFamily: 'Montes',
              fontWeight: FontWeight.w400,
              height: 16 / 12,
              decoration: TextDecoration.lineThrough,
            ),
            minorStyle: TextStyle(
              color: AppColors.gray,
              fontSize: 8.sp,
              fontFamily: 'Montes',
              fontWeight: FontWeight.w400,
              height: 1,
              decoration: TextDecoration.lineThrough,
            ),
            spaceBeforeCurrency: false,
          ),
        FormattedPriceText(
          amountText: current,
          currencyText: currencyCode,
          textAlign: TextAlign.right,
          mainStyle: TextStyle(
            color: AppColors.black,
            fontSize: 20.sp,
            fontFamily: 'Montes',
            fontWeight: FontWeight.w500,
            height: 24 / 20,
          ),
          minorStyle: TextStyle(
            color: AppColors.black,
            fontSize: 8.sp,
            fontFamily: 'Montes',
            fontWeight: FontWeight.w600,
            height: 1,
          ),
          spaceBeforeCurrency: true,
        ),
      ],
    );
  }
}

class _ProductCampaignBanner extends StatefulWidget {
  const _ProductCampaignBanner({required this.campaign});

  final AllProductCampaign campaign;

  @override
  State<_ProductCampaignBanner> createState() => _ProductCampaignBannerState();
}

class _ProductCampaignBannerState extends State<_ProductCampaignBanner> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  static const List<Color> _campaignRedGradient = [
    Color(0xFF4D0A0F),
    Color(0xFF8E111A),
    Color(0xFFCB262E),
  ];

  @override
  void initState() {
    super.initState();
    _syncRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(_syncRemaining);
    });
  }

  @override
  void didUpdateWidget(covariant _ProductCampaignBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.campaign.finishesAt != widget.campaign.finishesAt) {
      _syncRemaining();
    }
  }

  void _syncRemaining() {
    final endsAt = widget.campaign.finishesAt;
    if (endsAt == null) {
      _remaining = Duration.zero;
      return;
    }
    final diff = endsAt.toLocal().difference(DateTime.now());
    _remaining = diff.isNegative ? Duration.zero : diff;
  }

  String _formatRemaining(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    if (_remaining == Duration.zero) {
      return isArabic ? 'انتهت الحملة' : 'Campaign ended';
    }
    final hours = _remaining.inHours;
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);
    final parts = <String>[
      '${hours.toString().padLeft(2, '0')}h',
      '${minutes.toString().padLeft(2, '0')}m',
      '${seconds.toString().padLeft(2, '0')}s',
    ];
    return parts.join(' : ');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final title = widget.campaign.name.trim().isNotEmpty
        ? widget.campaign.name.trim()
        : (isArabic ? 'حملة خاصة' : 'Special campaign');

    if (_remaining == Duration.zero) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 12.w),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        gradient: const LinearGradient(
          colors: _campaignRedGradient,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x337A1016),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18.w,
            top: -18.h,
            child: Container(
              width: 92.w,
              height: 92.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 46.w,
                height: 46.w,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999.r),
                      ),
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontFamily: 'Montes',
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      isArabic
                          ? 'الحملة النشطة الآن مع عدّ تنازلي مباشر.'
                          : 'The active campaign is live with a real-time countdown.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 12.sp,
                        fontFamily: 'Montes',
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isArabic ? 'ينتهي خلال' : 'Ends in',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 9.sp,
                      fontFamily: 'Montes',
                      fontWeight: FontWeight.w500,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        color: Colors.white,
                        size: 13.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        _formatRemaining(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.sp,
                          fontFamily: 'Montes',
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DescriptionSection extends StatefulWidget {
  const _DescriptionSection({required this.title, required this.content});

  final String title;
  final String content;

  @override
  State<_DescriptionSection> createState() => _DescriptionSectionState();
}

class _DescriptionSectionState extends State<_DescriptionSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final normalized = widget.content.trim();
    final shouldCollapse = normalized.length > 180;
    final displayText = shouldCollapse && !_expanded
        ? '${normalized.substring(0, 180).trim()}...'
        : normalized;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: TextStyle(
            color: AppColors.black,
            fontSize: 14.sp,
            fontFamily: 'Montes',
            fontWeight: FontWeight.w500,
            height: 24 / 14,
          ),
        ),
        SizedBox(height: 10.h),
        RichText(
          text: TextSpan(
            style: TextStyle(
              color: AppColors.black,
              fontSize: 10.sp,
              fontFamily: 'Montes',
              fontWeight: FontWeight.w400,
              height: 18 / 10,
            ),
            children: [
              TextSpan(text: displayText),
              if (shouldCollapse)
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(start: 4.w),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6.r),
                        onTap: () => setState(() => _expanded = !_expanded),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 6.h,
                          ),
                          child: Text(
                            Localizations.localeOf(context).languageCode == 'ar'
                                ? (_expanded ? 'أقل' : 'المزيد')
                                : (_expanded ? 'Less' : 'More'),
                            style: TextStyle(
                              color: AppColors.black,
                              fontSize: 11.sp,
                              fontFamily: 'Montes',
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductAttachmentsSection extends StatelessWidget {
  const _ProductAttachmentsSection({required this.attachments});

  final List<HomeGraphqlProductAttachment> attachments;

  @override
  Widget build(BuildContext context) {
    final visibleAttachments = attachments
        .where((attachment) => attachment.mediaUrl.trim().isNotEmpty)
        .toList(growable: false);
    if (visibleAttachments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...List.generate(visibleAttachments.length, (index) {
          final attachment = visibleAttachments[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == visibleAttachments.length - 1 ? 0 : 10.h,
            ),
            child: _ProductAttachmentTile(attachment: attachment),
          );
        }),
      ],
    );
  }
}

class _ProductAttachmentTile extends StatelessWidget {
  const _ProductAttachmentTile({required this.attachment});

  final HomeGraphqlProductAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final mediaUrl = attachment.mediaUrl.trim();
    if (attachment.isVideo) {
      return AspectRatio(
        aspectRatio: 1,
        child: Container(
          width: double.infinity,
          color: const Color(0xFFF2F2F2),
          child: Center(
            child: Container(
              width: 54.w,
              height: 54.w,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 36.sp,
              ),
            ),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1,
      child: CachedNetworkImage(
        imageUrl: mediaUrl,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          color: const Color(0xFFF2F2F2),
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          color: const Color(0xFFF2F2F2),
          child: Icon(
            Icons.broken_image_outlined,
            color: Colors.grey[500],
            size: 34.sp,
          ),
        ),
      ),
    );
  }
}

class _ShippingQuickCard extends StatefulWidget {
  const _ShippingQuickCard({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_ShippingQuickCard> createState() => _ShippingQuickCardState();
}

class _ShippingQuickCardState extends State<_ShippingQuickCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: InkWell(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        borderRadius: BorderRadius.circular(14.r),
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: _pressed
                  ? const Color(0xFFFFC4C8)
                  : const Color(0xFFE6EAF0),
            ),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD72631).withValues(alpha: 0.08),
                blurRadius: _pressed ? 8 : 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38.w,
                height: 38.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(11.r),
                ),
                child: Icon(
                  Icons.local_shipping_outlined,
                  color: const Color(0xFFD72631),
                  size: 19.sp,
                ),
              ),
              SizedBox(width: 11.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 6.h,
                      children: [
                        _ShippingMiniPill(
                          icon: Icons.local_shipping_rounded,
                          text: isArabic ? 'شحن مجاني' : 'Free shipping',
                          textColor: const Color(0xFF0E9F6E),
                          backgroundColor: const Color(0xFFEAFBF3),
                        ),
                        _ShippingMiniPill(
                          icon: Icons.bolt_rounded,
                          text: isArabic
                              ? 'أسرع توصيل: 4 أيام'
                              : 'Fastest delivery: 4 days',
                          textColor: const Color(0xFF166534),
                          backgroundColor: const Color(0xFFEFFDF4),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Text(
                          isArabic ? 'الشحن' : 'Shipping',
                          style: TextStyle(
                            fontFamily: 'Montes',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                            height: 1.05,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 7.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(999.r),
                          ),
                          child: Text(
                            isArabic ? 'سريع' : 'Fast',
                            style: TextStyle(
                              fontFamily: 'Montes',
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFB4232A),
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      isArabic
                          ? 'أسرع توصيل خلال 4 أيام عمل'
                          : 'Fastest delivery in 4 business days',
                      style: TextStyle(
                        fontFamily: 'Montes',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475467),
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isArabic
                              ? 'اضغط لمزيد من التفاصيل'
                              : 'Tap for details',
                          style: TextStyle(
                            fontFamily: 'Montes',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFD72631),
                            decoration: TextDecoration.underline,
                            decorationColor: const Color(0xFFD72631),
                            decorationThickness: 1.6,
                            letterSpacing: 0.1,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Icon(
                          Icons.touch_app_rounded,
                          size: 13.sp,
                          color: const Color(0xFFD72631),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: const Color(0xFFD72631),
                size: 22.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShippingMiniPill extends StatelessWidget {
  const _ShippingMiniPill({
    required this.icon,
    required this.text,
    required this.textColor,
    required this.backgroundColor,
  });

  final IconData icon;
  final String text;
  final Color textColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.sp, color: textColor),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Montes',
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: textColor,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _CamionCommitmentsQuickCard extends StatelessWidget {
  const _CamionCommitmentsQuickCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Ink(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(10.w, 11.h, 10.w, 12.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: const Color(0xFFEDEDED)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 20.sp,
                    color: const Color(0xFF43C978),
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      isArabic ? 'التزامات كميون' : "Camion's commitments",
                      style: TextStyle(
                        fontFamily: 'Montes',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF43C978),
                        height: 1.2,
                      ),
                    ),
                  ),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Icon(
                      isArabic
                          ? Icons.chevron_left_rounded
                          : Icons.chevron_right_rounded,
                      color: const Color(0xFF43C978),
                      size: 22.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 11.h),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _CommitmentsSummaryPanel(
                        title: isArabic ? 'المدفوعات الآمنة' : 'Safe payments',
                        items: isArabic
                            ? ['الدفع الآمن', 'حماية الخصوصية']
                            : ['Secure payment', 'Privacy protection'],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: _CommitmentsSummaryPanel(
                        title: isArabic ? 'توصيل آمن' : 'Safe delivery',
                        items: isArabic
                            ? [
                                'استرداد للمنتج المفقود',
                                'استرداد للمنتج التالف',
                              ]
                            : [
                                'Refund for lost product',
                                'Refund for damage product',
                              ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommitmentsSummaryPanel extends StatelessWidget {
  const _CommitmentsSummaryPanel({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 88.h),
      padding: EdgeInsets.fromLTRB(11.w, 10.h, 9.w, 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F8),
        borderRadius: BorderRadius.circular(5.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Montes',
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF43C978),
              height: 1.15,
            ),
          ),
          SizedBox(height: 8.h),
          ...items.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 5.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 1.h),
                    child: Icon(
                      Icons.check_rounded,
                      size: 14.sp,
                      color: const Color(0xFF43C978),
                    ),
                  ),
                  SizedBox(width: 5.w),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontFamily: 'Montes',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF555555),
                        height: 1.18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShippingInfoRow extends StatelessWidget {
  const _ShippingInfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFE8ECF2)),
      ),
      child: Row(
        children: [
          Container(
            width: 28.w,
            height: 28.w,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: const Color(0xFF6B7280), size: 16.sp),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Montes',
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF4B5563),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Montes',
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: highlight
                  ? const Color(0xFF0E9F6E)
                  : const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShippingSpeedBars extends StatelessWidget {
  const _ShippingSpeedBars();

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final rows = <(String, double, String)>[
      (isArabic ? '≤ 4 أيام عمل' : '≤ 4 business days', 0.10, '5.0%'),
      (isArabic ? '5 أيام عمل' : '5 business days', 0.16, '6.0%'),
      (isArabic ? '6 أيام عمل' : '6 business days', 0.20, '7.0%'),
      (isArabic ? '7 أيام عمل' : '7 business days', 0.28, '8.0%'),
      (isArabic ? '8 أيام عمل' : '8 business days', 0.34, '9.0%'),
      (isArabic ? '9 أيام عمل' : '9 business days', 0.42, '10.0%'),
      (isArabic ? '10 أيام عمل' : '10 business days', 0.50, '11.0%'),
      (isArabic ? '11 أيام عمل' : '11 business days', 0.64, '12.0%'),
      (isArabic ? '> 11 أيام عمل' : '> 11 business days', 0.92, '42.0%'),
    ];

    return Column(
      children: rows
          .map(
            (row) => Padding(
              padding: EdgeInsets.only(bottom: 11.h),
              child: Row(
                children: [
                  SizedBox(
                    width: 130.w,
                    child: Text(
                      row.$1,
                      style: TextStyle(
                        fontFamily: 'Montes',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: row.$2),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(99.r),
                          child: LinearProgressIndicator(
                            value: value,
                            minHeight: 7.h,
                            backgroundColor: const Color(0xFFE5E7EB),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFC93B2B),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 12.w),
                  SizedBox(
                    width: 48.w,
                    child: Text(
                      row.$3,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'Montes',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _ProductDetailAccordion extends StatefulWidget {
  const _ProductDetailAccordion({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  State<_ProductDetailAccordion> createState() =>
      _ProductDetailAccordionState();
}

class _ProductDetailAccordionState extends State<_ProductDetailAccordion> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            width: double.infinity,
            height: 40.h,
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(5.r),
              border: Border.all(color: AppColors.borderGray),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 14.sp,
                      fontFamily: 'Montes',
                      fontWeight: FontWeight.w500,
                      height: 24 / 14,
                    ),
                  ),
                ),
                SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: Center(
                    child: Text(
                      _expanded ? '−' : '+',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 22.sp,
                        fontFamily: 'Montes',
                        fontWeight: FontWeight.w400,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded) SizedBox(height: 12.h),
        if (_expanded) widget.child,
      ],
    );
  }
}

enum _ReviewListFilter { all, withMedia, withDescription }

class _ReviewsSectionContent extends StatefulWidget {
  const _ReviewsSectionContent({
    required this.averageRating,
    required this.reviewCount,
    required this.reviews,
    required this.currentCustomerUuid,
    required this.onEditReview,
    required this.onDeleteReview,
  });

  final double averageRating;
  final int reviewCount;
  final List<ReviewModel> reviews;
  final String currentCustomerUuid;
  final ValueChanged<ReviewModel> onEditReview;
  final ValueChanged<ReviewModel> onDeleteReview;

  @override
  State<_ReviewsSectionContent> createState() => _ReviewsSectionContentState();
}

class _ReviewsSectionContentState extends State<_ReviewsSectionContent> {
  _ReviewListFilter _selectedFilter = _ReviewListFilter.all;

  String _stripReviewText(String value) {
    return value
        .replaceAll(
          RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false),
          '',
        )
        .trim();
  }

  bool _hasReviewMedia(ReviewModel review) {
    return review.images.any(
      (image) =>
          image.thumbnailUrl.trim().isNotEmpty ||
          image.imageUrl.trim().isNotEmpty,
    );
  }

  List<ReviewModel> _filteredReviews(List<ReviewModel> reviews) {
    switch (_selectedFilter) {
      case _ReviewListFilter.all:
        return reviews;
      case _ReviewListFilter.withMedia:
        return reviews.where(_hasReviewMedia).toList(growable: false);
      case _ReviewListFilter.withDescription:
        return reviews
            .where(
              (review) =>
                  _stripReviewText(review.review).isNotEmpty &&
                  !_hasReviewMedia(review),
            )
            .toList(growable: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviews = widget.reviews;
    final counts = List<int>.generate(
      5,
      (index) => reviews.where((review) => review.rating == 5 - index).length,
    );
    final total = reviews.isEmpty ? 1 : reviews.length;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? 'التقييمات والمراجعات' : 'Rating & Reviews',
          style: TextStyle(
            color: AppColors.black,
            fontSize: 14.sp,
            fontFamily: 'Montes',
            fontWeight: FontWeight.w500,
            height: 24 / 14,
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5.r),
            border: Border.all(
              color: const Color(0xFFD7D7D7),
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 72.w,
                    height: 72.w,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: (widget.averageRating / 5).clamp(0, 1),
                          strokeWidth: 6,
                          backgroundColor: const Color(0xFFE8EDF3),
                          color: const Color(0xFFCB262E),
                        ),
                        Center(
                          child: Text(
                            widget.averageRating.toStringAsFixed(1),
                            style: TextStyle(
                              color: AppColors.black,
                              fontSize: 16.sp,
                              fontFamily: 'Montes',
                              fontWeight: FontWeight.w600,
                              height: 24 / 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 18.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isArabic
                              ? '${widget.averageRating.toStringAsFixed(1)} من 5.0'
                              : '${widget.averageRating.toStringAsFixed(1)} out of 5.0',
                          style: TextStyle(
                            color: AppColors.black,
                            fontSize: 12.sp,
                            fontFamily: 'Montes',
                            fontWeight: FontWeight.w600,
                            height: 18 / 12,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          isArabic
                              ? 'بناءً على ${formatLocalizedNumber(context, widget.reviewCount)} مراجعة'
                              : 'Based on ${formatLocalizedNumber(context, widget.reviewCount)} reviews',
                          style: TextStyle(
                            color: AppColors.midGray,
                            fontSize: 11.sp,
                            fontFamily: 'Montes',
                            fontWeight: FontWeight.w400,
                            height: 16 / 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18.h),
              ...List.generate(5, (index) {
                final starValue = 5 - index;
                final count = counts[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: index == 4 ? 0 : 10.h),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 42.w,
                        child: Text(
                          '$starValue.0',
                          style: TextStyle(
                            color: AppColors.black,
                            fontSize: 12.sp,
                            fontFamily: 'Montes',
                            fontWeight: FontWeight.w400,
                            height: 18 / 12,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.star,
                        color: const Color(0xFFF7C95F),
                        size: 18.sp,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99.r),
                          child: LinearProgressIndicator(
                            minHeight: 8.h,
                            value: count / total,
                            backgroundColor: const Color(0xFFE8EDF3),
                            color: const Color(0xFFCB262E),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      SizedBox(
                        width: 30.w,
                        child: Text(
                          '$count',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: AppColors.black,
                            fontSize: 12.sp,
                            fontFamily: 'Montes',
                            fontWeight: FontWeight.w400,
                            height: 18 / 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        SizedBox(height: 18.h),
        Text(
          isArabic ? 'قوائم المراجعات' : 'Review Lists',
          style: TextStyle(
            color: AppColors.black,
            fontSize: 14.sp,
            fontFamily: 'Montes',
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            _ReviewFilterChip(
              label: isArabic ? 'كل المراجعات' : 'All Reviews',
              active: _selectedFilter == _ReviewListFilter.all,
              onTap: () {
                setState(() {
                  _selectedFilter = _ReviewListFilter.all;
                });
              },
            ),
            _ReviewFilterChip(
              label: isArabic ? 'مع الصور' : 'With Photos',
              active: _selectedFilter == _ReviewListFilter.withMedia,
              onTap: () {
                setState(() {
                  _selectedFilter = _ReviewListFilter.withMedia;
                });
              },
            ),
            _ReviewFilterChip(
              label: isArabic ? 'مع الوصف' : 'With Description',
              active: _selectedFilter == _ReviewListFilter.withDescription,
              onTap: () {
                setState(() {
                  _selectedFilter = _ReviewListFilter.withDescription;
                });
              },
            ),
          ],
        ),
        SizedBox(height: 12.h),
        ..._filteredReviews(reviews).map((review) {
          final isMine =
              widget.currentCustomerUuid.trim().isNotEmpty &&
              review.customerId.trim() == widget.currentCustomerUuid.trim();
          return Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: _ReviewListItem(
              review: review,
              isMine: isMine,
              onEdit: isMine ? widget.onEditReview : null,
              onDelete: isMine ? widget.onDeleteReview : null,
            ),
          );
        }),
        if (_filteredReviews(reviews).isEmpty)
          Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Text(
              isArabic
                  ? 'لا توجد مراجعات لهذا الفلتر.'
                  : 'No reviews found for this filter.',
              style: TextStyle(
                color: AppColors.midGray,
                fontSize: 11.sp,
                fontFamily: 'Montes',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }
}

class _ReviewFilterChip extends StatelessWidget {
  const _ReviewFilterChip({
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryColor : AppColors.white,
          borderRadius: BorderRadius.circular(5.r),
          border: Border.all(
            color: active ? AppColors.primaryColor : AppColors.borderGray,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.white : AppColors.black,
            fontSize: 10.sp,
            fontFamily: 'Montes',
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

class _ReviewListItem extends StatelessWidget {
  const _ReviewListItem({
    required this.review,
    required this.isMine,
    this.onEdit,
    this.onDelete,
  });

  final ReviewModel review;
  final bool isMine;
  final ValueChanged<ReviewModel>? onEdit;
  final ValueChanged<ReviewModel>? onDelete;

  String _bestImageUrl(ReviewImageModel image) {
    final thumb = image.thumbnailUrl.trim();
    final source = image.imageUrl.trim();
    final candidate = thumb.isNotEmpty ? thumb : source;
    if (candidate.isEmpty) return '';

    final transformed = ImageUrlTransformer.getTransformedImageUrl(
      candidate,
      AppConfig.instance.assetsHost,
    );
    return transformed.isNotEmpty ? transformed : candidate;
  }

  Widget _reviewImagePlaceholder(BuildContext context) {
    return Container(
      color: const Color(0xFFF2F2F2),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 16.sp,
              color: const Color(0xFFCB262E),
            ),
            SizedBox(height: 2.h),
            Text(
              Localizations.localeOf(context).languageCode == 'ar'
                  ? 'لا صورة'
                  : 'No Image',
              style: TextStyle(
                color: const Color(0xFF8A8A8A),
                fontSize: 7.sp,
                fontFamily: 'Montes',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionChip({
    required BuildContext context,
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
    String? semanticLabel,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(4.r),
          child: Icon(
            icon,
            size: 16.sp,
            color: color,
            semanticLabel: semanticLabel,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cleanReview = review.review
        .replaceAll(
          RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false),
          '',
        )
        .trim();
    final dateText =
        '${review.dateCreated.year}-${review.dateCreated.month.toString().padLeft(2, '0')}-${review.dateCreated.day.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    ...List.generate(
                      5,
                      (index) => Icon(
                        Icons.star,
                        size: 13.sp,
                        color: index < review.rating
                            ? const Color(0xFFF7C95F)
                            : const Color(0xFFE0E0E0),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      dateText,
                      style: TextStyle(
                        color: AppColors.midGray,
                        fontSize: 9.sp,
                        fontFamily: 'Montes',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (isMine && onEdit != null && onDelete != null) ...[
                _actionChip(
                  context: context,
                  onTap: () => onEdit!(review),
                  icon: Icons.edit_outlined,
                  color: const Color(0xFFCB262E),
                  semanticLabel: 'Edit review',
                ),
                SizedBox(width: 4.w),
                _actionChip(
                  context: context,
                  onTap: () => onDelete!(review),
                  icon: Icons.delete_outline,
                  color: const Color(0xFFD12B2B),
                  semanticLabel: 'Delete review',
                ),
              ],
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            review.reviewer,
            style: TextStyle(
              color: AppColors.black,
              fontSize: 10.sp,
              fontFamily: 'Montes',
              fontWeight: FontWeight.w600,
            ),
          ),
          if (cleanReview.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              cleanReview,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.black,
                fontSize: 10.sp,
                fontFamily: 'Montes',
                fontWeight: FontWeight.w400,
                height: 1.3,
              ),
            ),
          ],
          if (review.images.isNotEmpty) ...[
            SizedBox(height: 8.h),
            SizedBox(
              height: 64.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.images.length,
                separatorBuilder: (_, __) => SizedBox(width: 8.w),
                itemBuilder: (_, index) {
                  final image = review.images[index];
                  final url = _bestImageUrl(image);
                  return Container(
                    width: 64.w,
                    height: 64.h,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6.r),
                      color: const Color(0xFFF2F2F2),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: url.isEmpty
                        ? _reviewImagePlaceholder(context)
                        : CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                _reviewImagePlaceholder(context),
                          ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProductReviewComposerDialog extends StatefulWidget {
  const _ProductReviewComposerDialog({
    required this.productId,
    this.existingReview,
  });

  final String productId;
  final ReviewModel? existingReview;

  @override
  State<_ProductReviewComposerDialog> createState() =>
      _ProductReviewComposerDialogState();
}

class _ReviewComposerImageItem {
  const _ReviewComposerImageItem.local(this.path)
    : reviewImage = null,
      isExisting = false;

  const _ReviewComposerImageItem.remote(this.reviewImage)
    : path = '',
      isExisting = true;

  final String path;
  final ReviewImageModel? reviewImage;
  final bool isExisting;

  String get key => isExisting ? (reviewImage?.id.trim() ?? '') : path.trim();
}

class _ProductReviewComposerDialogState
    extends State<_ProductReviewComposerDialog> {
  late final TextEditingController _commentController;
  late double _rating;
  bool _isSubmitting = false;
  final List<String> _newImagePaths = <String>[];
  final Set<String> _removedExistingImageIds = <String>{};

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController(
      text: widget.existingReview?.review ?? '',
    );
    _rating = widget.existingReview?.rating.toDouble() ?? 0;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.existingReview != null;

  List<_ReviewComposerImageItem> _selectedImages() {
    final items = <_ReviewComposerImageItem>[
      for (final image
          in widget.existingReview?.images ?? const <ReviewImageModel>[])
        if (!_removedExistingImageIds.contains(image.id.trim()) &&
            _hasUsableImage(image))
          _ReviewComposerImageItem.remote(image),
      for (final path in _newImagePaths) _ReviewComposerImageItem.local(path),
    ];
    return items;
  }

  bool _hasUsableImage(ReviewImageModel image) {
    return image.thumbnailUrl.trim().isNotEmpty ||
        image.imageUrl.trim().isNotEmpty;
  }

  Widget _reviewImagePlaceholder(BuildContext context) {
    return Container(
      color: const Color(0xFFF2F2F2),
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 20.sp,
          color: const Color(0xFF9A9A9A),
        ),
      ),
    );
  }

  String _extractReviewId(dynamic data) {
    if (data is! Map<String, dynamic>) return '';
    final directId = (data['uuid'] ?? data['id'] ?? data['reviewId'] ?? '')
        .toString()
        .trim();
    if (directId.isNotEmpty) return directId;
    final review = data['review'];
    if (review is Map<String, dynamic>) {
      return (review['uuid'] ?? review['id'] ?? '').toString().trim();
    }
    return '';
  }

  Future<ImageSource?> _pickSource() async {
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
                title: Text(
                  Localizations.localeOf(context).languageCode == 'ar'
                      ? 'التقاط صورة'
                      : 'Take Photo',
                ),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(
                  Localizations.localeOf(context).languageCode == 'ar'
                      ? 'اختيار من المعرض'
                      : 'Choose from Gallery',
                ),
                onTap: () =>
                    Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
              ListTile(
                title: Text(
                  Localizations.localeOf(context).languageCode == 'ar'
                      ? 'إلغاء'
                      : 'Cancel',
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

  Future<void> _addMedia() async {
    final currentCount = _selectedImages().length;
    if (currentCount >= 5) {
      AppToast.show(
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        msg: Localizations.localeOf(context).languageCode == 'ar'
            ? 'يمكنك إضافة 5 صور كحد أقصى'
            : 'You can add up to 5 images only',
      );
      return;
    }

    try {
      final source = await _pickSource();
      if (!mounted || source == null) return;
      final remainingSlots = 5 - _selectedImages().length;
      if (remainingSlots <= 0) return;

      if (source == ImageSource.gallery) {
        final picked = await ImagePicker().pickMultiImage(
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1920,
        );
        if (!mounted || picked.isEmpty) return;
        setState(() {
          for (final file in picked.take(remainingSlots)) {
            final path = file.path.trim();
            if (path.isNotEmpty) {
              _newImagePaths.add(path);
            }
          }
        });
        return;
      }

      final file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (!mounted) return;
      final path = file?.path.trim();
      if (path == null || path.isEmpty) return;
      setState(() {
        _newImagePaths.add(path);
      });
    } on PlatformException catch (_) {
      if (!mounted) return;
      AppToast.show(
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        msg: 'Please allow camera/photos access in iOS Settings.',
      );
    } catch (_) {
      if (!mounted) return;
      AppToast.show(
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        msg: 'Unable to open media picker right now. Please try again.',
      );
    }
  }

  Future<ReviewModel?> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final comment = _commentController.text.trim();
    if (comment.isEmpty || _rating <= 0 || _isSubmitting) {
      return null;
    }
    setState(() {
      _isSubmitting = true;
    });

    try {
      if (!_isEditing) {
        final createResult = await sl<HomeRepository>().createReview(
          productId: widget.productId,
          comment: comment,
          rating: _rating,
          imagePaths: _newImagePaths,
        );
        if (!mounted) return null;
        return await createResult.fold<Future<ReviewModel?>>(
          (error) async {
            AppToast.show(
              gravity: ToastGravity.TOP,
              backgroundColor: Colors.red,
              msg: error.message,
            );
            return null;
          },
          (data) async {
            final reviewId = _extractReviewId(data);
            if (reviewId.isNotEmpty) {
              final refreshed = await sl<HomeRepository>().getReviewById(
                productId: widget.productId,
                reviewId: reviewId,
              );
              if (!mounted) return null;
              return refreshed.fold(
                (_) => ReviewModel.fromJson(
                  data is Map<String, dynamic> ? data : <String, dynamic>{},
                ),
                (review) => review,
              );
            }
            if (data is Map<String, dynamic>) {
              return ReviewModel.fromJson(data);
            }
            return null;
          },
        );
      }

      final existingReview = widget.existingReview!;
      final updateResult = await sl<HomeRepository>().updateReview(
        productId: widget.productId,
        reviewId: existingReview.id,
        comment: comment,
        rating: _rating,
      );
      if (!mounted) return null;

      return await updateResult.fold<Future<ReviewModel?>>(
        (error) async {
          AppToast.show(
            gravity: ToastGravity.TOP,
            backgroundColor: Colors.red,
            msg: error.message,
          );
          return null;
        },
        (data) async {
          var resolvedReviewId = existingReview.id.trim();
          if (data is Map<String, dynamic>) {
            final responseReviewId = (data['uuid'] ?? '').toString().trim();
            if (responseReviewId.isNotEmpty) {
              resolvedReviewId = responseReviewId;
            }
          }

          for (final imageId in _removedExistingImageIds) {
            final normalizedImageId = imageId.trim();
            if (normalizedImageId.isEmpty) continue;
            final deleteResult = await sl<HomeRepository>().deleteReviewImage(
              productId: widget.productId,
              reviewId: resolvedReviewId,
              imageId: normalizedImageId,
            );
            if (!mounted) return null;
            if (deleteResult.isLeft()) {
              final error = deleteResult.fold((l) => l, (_) => null);
              if (error != null) {
                AppToast.show(
                  gravity: ToastGravity.TOP,
                  backgroundColor: Colors.red,
                  msg: error.message,
                );
                return null;
              }
            }
          }

          for (final path in _newImagePaths) {
            final normalizedPath = path.trim();
            if (normalizedPath.isEmpty || !File(normalizedPath).existsSync()) {
              continue;
            }
            final uploadResult = await sl<HomeRepository>().createReviewImage(
              productId: widget.productId,
              reviewId: resolvedReviewId,
              formData: FormData.fromMap({
                'file': await MultipartFile.fromFile(normalizedPath),
              }),
            );
            if (!mounted) return null;
            if (uploadResult.isLeft()) {
              final uploadError = uploadResult.fold((l) => l, (_) => null);
              if (uploadError != null) {
                AppToast.show(
                  gravity: ToastGravity.TOP,
                  backgroundColor: Colors.red,
                  msg: uploadError.message,
                );
                return null;
              }
            }
          }

          final shouldRefreshImages =
              _newImagePaths.isNotEmpty || _removedExistingImageIds.isNotEmpty;
          if (!shouldRefreshImages) {
            return ReviewModel(
              id: resolvedReviewId.isNotEmpty
                  ? resolvedReviewId
                  : existingReview.id,
              customerId: existingReview.customerId,
              dateCreated: existingReview.dateCreated,
              reviewer: existingReview.reviewer,
              review: comment,
              rating: _rating.toInt(),
              verified: existingReview.verified,
              isEdited: true,
              images: existingReview.images
                  .where(
                    (image) => !_removedExistingImageIds.contains(image.id),
                  )
                  .toList(growable: false),
            );
          }

          final refreshed = await sl<HomeRepository>().getReviewById(
            productId: widget.productId,
            reviewId: resolvedReviewId,
          );
          if (!mounted) return null;
          return refreshed.fold(
            (_) => ReviewModel(
              id: resolvedReviewId.isNotEmpty
                  ? resolvedReviewId
                  : existingReview.id,
              customerId: existingReview.customerId,
              dateCreated: existingReview.dateCreated,
              reviewer: existingReview.reviewer,
              review: comment,
              rating: _rating.toInt(),
              verified: existingReview.verified,
              isEdited: true,
              images: existingReview.images
                  .where(
                    (image) => !_removedExistingImageIds.contains(image.id),
                  )
                  .toList(growable: false),
            ),
            (review) => review,
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final selectedImages = _selectedImages();
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w),
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.86,
          ),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isEditing
                            ? (isArabic ? 'تعديل تقييمك' : 'Edit your review')
                            : (isArabic ? 'إضافة تقييم' : 'Add your review'),
                        style: TextStyle(
                          fontFamily: 'Montes',
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 24.w,
                        height: 24.w,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F2),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16.sp,
                          color: const Color(0xFF4A4A4A),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starValue = index + 1;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _rating = starValue.toDouble()),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2.w),
                        child: Icon(
                          starValue <= _rating ? Icons.star : Icons.star_border,
                          color: const Color(0xFFFFB800),
                          size: 24.sp,
                        ),
                      ),
                    );
                  }),
                ),
                SizedBox(height: 14.h),
                Container(
                  width: 295.w,
                  constraints: BoxConstraints(minHeight: 140.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  child: TextField(
                    controller: _commentController,
                    minLines: 5,
                    maxLines: 8,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                    textAlignVertical: TextAlignVertical.top,
                    style: TextStyle(fontFamily: 'Montes', fontSize: 14.sp),
                    decoration: InputDecoration(
                      hintText: isArabic
                          ? 'اكتب مراجعتك هنا'
                          : 'Write your review here',
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                if (selectedImages.isNotEmpty)
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: selectedImages
                        .map((item) {
                          final isRemote = item.isExisting;
                          final image = item.reviewImage;
                          final isSelectedRemote =
                              isRemote &&
                              image != null &&
                              image.id.trim().isNotEmpty;
                          final displayUrl = isRemote && image != null
                              ? (image.thumbnailUrl.trim().isNotEmpty
                                    ? image.thumbnailUrl
                                    : image.imageUrl)
                              : '';
                          final localPath = item.path.trim();
                          final isVideo =
                              localPath.toLowerCase().endsWith('.mp4') ||
                              localPath.toLowerCase().endsWith('.mov') ||
                              localPath.toLowerCase().endsWith('.m4v') ||
                              localPath.toLowerCase().endsWith('.avi') ||
                              localPath.toLowerCase().endsWith('.mkv') ||
                              localPath.toLowerCase().endsWith('.webm');
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 86.w,
                                height: 86.w,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.r),
                                  color: const Color(0xFFF2F2F2),
                                  border: Border.all(
                                    color: const Color(0xFFE0E0E0),
                                  ),
                                ),
                                child: isRemote
                                    ? CachedNetworkImage(
                                        imageUrl: displayUrl,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) =>
                                            _reviewImagePlaceholder(context),
                                      )
                                    : (isVideo
                                          ? const Icon(Icons.videocam_outlined)
                                          : Image.file(
                                              File(localPath),
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  _reviewImagePlaceholder(
                                                    context,
                                                  ),
                                            )),
                              ),
                              Positioned(
                                top: -6,
                                right: -6,
                                child: GestureDetector(
                                  onTap: _isSubmitting
                                      ? null
                                      : () {
                                          setState(() {
                                            if (isSelectedRemote) {
                                              _removedExistingImageIds.add(
                                                image.id.trim(),
                                              );
                                            } else {
                                              _newImagePaths.remove(localPath);
                                            }
                                          });
                                        },
                                  child: Container(
                                    width: 22.w,
                                    height: 22.w,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFCB262E),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 14.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        })
                        .toList(growable: false),
                  ),
                SizedBox(height: 12.h),
                if (selectedImages.isNotEmpty) SizedBox(height: 4.h),
                OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : _addMedia,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCB262E)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9.r),
                    ),
                    minimumSize: Size(0, 48.h),
                  ),
                  icon: Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 18.sp,
                    color: const Color(0xFFCB262E),
                  ),
                  label: Text(
                    selectedImages.isEmpty
                        ? (isArabic ? 'اختيار صورة' : 'Select Photo')
                        : (isArabic
                              ? 'اختيار صورة إضافية (${selectedImages.length})'
                              : 'Select Photo (${selectedImages.length})'),
                    style: TextStyle(
                      color: const Color(0xFFCB262E),
                      fontFamily: 'Montes',
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                SizedBox(
                  width: 295.w,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            final review = await _submit();
                            if (!context.mounted || review == null) return;
                            Navigator.of(context).pop(review);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFCB262E),
                      foregroundColor: Colors.white,
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            _isEditing
                                ? (isArabic ? 'تحديث التقييم' : 'Update Review')
                                : (isArabic
                                      ? 'إرسال التقييم'
                                      : 'Submit Review'),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StockStatusBadge extends StatelessWidget {
  const _StockStatusBadge({
    required this.isInStock,
    required this.stockQuantity,
  });

  final bool isInStock;
  final int stockQuantity;

  @override
  Widget build(BuildContext context) {
    final hasQuantityFromApi = stockQuantity > 0;
    final statusColor = isInStock ? const Color(0xFF1B9C4A) : AppColors.red;
    final bgColor = isInStock
        ? const Color(0x1A1B9C4A)
        : const Color(0x1AFF3B30);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: statusColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.w,
            height: 6.w,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            isInStock ? S.of(context).in_stock : S.of(context).out_of_stock,
            style: TextStyle(
              color: statusColor,
              fontSize: 11.sp,
              fontFamily: 'Montes',
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
          if (isInStock && hasQuantityFromApi) ...[
            SizedBox(width: 6.w),
            Text(
              '($stockQuantity)',
              style: TextStyle(
                color: statusColor,
                fontSize: 10.sp,
                fontFamily: 'Montes',
                fontWeight: FontWeight.w500,
                height: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SizeGuideSection extends StatefulWidget {
  const _SizeGuideSection({required this.imageUrl});

  final String imageUrl;

  @override
  State<_SizeGuideSection> createState() => _SizeGuideSectionState();
}

class _SizeGuideSectionState extends State<_SizeGuideSection> {
  bool _isExpanded = false;

  String _normalizeImageUrl(String rawUrl) {
    final candidate = rawUrl.trim();
    if (candidate.isEmpty) return '';
    final transformed = ImageUrlTransformer.getTransformedImageUrl(
      candidate,
      AppConfig.instance.assetsHost,
    );
    return transformed.isNotEmpty ? transformed : candidate;
  }

  Future<void> _openFullscreen(String imageUrl) async {
    if (imageUrl.trim().isEmpty || !mounted) return;
    await context.push(AppRouter.fullScreenImage, extra: imageUrl.trim());
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final resolvedImageUrl = _normalizeImageUrl(widget.imageUrl);
    if (resolvedImageUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE3E3E3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              final nextExpanded = !_isExpanded;
              setState(() => _isExpanded = nextExpanded);
              if (nextExpanded) {
                unawaited(
                  sl<AppsFlyerService>().logConversionEvent(
                    'view_size_chart',
                    eventParams: {'category': 'product_detail'},
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(10.r),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              child: Row(
                children: [
                  Icon(
                    Icons.straighten_rounded,
                    size: 18.sp,
                    color: AppColors.black,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      isArabic ? 'دليل المقاس' : 'Size guide',
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 14.sp,
                        fontFamily: 'Montes',
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_right_rounded,
                    size: 24.sp,
                    color: const Color(0xFF1F1F1F),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            SizedBox(height: 12.h),
            GestureDetector(
              onTap: () => _openFullscreen(resolvedImageUrl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: CachedNetworkImage(
                  imageUrl: resolvedImageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 180.h,
                    color: const Color(0xFFF4F4F4),
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(
                      color: Color(0xFFCB262E),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 160.h,
                    color: const Color(0xFFF4F4F4),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 30.sp,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                isArabic ? 'اضغط لعرض الصورة كاملة' : 'Tap to view full size',
                style: TextStyle(
                  color: AppColors.midGray,
                  fontSize: 10.sp,
                  fontFamily: 'Montes',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewStatPill extends StatelessWidget {
  const _PreviewStatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF6B7280),
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
              fontFamily: 'Montes',
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: TextStyle(
              color: const Color(0xFF111827),
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              fontFamily: 'Montes',
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductBottomCartBar extends StatelessWidget {
  const _ProductBottomCartBar({
    required this.product,
    required this.productId,
    required this.onOpenCart,
    required this.onAddToCartSuccess,
    required this.onBuyNow,
    required this.isBuyNowLoading,
    required this.onValidateVariation,
    required this.resolveVariantUuid,
    required this.chosenAttributes,
    required this.chosenQuantity,
    required this.selectedVariation,
  });

  final AllProductModel product;
  final String productId;
  final Future<void> Function(String productId) onOpenCart;
  final VoidCallback onAddToCartSuccess;
  final Future<void> Function(AllProductModel product) onBuyNow;
  final bool isBuyNowLoading;
  final bool Function(AllProductModel product) onValidateVariation;
  final String Function(AllProductModel product) resolveVariantUuid;
  final Map<String, String> chosenAttributes;
  final int chosenQuantity;
  final ProductVariations? selectedVariation;

  bool _isVariationStockAvailable(String? status) {
    final normalized = (status ?? '').trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return normalized == 'instock' ||
        normalized == 'in_stock' ||
        normalized == 'in stock' ||
        normalized == 'available';
  }

  @override
  Widget build(BuildContext context) {
    final currentProductId = productId.trim().isEmpty
        ? product.id.toString()
        : productId.trim();

    return SafeArea(
      top: false,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
          decoration: const BoxDecoration(
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 18,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: BlocConsumer<AddCartCubit, AddCartState>(
            listener: (context, state) {
              if (state is AddCartError) {
                AppToast.show(
                  gravity: ToastGravity.TOP,
                  backgroundColor: AppColors.primaryColor,
                  msg: state.error.message,
                );
              } else if (state is AddCartSuccess &&
                  state.productId == currentProductId) {
                onAddToCartSuccess();
                final unitPrice = selectedVariation == null
                    ? _parseTikTokMoney(product.prices.price)
                    : (selectedVariation!.salePrice > 0
                          ? selectedVariation!.salePrice.toDouble()
                          : selectedVariation!.price.toDouble());
                unawaited(
                  TikTokBusinessService.addToCart(
                    contentId: currentProductId,
                    description: product.shortDescription.trim().isNotEmpty
                        ? product.shortDescription.trim()
                        : product.description.trim(),
                    contentType: 'product',
                    value: (unitPrice * chosenQuantity).toStringAsFixed(2),
                    currency: product.prices.currencyCode.trim().isNotEmpty
                        ? product.prices.currencyCode.trim().toUpperCase()
                        : 'USD',
                    contents: [
                      {
                        'contentId': currentProductId,
                        'contentName': product.name.trim(),
                        'price': unitPrice,
                        'quantity': chosenQuantity,
                      },
                    ],
                  ),
                );
                unawaited(
                  sl<AppsFlyerService>().logAddToCart(
                    contentId: currentProductId,
                    contentType: 'product',
                    price: unitPrice.toStringAsFixed(2),
                    currency: product.prices.currencyCode.trim().isNotEmpty
                        ? product.prices.currencyCode.trim().toUpperCase()
                        : 'USD',
                    quantity: chosenQuantity,
                  ),
                );
              }
            },
            builder: (context, state) {
              final showGoToCart =
                  product.isInCart == true ||
                  (state is AddCartSuccess &&
                      state.productId == currentProductId);
              final isLoading =
                  state is AddCartLoading &&
                  state.productId == currentProductId;
              final selected = selectedVariation;

              return Row(
                children: [
                  GestureDetector(
                    onTap: () => onOpenCart(currentProductId),
                    child: Container(
                      width: 56.w,
                      height: 60.h,
                      padding: EdgeInsets.fromLTRB(12.w, 2.h, 12.w, 2.h),
                      alignment: Alignment.center,
                      child: Image.asset(
                        'assets/images/cart.png',
                        width: 30,
                        height: 30,
                        fit: BoxFit.contain,
                        color: const Color(0x99000000),
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: SizedBox(
                      height: 70.h,
                      child: CustomElevatedButton(
                        onPressed: showGoToCart
                            ? () => onOpenCart(currentProductId)
                            : () async {
                                if (currentProductId == '0') {
                                  AppToast.show(
                                    gravity: ToastGravity.TOP,
                                    backgroundColor: Colors.red,
                                    msg:
                                        "Unable to identify product for cart. Please retry.",
                                  );
                                  return;
                                }

                                if (!onValidateVariation(product)) {
                                  return;
                                }

                                if (selected != null) {
                                  final inStock = _isVariationStockAvailable(
                                    selected.stockStatus,
                                  );
                                  if (!inStock) {
                                    AppToast.show(
                                      gravity: ToastGravity.TOP,
                                      backgroundColor: Colors.red,
                                      msg: S.of(context).out_of_stock,
                                    );
                                    return;
                                  }
                                  if (selected.stockQuantity > 0 &&
                                      chosenQuantity > selected.stockQuantity) {
                                    AppToast.show(
                                      gravity: ToastGravity.TOP,
                                      backgroundColor: Colors.red,
                                      msg:
                                          'Only ${selected.stockQuantity} item(s) available.',
                                    );
                                    return;
                                  }
                                } else if (product.isInStock == false) {
                                  AppToast.show(
                                    gravity: ToastGravity.TOP,
                                    backgroundColor: Colors.red,
                                    msg: S.of(context).out_of_stock,
                                  );
                                  return;
                                }

                                final variantUuid = resolveVariantUuid(
                                  product,
                                ).trim();
                                if (variantUuid.isEmpty) {
                                  AppToast.show(
                                    gravity: ToastGravity.TOP,
                                    backgroundColor: Colors.red,
                                    msg: "Please select a valid variant.",
                                  );
                                  return;
                                }

                                final selectedImageUrl =
                                    (selected?.image ?? '').trim().isNotEmpty
                                    ? (selected!.image ?? '').trim()
                                    : (product.images.isNotEmpty
                                          ? (() {
                                              final thumb = product
                                                  .images
                                                  .first
                                                  .thumbnail
                                                  .trim();
                                              if (thumb.isNotEmpty) {
                                                return thumb;
                                              }
                                              final src = product
                                                  .images
                                                  .first
                                                  .src
                                                  .trim();
                                              if (src.isNotEmpty) {
                                                return src;
                                              }
                                              return '';
                                            })()
                                          : (() {
                                              final featuredThumb = product
                                                  .featuredThumbnailUrl
                                                  .trim();
                                              if (featuredThumb.isNotEmpty) {
                                                return featuredThumb;
                                              }
                                              return product.featuredImageUrl
                                                  .trim();
                                            })());
                                final selectedAttributes =
                                    selected?.attributes
                                        .map(
                                          (attribute) => {
                                            'attribute': attribute.name,
                                            'value': attribute.option,
                                          },
                                        )
                                        .toList() ??
                                    chosenAttributes.entries
                                        .map(
                                          (entry) => {
                                            'attribute': entry.key,
                                            'value': entry.value,
                                          },
                                        )
                                        .toList();
                                debugPrint(
                                  '[add-to-cart] ${jsonEncode({'productUuid': currentProductId, 'variantUuid': variantUuid, 'quantity': chosenQuantity, 'selectedAttributes': selectedAttributes, 'selectedImageUrl': selectedImageUrl})}',
                                );

                                await context.read<AddCartCubit>().addToCart(
                                  productUuid: currentProductId,
                                  variantUuid: variantUuid,
                                  quantity: chosenQuantity,
                                );

                                if (!context.mounted) return;
                                HomeScreen.homeKey.currentState
                                    ?.refreshWishListAndCartList();
                              },
                        backgroundColor: AppColors.primaryColor,
                        elevation: 0,
                        horizontalPadding: 24.w,
                        verticalPadding: 20.h,
                        child: !showGoToCart && isLoading
                            ? SizedBox(
                                width: 22.w,
                                height: 22.w,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.4,
                                ),
                              )
                            : Text(
                                showGoToCart
                                    ? S.of(context).go_to_cart
                                    : S.of(context).add_to_cart,
                                style: AppStyle.stylesemiBold12(context),
                              ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: SizedBox(
                      height: 70.h,
                      child: CustomElevatedButton(
                        onPressed: isBuyNowLoading
                            ? null
                            : () => onBuyNow(product),
                        backgroundColor: AppColors.primaryColor,
                        elevation: 0,
                        horizontalPadding: 20.w,
                        verticalPadding: 20.h,
                        child: isBuyNowLoading
                            ? SizedBox(
                                width: 22.w,
                                height: 22.w,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.4,
                                ),
                              )
                            : Text(
                                Localizations.localeOf(context).languageCode ==
                                        'ar'
                                    ? 'اشتر الآن'
                                    : 'Buy Now',
                                style: AppStyle.stylesemiBold12(context),
                              ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SimilarProductsSection extends StatelessWidget {
  const _SimilarProductsSection({
    required this.products,
    required this.isGridView,
    required this.onToggleGridView,
    required this.onMoreTap,
  });

  final List<HomeGraphqlProduct> products;
  final bool isGridView;
  final ValueChanged<bool> onToggleGridView;
  final VoidCallback onMoreTap;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    final localized = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                Localizations.localeOf(context).languageCode == 'ar'
                    ? 'منتجات مشابهة'
                    : 'Similar Products',
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 20.sp,
                  fontFamily: 'Montes',
                  fontWeight: FontWeight.w500,
                  height: 24 / 20,
                ),
              ),
            ),
            GestureDetector(
              onTap: onMoreTap,
              child: Text(
                S.of(context).more,
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 14.sp,
                  fontFamily: 'Montes',
                  fontWeight: FontWeight.w400,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            SizedBox(width: 10.w),
            GestureDetector(
              onTap: () => onToggleGridView(false),
              child: Opacity(
                opacity: isGridView ? 0.6 : 1,
                child: Image.asset(
                  'assets/images/sorticon2.png',
                  width: 20.w,
                  height: 20.w,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(width: 6.w),
            GestureDetector(
              onTap: () => onToggleGridView(true),
              child: Opacity(
                opacity: isGridView ? 1 : 0.6,
                child: Image.asset(
                  'assets/images/sorticon.png',
                  width: 20.w,
                  height: 20.w,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 18.h),
        SizedBox(
          height: isGridView
              ? ProductCollectionCard.compactCardHeight.h + 24.h
              : 580.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.fromLTRB(0, 8.h, 12.w, 20.h),
            clipBehavior: Clip.none,
            itemCount: products.length,
            separatorBuilder: (_, __) => SizedBox(width: 12.w),
            itemBuilder: (context, index) {
              final product = products[index];
              return SizedBox(
                width: isGridView
                    ? ProductCollectionCard.compactCardWidth.w
                    : ProductCollectionCard.expandedCardWidth.w,
                child: ProductCollectionCard(
                  productId: product.uuid,
                  productSlug: product.slug,
                  selectedVariantUuid: product.variantUuid ?? '',
                  name: product.title,
                  subtitle: ProductDescriptionFormatter.resolveShort(
                    brief: product.brief,
                    descriptionHtml: product.descriptionHtml,
                    description: product.description,
                    fallback: localized.description,
                  ),
                  imageUrl: product.primaryVariantImageUrl,
                  imageAssetPath: Assets.imagesShoes,
                  campaignLabel:
                      product.campaign?.name.trim().isNotEmpty == true
                      ? product.campaign!.name
                      : product.title,
                  campaignEndsAt: product.campaign?.finishesAt,
                  price: product.formattedPrice,
                  oldPrice: product.formattedOriginalPrice,
                  currencyCode: product.formattedCurrencyCode,
                  favoritesLabel:
                      '${formatLocalizedNumber(context, product.likesCount)}  •  ${localized.favorites}',
                  reviewsLabel:
                      '${formatLocalizedNumber(context, product.averageRatingText, fractionDigits: 1)} ★★★★★  •  ${formatLocalizedNumber(context, product.reviewsCount)} ${localized.reviews}',
                  isInitiallyInWishList: false,
                  wishlistEnabled: false,
                  type: isGridView
                      ? ProductCollectionCardType.compact
                      : ProductCollectionCardType.expanded,
                  width: isGridView
                      ? ProductCollectionCard.compactCardWidth.w
                      : ProductCollectionCard.expandedCardWidth.w,
                  onTap: () => context.push(
                    AppRouter.productDetails,
                    extra: {
                      'id': product.uuid,
                      'slug': product.slug,
                      'selectedVariantUuid': product.variantUuid ?? '',
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SimilarProductsSectionSkeleton extends StatelessWidget {
  const _SimilarProductsSectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Localizations.localeOf(context).languageCode == 'ar'
              ? 'منتجات مشابهة'
              : 'Similar Products',
          style: TextStyle(
            color: AppColors.black,
            fontSize: 20.sp,
            fontFamily: 'Montes',
            fontWeight: FontWeight.w500,
            height: 24 / 20,
          ),
        ),
        SizedBox(height: 18.h),
        SizedBox(
          height: ProductCollectionCard.compactCardHeight.h + 24.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.fromLTRB(0, 8.h, 12.w, 20.h),
            clipBehavior: Clip.none,
            itemCount: 2,
            separatorBuilder: (_, __) => SizedBox(width: 12.w),
            itemBuilder: (_, __) {
              return SizedBox(
                width: ProductCollectionCard.compactCardWidth.w,
                child: const ProductCollectionCard(
                  productId: '0',
                  productSlug: '',
                  name: 'Product Name',
                  subtitle: 'Product preview',
                  price: '50.00',
                  oldPrice: '80.00',
                  favoritesLabel: '0 • Favorites',
                  reviewsLabel: '',
                  imageAssetPath: Assets.imagesShoes,
                  wishlistEnabled: false,
                  onTap: _noop,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

void _noop() {}
