class ProfileUser {
  const ProfileUser({
    required this.name,
    required this.username,
    required this.email,
    required this.role,
    required this.merchantId,
    required this.gender,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.profilePhotoUrl,
    required this.nutritionGoal,
    required this.foodPreferences,
    required this.dietaryRestrictions,
    required this.tasteProfile,
    required this.preferredLanguage,
  });

  final String name;
  final String username;
  final String email;
  final String role;
  final String merchantId;
  final String gender;
  final int? age;
  final int? heightCm;
  final int? weightKg;
  final String profilePhotoUrl;
  final String nutritionGoal;
  final List<String> foodPreferences;
  final List<String> dietaryRestrictions;
  final List<String> tasteProfile;
  final String preferredLanguage;

  bool get isCustomer => role == 'customer';
  bool get isMerchant => role == 'merchant';
  bool get isAdmin => role == 'admin';

  factory ProfileUser.fromJson(Map<String, dynamic> json) {
    return ProfileUser(
      name: _asString(json['name']),
      username: _asString(json['username']),
      email: _asString(json['email']),
      role: _roleValue(json['role']),
      merchantId: _asString(json['merchant_id']),
      gender: _genderLabel(_asString(json['gender'])),
      age: _asInt(json['age']),
      heightCm: _asInt(json['height_cm']),
      weightKg: _asInt(json['weight_kg']),
      profilePhotoUrl: _asString(json['profile_photo_url']),
      nutritionGoal: _asString(json['nutrition_goal']),
      foodPreferences: _asStringList(json['food_preferences']),
      dietaryRestrictions: _asStringList(json['dietary_restrictions']),
      tasteProfile: _asStringList(json['taste_profile']),
      preferredLanguage: _asString(json['preferred_language']),
    );
  }

  static String apiGender(String label) {
    return switch (label.trim().toLowerCase()) {
      'male' => 'MALE',
      'female' => 'FEMALE',
      _ => '',
    };
  }

  static String _genderLabel(String value) {
    return switch (value.trim().toUpperCase()) {
      'MALE' => 'Male',
      'FEMALE' => 'Female',
      _ => '',
    };
  }

  static String _roleValue(Object? value) {
    return switch (_asString(value).toLowerCase()) {
      'merchant' => 'merchant',
      'admin' => 'admin',
      _ => 'customer',
    };
  }

  static String _asString(Object? value) {
    return value?.toString().trim() ?? '';
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '');
  }

  static List<String> _asStringList(Object? value) {
    if (value is! List) return const [];

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}
