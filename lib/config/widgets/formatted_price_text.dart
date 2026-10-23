import 'package:camion/core/utils/currency_display_utils.dart';
import 'package:flutter/material.dart';

class FormattedPriceText extends StatelessWidget {
  const FormattedPriceText({
    super.key,
    required this.amountText,
    required this.currencyText,
    required this.mainStyle,
    required this.minorStyle,
    this.textAlign = TextAlign.start,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.spaceBeforeCurrency = false,
  });

  final String amountText;
  final String currencyText;
  final TextStyle mainStyle;
  final TextStyle minorStyle;
  final TextAlign textAlign;
  final int maxLines;
  final TextOverflow overflow;
  final bool spaceBeforeCurrency;

  @override
  Widget build(BuildContext context) {
    final hasAmount = amountText.trim().isNotEmpty;
    final normalizedAmount = hasAmount
        ? formatLocalizedDecimal(context, amountText)
        : formatLocalizedDecimal(context, 0);
    final parts = normalizedAmount.split('.');
    final arabicParts = normalizedAmount.split('٫');
    final activeParts = parts.length > 1 ? parts : arabicParts;
    final whole = activeParts.first;
    final decimal = activeParts.length > 1 ? activeParts[1] : '00';
    final separator = isArabicLocale(context) ? '٫' : '.';
    final minor = '$separator${decimal.padRight(2, '0').substring(0, 2)}';
    final currency = currencyText.trim().isEmpty
        ? ''
        : localizedCurrencyLabel(context, currencyText);
    final currencyWithSpace = currency.isEmpty ? '' : ' $currency';

    return RichText(
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      text: TextSpan(
        children: [
          if (hasAmount && currency.isNotEmpty && !isArabicLocale(context))
            TextSpan(text: '$currency ', style: minorStyle),
          if (hasAmount) TextSpan(text: whole, style: mainStyle),
          if (hasAmount) TextSpan(text: minor, style: minorStyle),
          if (isArabicLocale(context))
            TextSpan(text: currencyWithSpace, style: minorStyle)
          else if (!hasAmount)
            TextSpan(
              text: spaceBeforeCurrency ? currencyWithSpace : currency,
              style: minorStyle,
            ),
        ],
      ),
    );
  }
}
