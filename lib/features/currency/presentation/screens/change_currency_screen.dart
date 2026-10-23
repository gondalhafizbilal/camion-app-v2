import 'package:camion/config/widgets/app_tap_feedback.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/core/utils/navigation_utils.dart';
import 'package:camion/features/currency/data/models/currency_model.dart';
import 'package:camion/features/currency/presentation/logic/cubit/currency_cubit.dart';
import 'package:camion/features/home/presentation/screens/home_screen.dart';
import 'package:camion/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChangeCurrencyScreen extends StatefulWidget {
  const ChangeCurrencyScreen({super.key});

  @override
  State<ChangeCurrencyScreen> createState() => _ChangeCurrencyScreenState();
}

class _ChangeCurrencyScreenState extends State<ChangeCurrencyScreen> {
  String? _pendingCurrencyCode;
  bool _saving = false;
  final TextEditingController _searchController = TextEditingController();
  bool _searchVisible = false;
  String _searchQuery = '';

  String _tr(BuildContext context, {required String en, required String ar}) {
    return Localizations.localeOf(context).languageCode.toLowerCase() == 'ar'
        ? ar
        : en;
  }

  @override
  void initState() {
    super.initState();
    // Ensure saved currency loaded then fetch list
    context.read<CurrencyCubit>().loadSavedCurrency();
    context.read<CurrencyCubit>().loadCurrencies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searchVisible = !_searchVisible;
      if (!_searchVisible) {
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  List<Currency> _filteredCurrencies(List<Currency> currencies) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return currencies;
    return currencies.where((item) {
      final code = item.code.toLowerCase();
      final symbol = item.symbol.toLowerCase();
      final name = (item.name ?? '').toLowerCase();
      return code.contains(q) || symbol.contains(q) || name.contains(q);
    }).toList(growable: false);
  }

  Future<void> _saveCurrency(List<Currency> currencies) async {
    if (_saving) return;
    final cubit = context.read<CurrencyCubit>();
    final selectedCode = _pendingCurrencyCode ?? cubit.selectedCurrency?.code;
    if (selectedCode == null || selectedCode.isEmpty) return;

    final currentCode = cubit.selectedCurrency?.code;
    if (currentCode == selectedCode) {
      AppNavigator.safePop(context);
      return;
    }

    final selectedCurrency = currencies.firstWhere(
      (item) => item.code == selectedCode,
      orElse: () => cubit.selectedCurrency ?? currencies.first,
    );

    setState(() => _saving = true);
    await cubit.selectCurrency(selectedCurrency);
    HomeScreen.homeKey.currentState?.refreshProducts();
    if (!mounted) return;
    setState(() => _saving = false);
    AppNavigator.safePop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: BlocBuilder<CurrencyCubit, CurrencyState>(
            builder: (context, state) {
              final currencies = context.read<CurrencyCubit>().currencies;
              final selected = context.read<CurrencyCubit>().selectedCurrency;
              final activeCode = _pendingCurrencyCode ?? selected?.code;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Opacity(
                        opacity: 0.8,
                        child: SizedBox(
                          width: 40.w,
                          height: 40.h,
                          child: AppTapFeedback(
                            onTap: () => AppNavigator.safePop(context),
                            customBorder: const CircleBorder(),
                            child: Icon(
                              Icons.arrow_back,
                              color: AppColors.black,
                              size: 24.sp,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          S.of(context).currency,
                          style: AppStyle.styleAppBarTitle20Medium(context),
                        ),
                      ),
                      Opacity(
                        opacity: 0.8,
                        child: SizedBox(
                          width: 40.w,
                          height: 40.h,
                          child: AppTapFeedback(
                            onTap: _toggleSearch,
                            customBorder: const CircleBorder(),
                            child: _searchVisible
                                ? Icon(
                                    Icons.close,
                                    color: AppColors.primaryColor,
                                    size: 24.sp,
                                  )
                                : Image.asset(
                                    'assets/images/searchicon.png',
                                    width: 40.w,
                                    height: 40.h,
                                    fit: BoxFit.contain,
                                  ),
                        ),
                      ),
                      ),
                    ],
                  ),
                  if (_searchVisible) ...[
                    SizedBox(height: 8.h),
                    SizedBox(
                      height: 40.h,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                        decoration: InputDecoration(
                          hintText:
                              '${S.of(context).search} ${S.of(context).currency}',
                          isDense: true,
                          prefixIcon: const Icon(Icons.search),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 10.h,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: const BorderSide(
                              color: Color(0xFFE3E7EE),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: const BorderSide(
                              color: Color(0xFFE3E7EE),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 28.h),
                  Text(
                    _tr(
                      context,
                      en: 'Select Your Currency',
                      ar: 'اختر عملتك',
                    ),
                    style: AppStyle.styleSectionTitle16Medium(context),
                  ),
                  SizedBox(height: 18.h),
                  Expanded(
                    child:
                        (state is CurrencyLoading && currencies.isEmpty)
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryColor,
                            ),
                          )
                        : _filteredCurrencies(currencies).isEmpty
                        ? Center(
                            child: Text(
                              _searchQuery.trim().isEmpty
                                  ? S.of(context).no_currencies_available
                                  : _tr(
                                      context,
                                      en: 'No matching currencies found',
                                      ar: 'لا توجد عملات مطابقة',
                                    ),
                              style: AppStyle.styleRegular16(
                                context,
                              ).copyWith(color: AppColors.gray),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _filteredCurrencies(currencies).length,
                            separatorBuilder: (_, __) => SizedBox(height: 6.h),
                            itemBuilder: (context, index) {
                              final currency =
                                  _filteredCurrencies(currencies)[index];
                              final isSelected = activeCode == currency.code;
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _pendingCurrencyCode = currency.code;
                                  });
                                },
                                borderRadius: BorderRadius.circular(8.r),
                                child: Container(
                                  width: double.infinity,
                                  height: 56.h,
                                  padding: EdgeInsets.fromLTRB(
                                    12.w,
                                    8.h,
                                    12.w,
                                    8.h,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${currency.code} ${currency.symbol}',
                                          style: TextStyle(
                                            fontFamily: 'Montes',
                                            fontWeight: FontWeight.w500,
                                            fontSize: 16.sp,
                                            height: 1.5,
                                            color: isSelected
                                                ? AppColors.primaryColor
                                                : AppColors.black,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        Container(
                                          width: 24.w,
                                          height: 24.w,
                                          decoration: const BoxDecoration(
                                            color: AppColors.primaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 16.sp,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: _saving ? null : () => _saveCurrency(currencies),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              S.of(context).save,
                              style: TextStyle(
                                fontFamily: 'Montes',
                                fontWeight: FontWeight.w600,
                                fontSize: 18.sp,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
