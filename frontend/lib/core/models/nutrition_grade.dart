enum NutritionGrade {
  good,
  veryGood,
  excellent;

  static NutritionGrade? tryParse(String value) {
    final normalizedValue = value
        .trim()
        .toUpperCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');

    return switch (normalizedValue) {
      'GOOD' => NutritionGrade.good,
      'VERY_GOOD' || 'VERYGOOD' => NutritionGrade.veryGood,
      'EXCELLENT' => NutritionGrade.excellent,
      _ => null,
    };
  }

  static String labelFor(String value) {
    final grade = tryParse(value);
    if (grade != null) return grade.label;

    final trimmedValue = value.trim();
    return trimmedValue.isEmpty ? NutritionGrade.good.label : trimmedValue;
  }

  String get label {
    return switch (this) {
      NutritionGrade.good => 'Good',
      NutritionGrade.veryGood => 'Very Good',
      NutritionGrade.excellent => 'Excellent',
    };
  }

  String get description {
    return switch (this) {
      NutritionGrade.good =>
        'Pilihan yang cukup baik untuk dikonsumsi sehari-hari dengan nutrisi yang cukup seimbang.',
      NutritionGrade.veryGood =>
        'Memiliki kandungan gizi yang lebih seimbang dengan gula, lemak, dan sodium yang lebih terkontrol.',
      NutritionGrade.excellent =>
        'Pilihan paling sehat dengan nutrisi tinggi dan komposisi yang lebih baik untuk tubuh.',
    };
  }
}
