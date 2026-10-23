class VariantSelectionSnapshot {
  const VariantSelectionSnapshot({
    required this.attributes,
    required this.isInStock,
  });

  final Map<String, String> attributes;
  final bool isInStock;
}

class VariantSelectionRules {
  static String normalizeAttributeName(String raw) {
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

  static String normalizeOptionValue(String raw) {
    return raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  static Map<String, String> normalizeAttributeMap(
    Map<String, String> attributes,
  ) {
    final normalized = <String, String>{};
    for (final entry in attributes.entries) {
      final key = normalizeAttributeName(entry.key);
      final value = normalizeOptionValue(entry.value);
      if (key.isEmpty || value.isEmpty) continue;
      normalized[key] = value;
    }
    return normalized;
  }

  static bool isColorAttributeName(String raw) {
    final normalized = normalizeAttributeName(raw);
    return normalized == 'color' ||
        normalized.contains('color') ||
        normalized.contains('colour') ||
        normalized.contains('spec');
  }

  static String? findColorAttributeName(Iterable<String> attributeNames) {
    for (final attrName in attributeNames) {
      if (isColorAttributeName(attrName)) {
        return attrName.trim();
      }
    }
    return null;
  }

  static Map<String, Set<String>> availableAttributesFromVariants(
    Iterable<VariantSelectionSnapshot> variants,
  ) {
    final attributes = <String, Set<String>>{};
    for (final variant in variants) {
      if (!variant.isInStock) continue;
      for (final entry in variant.attributes.entries) {
        final key = entry.key.trim();
        final value = entry.value.trim();
        if (key.isEmpty || value.isEmpty) continue;
        attributes.putIfAbsent(key, () => <String>{}).add(value);
      }
    }
    return attributes;
  }

  static bool matchesExactAttributes({
    required Map<String, String> selectedAttributes,
    required Map<String, String> variantAttributes,
  }) {
    if (selectedAttributes.isEmpty || variantAttributes.isEmpty) return false;

    final allSelectedMatch = variantAttributes.entries.every(
      (entry) => selectedAttributes[entry.key] == entry.value,
    );
    final noExtraAttributes = selectedAttributes.keys
        .toSet()
        .difference(variantAttributes.keys.toSet())
        .isEmpty;
    return allSelectedMatch && noExtraAttributes;
  }

  static bool matchesRequiredAttributes({
    required Map<String, String> requiredAttributes,
    required Map<String, String> variantAttributes,
  }) {
    if (requiredAttributes.isEmpty || variantAttributes.isEmpty) return false;
    return requiredAttributes.entries.every(
      (entry) => variantAttributes[entry.key] == entry.value,
    );
  }

  static bool hasMatchingVariant(
    Iterable<VariantSelectionSnapshot> variants,
    Map<String, String> selectedAttributes,
  ) {
    final selected = normalizeAttributeMap(selectedAttributes);
    if (selected.isEmpty) return false;

    for (final variant in variants) {
      if (!variant.isInStock) continue;
      if (matchesExactAttributes(
        selectedAttributes: selected,
        variantAttributes: variant.attributes,
      )) {
        return true;
      }
    }
    return false;
  }

  static bool isOptionAvailable({
    required Iterable<VariantSelectionSnapshot> variants,
    required Map<String, String> selectedAttributes,
    required String attrName,
    required String optionValue,
    required String? colorAttributeName,
  }) {
    final tempAttributes = Map<String, String>.from(selectedAttributes)
      ..[attrName] = optionValue;
    final normalizedTemp = normalizeAttributeMap(tempAttributes);
    final isColorSelection = isColorAttributeName(attrName);
    final normalizedColorAttributeName = colorAttributeName == null
        ? null
        : normalizeAttributeName(colorAttributeName);

    final criteria = <String, String>{...normalizedTemp};
    if (!isColorSelection &&
        normalizedColorAttributeName != null &&
        normalizedColorAttributeName.isNotEmpty) {
      criteria.remove(normalizedColorAttributeName);
    }

    for (final variant in variants) {
      if (!variant.isInStock) continue;
      if (matchesRequiredAttributes(
        requiredAttributes: criteria,
        variantAttributes: variant.attributes,
      )) {
        return true;
      }
    }
    return false;
  }

  static List<String> availableValuesForOption({
    required Iterable<VariantSelectionSnapshot> variants,
    required String optionName,
    required Iterable<String> optionValues,
  }) {
    final normalizedOptionName = normalizeAttributeName(optionName);
    if (normalizedOptionName.isEmpty) return const <String>[];

    final seen = <String>{};
    final values = <String>[];
    for (final rawValue in optionValues) {
      final value = rawValue.trim();
      final normalizedValue = normalizeOptionValue(value);
      if (normalizedValue.isEmpty || !seen.add(normalizedValue)) continue;

      final exists = variants.any(
        (variant) =>
            variant.isInStock &&
            variant.attributes[normalizedOptionName] == normalizedValue,
      );
      if (exists) {
        values.add(value);
      }
    }
    return values;
  }

  static List<String> availableColorOptionsForCurrentSelection({
    required Iterable<VariantSelectionSnapshot> variants,
    required Map<String, String> selectedAttributes,
    required String changedAttributeName,
    required String colorAttributeName,
    required Iterable<String> candidateValues,
  }) {
    final normalizedColorName = normalizeAttributeName(colorAttributeName);
    if (normalizedColorName.isEmpty) return const <String>[];

    final normalizedChangedName = normalizeAttributeName(changedAttributeName);
    final selected = normalizeAttributeMap(selectedAttributes);
    final requiredAttributes = <String, String>{...selected}
      ..remove(normalizedColorName);
    if (normalizedChangedName.isNotEmpty &&
        selected[normalizedChangedName] != null) {
      requiredAttributes[normalizedChangedName] =
          selected[normalizedChangedName]!;
    }

    final colors = <String>[];
    final seen = <String>{};
    for (final rawValue in candidateValues) {
      final colorValue = rawValue.trim();
      final normalizedColor = normalizeOptionValue(colorValue);
      if (normalizedColor.isEmpty || !seen.add(normalizedColor)) continue;

      final matches = variants.any(
        (variant) =>
            variant.isInStock &&
            matchesRequiredAttributes(
              requiredAttributes: requiredAttributes,
              variantAttributes: variant.attributes,
            ) &&
            variant.attributes[normalizedColorName] == normalizedColor,
      );
      if (matches) {
        colors.add(colorValue);
      }
    }
    return colors;
  }

  static VariantSelectionSnapshot? findFallbackVariantForNonColorSelection({
    required Iterable<VariantSelectionSnapshot> variants,
    required Map<String, String> selectedAttributes,
    required String changedAttributeName,
    required String colorAttributeName,
  }) {
    final normalizedColorName = normalizeAttributeName(colorAttributeName);
    if (normalizedColorName.isEmpty) return null;

    final normalizedChangedName = normalizeAttributeName(changedAttributeName);
    final selected = normalizeAttributeMap(selectedAttributes);
    final requiredAttributes = <String, String>{...selected}
      ..remove(normalizedColorName);
    if (normalizedChangedName.isNotEmpty &&
        selected[normalizedChangedName] != null) {
      requiredAttributes[normalizedChangedName] =
          selected[normalizedChangedName]!;
    }

    for (final variant in variants) {
      if (!variant.isInStock) continue;
      if (!matchesRequiredAttributes(
        requiredAttributes: requiredAttributes,
        variantAttributes: variant.attributes,
      )) {
        continue;
      }

      if (variant.attributes.containsKey(normalizedColorName)) {
        return variant;
      }
    }
    return null;
  }
}
