import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'models/food_detail.dart';

class FoodRemoteDataSource {
  FoodRemoteDataSource(this._client);

  final DioClient _client;

  Future<FoodDetail> getFoodDetail(String foodId) async {
    final response = await _client.get(ApiConstants.foodDetails(foodId));
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid food detail response.');
    }

    return FoodDetail.fromJson(data);
  }

  Future<void> recordRecentlyViewed(String foodId) {
    return _client.post(
      ApiConstants.usersRecentlyViewed,
      data: {'food_id': foodId},
    );
  }
}
