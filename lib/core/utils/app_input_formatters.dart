import 'package:flutter/services.dart';

class AppInputFormatters {
  static final TextInputFormatter noEmoji = TextInputFormatter.withFunction((
    oldValue,
    newValue,
  ) {
    final filteredText = _removeEmoji(newValue.text);
    if (filteredText == newValue.text) return newValue;

    final collapsedOffset = filteredText.length;
    return TextEditingValue(
      text: filteredText,
      selection: TextSelection.collapsed(offset: collapsedOffset),
      composing: TextRange.empty,
    );
  });

  static final TextInputFormatter couponCodeAlphaNumericOnly =
      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]'));

  static final TextInputFormatter fullNameNoSpecialCharacters =
      TextInputFormatter.withFunction((oldValue, newValue) {
        final filteredText = _filterNameInput(newValue.text);
        if (filteredText == newValue.text) return newValue;

        return TextEditingValue(
          text: filteredText,
          selection: TextSelection.collapsed(offset: filteredText.length),
          composing: TextRange.empty,
        );
      });

  static bool isValidFullName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    return _filterNameInput(trimmed) == trimmed;
  }

  static String _filterNameInput(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      if (_isAllowedNameRune(rune)) {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  static bool _isAllowedNameRune(int rune) {
    if (rune == 0x20) return true; // space

    // Latin letters A-Z / a-z
    final isLatinUpper = rune >= 0x41 && rune <= 0x5A;
    final isLatinLower = rune >= 0x61 && rune <= 0x7A;
    if (isLatinUpper || isLatinLower) return true;

    // Arabic letters + common Arabic diacritics.
    final isArabicLetter =
        (rune >= 0x0621 && rune <= 0x063A) ||
        (rune >= 0x0641 && rune <= 0x064A) ||
        (rune >= 0x066E && rune <= 0x066F) ||
        (rune >= 0x0671 && rune <= 0x06D3) ||
        rune == 0x06D5 ||
        (rune >= 0x06FA && rune <= 0x06FC) ||
        rune == 0x06FF;
    final isArabicMark = rune == 0x0670 || (rune >= 0x064B && rune <= 0x065F);

    if (isArabicLetter || isArabicMark) return true;

    return false;
  }

  static String _removeEmoji(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      if (!_isEmojiRune(rune)) {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  static bool _isEmojiRune(int rune) {
    if (rune == 0x200D || rune == 0xFE0F) return true;
    if (rune >= 0x1F1E6 && rune <= 0x1F1FF) return true;
    if (rune >= 0x1F300 && rune <= 0x1F5FF) return true;
    if (rune >= 0x1F600 && rune <= 0x1F64F) return true;
    if (rune >= 0x1F680 && rune <= 0x1F6FF) return true;
    if (rune >= 0x1F700 && rune <= 0x1F77F) return true;
    if (rune >= 0x1F780 && rune <= 0x1F7FF) return true;
    if (rune >= 0x1F800 && rune <= 0x1F8FF) return true;
    if (rune >= 0x1F900 && rune <= 0x1F9FF) return true;
    if (rune >= 0x1FA00 && rune <= 0x1FAFF) return true;
    if (rune >= 0x2600 && rune <= 0x27BF) return true;
    return false;
  }
}
