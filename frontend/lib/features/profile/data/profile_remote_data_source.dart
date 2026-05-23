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
      },
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid updated profile response.');
    }

    return ProfileUser.fromJson(data);
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
