import 'package:camion/core/utils/currency_display_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<BuildContext> pumpContext(WidgetTester tester, Locale locale) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return capturedContext;
  }

  testWidgets('formats GCC money with Arabic digits and symbols', (
    tester,
  ) async {
    final context = await pumpContext(tester, const Locale('ar'));

    expect(formatMoneyForDisplay(context, 129, 'QAR'), '١٢٩٫٠٠ ر.ق');
    expect(formatMoneyForDisplay(context, 129, 'SAR'), '١٢٩٫٠٠ ر.س');
    expect(formatMoneyForDisplay(context, 129, 'KWD'), '١٢٩٫٠٠ د.ك');
  });

  testWidgets('keeps non-GCC currency as ISO code in Arabic', (tester) async {
    final context = await pumpContext(tester, const Locale('ar'));

    expect(formatMoneyForDisplay(context, 129, 'USD'), '١٢٩٫٠٠ USD');
  });

  testWidgets('formats money with ISO code and Latin digits in English', (
    tester,
  ) async {
    final context = await pumpContext(tester, const Locale('en'));

    expect(formatMoneyForDisplay(context, 129, 'QAR'), 'QAR 129.00');
    expect(formatMoneyForDisplay(context, 129, 'USD'), 'USD 129.00');
  });
}
