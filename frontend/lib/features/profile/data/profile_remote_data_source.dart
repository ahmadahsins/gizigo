import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'models/profile_history_item.dart';
import 'models/profile_user.dart';

class ProfileRemoteDataSource {
  ProfileRemoteDataSource(this._client);

  final DioClient _client;

  Future<ProfileUser> getProfile() async {
    final response = await _client.get(ApiConstants.usersMe);
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid profile response.');
    }

    return ProfileUser.fromJson(data);
  }

  Future<void> syncUser() async {
    await _client.post(ApiConstants.authSync);
  }

  Future<ProfileUser> updateProfile({
    required String name,
    required String gender,
    required int? age,
    required int? heightCm,
    required int? weightKg,
    List<String>? foodPreferences,
    List<String>? dietaryRestrictions,
    List<String>? tasteProfile,
    String? nutritionGoal,
    String? preferredLanguage,
  }) async {
    await syncUser();

    final response = await _client.patch(
      ApiConstants.usersMe,
      data: {
        'name': name,
        if (ProfileUser.apiGender(gender).isNotEmpty)
          'gender': ProfileUser.apiGender(gender),
        'age': ?age,
        'height_cm': ?heightCm,
        'weight_kg': ?weightKg,
        'food_preferences': ?foodPreferences,
        'dietary_restrictions': ?dietaryRestrictions,
        'taste_profile': ?tasteProfile,
        if (nutritionGoal != null && nutritionGoal.trim().isNotEmpty)
          'nutrition_goal': nutritionGoal.trim(),
        if (preferredLanguage != null && preferredLanguage.trim().isNotEmpty)
          'preferred_language': preferredLanguage.trim(),
      },
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid updated profile response.');
    }

    return ProfileUser.fromJson(data);
  }

  Future<ProfileUser> updatePreferences({
    required List<String> foodPreferences,
    required List<String> dietaryRestrictions,
    required List<String> tasteProfile,
    String? nutritionGoal,
  }) async {
    await syncUser();

    final response = await _client.patch(
      ApiConstants.usersMe,
      data: {
        'food_preferences': foodPreferences,
        'dietary_restrictions': dietaryRestrictions,
        'taste_profile': tasteProfile,
        if (nutritionGoal != null && nutritionGoal.trim().isNotEmpty)
          'nutrition_goal': nutritionGoal.trim(),
      },
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid updated preference response.');
    }

    return ProfileUser.fromJson(data);
  }

  Future<ProfileUser> updateLanguage(String language) async {
    await syncUser();

    final response = await _client.patch(
      ApiConstants.usersMe,
      data: {'preferred_language': language},
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid updated language response.');
    }

    return ProfileUser.fromJson(data);
  }

  Future<ProfileUser> uploadProfilePhoto({
    required List<int> bytes,
    required String filename,
  }) async {
    await syncUser();

    final contentType = _imageContentType(bytes, filename);
    final uploadFilename = _filenameWithImageExtension(filename, contentType);
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: uploadFilename,
        contentType: contentType,
      ),
    });
    final response = await _client.post(
      ApiConstants.usersMePhoto,
      data: formData,
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid updated profile photo response.');
    }

    return ProfileUser.fromJson(data);
  }

  DioMediaType _imageContentType(List<int> bytes, String filename) {
    final filenameContentType = MultipartFile.lookupMediaType(filename);
    if (filenameContentType != null && filenameContentType.type == 'image') {
      return filenameContentType;
    }

    if (_startsWith(bytes, const [0xFF, 0xD8, 0xFF])) {
      return DioMediaType('image', 'jpeg');
    }
    if (_startsWith(bytes, const [0x89, 0x50, 0x4E, 0x47])) {
      return DioMediaType('image', 'png');
    }
    if (_isWebp(bytes)) {
      return DioMediaType('image', 'webp');
    }

    return DioMediaType('image', 'jpeg');
  }

  String _filenameWithImageExtension(
    String filename,
    DioMediaType contentType,
  ) {
    final trimmedFilename = filename.trim();
    final hasKnownExtension = RegExp(
      r'\.(jpe?g|png|webp)$',
      caseSensitive: false,
    ).hasMatch(trimmedFilename);
    if (hasKnownExtension) return trimmedFilename;

    final baseName = trimmedFilename.isEmpty
        ? 'profile-photo'
        : trimmedFilename.replaceAll(RegExp(r'\.[^./\\]+$'), '');
    final extension = switch (contentType.subtype) {
      'png' => 'png',
      'webp' => 'webp',
      _ => 'jpg',
    };

    return '$baseName.$extension';
  }

  bool _startsWith(List<int> bytes, List<int> signature) {
    if (bytes.length < signature.length) return false;

    for (var i = 0; i < signature.length; i++) {
      if (bytes[i] != signature[i]) return false;
    }

    return true;
  }

  bool _isWebp(List<int> bytes) {
    if (bytes.length < 12) return false;

    final hasRiff = _startsWith(bytes, const [0x52, 0x49, 0x46, 0x46]);
    final hasWebp =
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50;

    return hasRiff && hasWebp;
  }

  Future<List<ProfileHistoryItem>> getRecentlyViewed({String? query}) async {
    final response = await _client.get(
      ApiConstants.usersRecentlyViewed,
      queryParameters: {
        'page': 1,
        'limit': 50,
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      },
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) return const [];

    final items = data['items'];
    if (items is! List) return const [];

    return items
        .whereType<Map>()
        .map(
          (item) =>
              ProfileHistoryItem.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
  }
}
