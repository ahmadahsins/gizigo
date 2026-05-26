import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../router/app_router.dart';

class AuthRoleRouter {
  const AuthRoleRouter._();

  static Future<String> routeNameForCurrentUser({DioClient? client}) async {
    try {
      final response = await (client ?? DioClient()).post(
        ApiConstants.authSync,
      );

      return routeNameForRole(_roleFrom(response.data));
    } catch (_) {
      return AppRouter.home;
    }
  }

  static String routeNameForRole(String role) {
    return switch (role) {
      'admin' => AppRouter.adminHome,
      'merchant' => AppRouter.merchantHome,
      _ => AppRouter.home,
    };
  }

  static String _roleFrom(Object? data) {
    if (data is! Map) return 'customer';

    return data['role']?.toString().trim().toLowerCase() ?? 'customer';
  }
}
