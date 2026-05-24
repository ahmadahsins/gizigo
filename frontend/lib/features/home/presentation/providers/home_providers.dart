import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/home_remote_data_source.dart';
import '../../data/models/home_category.dart';
import '../../data/models/home_data.dart';
import '../../data/repositories/home_repository.dart';
import '../../../location/data/location_remote_data_source.dart';
import '../../../location/data/location_storage_service.dart';
import '../../../location/domain/entities/location_item.dart';

class HomeRequest {
  const HomeRequest({this.lat, this.lng});

  final double? lat;
  final double? lng;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HomeRequest && other.lat == lat && other.lng == lng;
  }

  @override
  int get hashCode => Object.hash(lat, lng);
}

class HomeUserProfile {
  const HomeUserProfile({
    required this.displayName,
    required this.profilePhotoUrl,
  });

  final String displayName;
  final String profilePhotoUrl;
}

final dioClientProvider = Provider<DioClient>((ref) => DioClient());

final locationStorageServiceProvider = Provider<LocationStorageService>((ref) {
  return const LocationStorageService();
});

final locationRemoteDataSourceProvider = Provider<LocationRemoteDataSource>((
  ref,
) {
  return LocationRemoteDataSource(ref.watch(dioClientProvider));
});

final homeRemoteDataSourceProvider = Provider<HomeRemoteDataSource>((ref) {
  return HomeRemoteDataSource(ref.watch(dioClientProvider));
});

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(ref.watch(homeRemoteDataSourceProvider));
});

final homeCategoriesProvider = Provider<List<HomeCategory>>((ref) {
  return ref.watch(homeRepositoryProvider).localCategories;
});

final selectedLocationProvider = FutureProvider.autoDispose<LocationItem?>((
  ref,
) async {
  final storage = ref.watch(locationStorageServiceProvider);
  final cachedLocation = await storage.readSelectedLocation();
  if (cachedLocation != null) return cachedLocation;

  try {
    final locations = await ref
        .watch(locationRemoteDataSourceProvider)
        .getRecentLocations();
    final latestLocation = locations.firstOrNull;
    if (latestLocation != null) {
      await storage.saveSelectedLocation(latestLocation);
    }

    return latestLocation;
  } catch (_) {
    return null;
  }
});

final homeUserProfileProvider = FutureProvider.autoDispose<HomeUserProfile>((
  ref,
) async {
  final fallbackProfile = _firebaseUserProfile();

  try {
    final response = await ref
        .watch(dioClientProvider)
        .get(ApiConstants.usersMe);
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return HomeUserProfile(
        displayName: _firstPresentName([
          data['name'],
          data['username'],
          data['email'],
          fallbackProfile.displayName,
        ]),
        profilePhotoUrl: _firstPresentText([
          data['profile_photo_url'],
          fallbackProfile.profilePhotoUrl,
        ]),
      );
    }
  } catch (_) {}

  return fallbackProfile;
});

final homeUserNameProvider = FutureProvider.autoDispose<String>((ref) async {
  final profile = await ref.watch(homeUserProfileProvider.future);

  return profile.displayName;
});

final homeDataProvider = FutureProvider.autoDispose
    .family<HomeData, HomeRequest>((ref, request) {
      return ref
          .watch(homeRepositoryProvider)
          .getHomeData(lat: request.lat, lng: request.lng);
    });

HomeUserProfile _firebaseUserProfile() {
  final user = FirebaseAuth.instance.currentUser;

  return HomeUserProfile(
    displayName: _firstPresentName([user?.displayName, user?.email, 'there']),
    profilePhotoUrl: _firstPresentText([user?.photoURL]),
  );
}

String _firstPresentName(List<Object?> values) {
  for (final value in values) {
    final name = _cleanName(value);
    if (name.isNotEmpty) return name;
  }

  return 'there';
}

String _firstPresentText(List<Object?> values) {
  for (final value in values) {
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty) return text;
  }

  return '';
}

String _cleanName(Object? value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return '';

  final emailName = text.contains('@') ? text.split('@').first : text;
  return emailName.trim().isEmpty ? '' : emailName.trim();
}
