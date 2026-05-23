class ProfileUser {
  const ProfileUser({
    required this.name,
    required this.username,
    required this.email,
    required this.gender,
    required this.age,
    required this.heightCm,
    required this.weightKg,
  });

  final String name;
  final String username;
  final String email;
  final String gender;
  final int? age;
  final int? heightCm;
  final int? weightKg;

  factory ProfileUser.fromJson(Map<String, dynamic> json) {
    return ProfileUser(
      name: _asString(json['name']),
      username: _asString(json['username']),
      email: _asString(json['email']),
      gender: _genderLabel(_asString(json['gender'])),
      age: _asInt(json['age']),
      heightCm: _asInt(json['height_cm']),
      weightKg: _asInt(json['weight_kg']),
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

  static String _asString(Object? value) {
    return value?.toString().trim() ?? '';
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '');
  }
}
