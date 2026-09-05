import '../config/api_config.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api;

  AuthService(this._api);

  Future<AuthResult> currentUser() async {
    // Prevent the browser from reusing an older profile response after a
    // hard reload. The session must always be reconciled with the database.
    final response = await _api.get(
      ApiConfig.currentUser,
      queryParams: {'_refresh': DateTime.now().millisecondsSinceEpoch.toString()},
    );
    if (response.success && response.data is Map) {
      final data = response.data as Map<String, dynamic>;
      final userData = data['user'] as Map<String, dynamic>?;
      if (userData != null) {
        return AuthResult(success: true, user: User.fromJson(userData));
      }
    }
    return AuthResult(
      success: false,
      statusCode: response.statusCode,
      message: _friendlyMessage(response.statusCode),
    );
  }

  Future<AuthResult> login(String email, String password) async {
    final response = await _api.post(
      ApiConfig.login,
      body: {'email': email, 'password': password},
    );

    if (response.success && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String?;
      final userData = data['user'] as Map<String, dynamic>?;

      if (token != null && userData != null) {
        _api.setToken(token);
        return AuthResult(
          success: true,
          user: User.fromJson(userData),
          token: token,
          message: response.message,
        );
      }
    }

    return AuthResult(
      success: false,
      statusCode: response.statusCode,
      message: _friendlyMessage(
        response.statusCode,
        fallback: 'লগইন ব্যর্থ হয়েছে',
      ),
    );
  }

  Future<AuthResult> signup({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? institution,
  }) async {
    final response = await _api.post(
      ApiConfig.signup,
      body: {
        'name': name,
        'email': email,
        'password': password,
        if (phone != null) 'phone': phone, // ignore: use_null_aware_elements
        if (institution != null) // ignore: use_null_aware_elements
          'institution': institution, // ignore: use_null_aware_elements
      },
    );

    if (response.success && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String?;
      final userData = data['user'] as Map<String, dynamic>?;

      if (token != null && userData != null) {
        _api.setToken(token);
        return AuthResult(
          success: true,
          user: User.fromJson(userData),
          token: token,
          message: response.message,
        );
      }
    }

    return AuthResult(
      success: false,
      statusCode: response.statusCode,
      message: response.statusCode == 409
          ? 'এই ইমেইল বা ফোন নম্বর আগে ব্যবহার করা হয়েছে'
          : _friendlyMessage(
              response.statusCode,
              fallback: 'রেজিস্ট্রেশন ব্যর্থ হয়েছে',
            ),
    );
  }

  String _friendlyMessage(
    int statusCode, {
    String fallback = 'অনুরোধ ব্যর্থ হয়েছে',
  }) {
    switch (statusCode) {
      case 0:
        return 'সার্ভারে সংযোগ করা যাচ্ছে না। ইন্টারনেট বা backend চালু আছে কি না দেখুন।';
      case 401:
        return 'ইমেইল বা পাসওয়ার্ড সঠিক নয়';
      case 404:
        return 'অ্যাকাউন্ট পাওয়া যায়নি';
      case 409:
        return 'এই তথ্য আগে ব্যবহার করা হয়েছে';
      case 503:
        return 'ডাটাবেস এখন unavailable। পরে আবার চেষ্টা করুন।';
      default:
        return fallback;
    }
  }

  Future<void> logout() async {
    await _api.post(ApiConfig.logout);
    _api.clearToken();
  }
}

class AuthResult {
  final bool success;
  final User? user;
  final String? token;
  final String? message;
  final int statusCode;

  AuthResult({
    required this.success,
    this.user,
    this.token,
    this.message,
    this.statusCode = 0,
  });
}
