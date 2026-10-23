class ProductDescriptionFormatter {
  const ProductDescriptionFormatter._();

  static String parseHtmlToPlainText(String value) {
    if (value.trim().isEmpty) return '';

    var text = _decodeHtmlEntities(value);
    text = text.replaceAll(
      RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false),
      '\n',
    );
    text = text.replaceAll(
      RegExp(r'<\s*/\s*(p|div|li|h[1-6])\s*>', caseSensitive: false),
      '\n',
    );
    text = text.replaceAll(
      RegExp(r'<\s*(li)\b[^>]*>', caseSensitive: false),
      '• ',
    );
    text = text.replaceAll(
      RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false),
      '',
    );

    // Some payloads contain escaped HTML (&lt;p&gt;...&lt;/p&gt;). Decode once
    // more and strip tags again so both HTML and escaped HTML are supported.
    text = _decodeHtmlEntities(text);
    text = text.replaceAll(
      RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false),
      '\n',
    );
    text = text.replaceAll(
      RegExp(r'<\s*/\s*(p|div|li|h[1-6])\s*>', caseSensitive: false),
      '\n',
    );
    text = text.replaceAll(
      RegExp(r'<\s*(li)\b[^>]*>', caseSensitive: false),
      '• ',
    );
    text = text.replaceAll(
      RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false),
      '',
    );

    text = text
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((line) => line.isNotEmpty)
        .join('\n')
        .trim();

    return text;
  }

  static String _decodeHtmlEntities(String value) {
    return value
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#34;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }

  static String resolveShort({
    String? brief,
    String? descriptionHtml,
    String? description,
    String fallback = '',
  }) {
    final normalizedBrief = parseHtmlToPlainText(brief ?? '');
    if (normalizedBrief.isNotEmpty) return normalizedBrief;

    final normalizedDescription = parseHtmlToPlainText(description ?? '');
    if (normalizedDescription.isNotEmpty) return normalizedDescription;

    final normalizedHtml = parseHtmlToPlainText(descriptionHtml ?? '');
    if (normalizedHtml.isNotEmpty) return normalizedHtml;

    return fallback;
  }

  static String resolveFull({
    String? descriptionHtml,
    String? description,
    String? shortDescription,
    String fallback = '',
  }) {
    final normalizedDescription = parseHtmlToPlainText(description ?? '');
    if (normalizedDescription.isNotEmpty) return normalizedDescription;

    final normalizedHtml = parseHtmlToPlainText(descriptionHtml ?? '');
    if (normalizedHtml.isNotEmpty) return normalizedHtml;

    final normalizedShort = parseHtmlToPlainText(shortDescription ?? '');
    if (normalizedShort.isNotEmpty) return normalizedShort;

    return fallback;
  }
}
