import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/api_config.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;
  late final AuthService _authService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  User? _user;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  AuthProvider(this._apiService) {
    _authService = AuthService(_apiService);
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  String get userRole => _user?.role ?? '';

  Future<void> initialize() async {
    final token = await _storage.read(key: 'auth_token');
    final role = await _storage.read(key: 'user_role');
    final name = await _storage.read(key: 'user_name');
    final email = await _storage.read(key: 'user_email');
    final userId = await _storage.read(key: 'user_id');
    final phone = await _storage.read(key: 'user_phone');
    final institution = await _storage.read(key: 'user_institution');
    final avatar = await _storage.read(key: 'user_avatar');

    if (token != null && role != null && name != null && email != null) {
      _apiService.setToken(token);
      _user = User(
        id: userId != null ? int.tryParse(userId) : null,
        name: name,
        email: email,
        role: role,
        phone: phone,
        institution: institution,
        avatar: avatar,
      );

      // The API may still be waking up after a browser hard reload. Retry the
      // server refresh so the cached profile is not left stale.
      var session = await _authService.currentUser();
      if (!session.success && session.statusCode == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        session = await _authService.currentUser();
      }
      if (session.success && session.user != null) {
        _user = session.user;
        await _saveSession(token, session.user!);
      } else if (session.statusCode == 401) {
        _user = null;
        _apiService.clearToken();
        await _storage.deleteAll();
      }
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.login(email, password);
      if (result.success && result.user != null && result.token != null) {
        _user = result.user;
        await _saveSession(result.token!, result.user!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'সংযোগ ত্রুটি হয়েছে';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? institution,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.signup(
        name: name,
        email: email,
        password: password,
        phone: phone,
        institution: institution,
      );
      if (result.success && result.user != null && result.token != null) {
        _user = result.user;
        await _saveSession(result.token!, result.user!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'সংযোগ ত্রুটি হয়েছে';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    unawaited(_authService.logout().catchError((_) {}));
    _apiService.clearToken();
    _user = null;
    await _storage.deleteAll();
    notifyListeners();
  }

  Future<void> _saveSession(String token, User user) async {
    await _storage.write(key: 'auth_token', value: token);
    await _storage.write(key: 'user_role', value: user.role);
    await _storage.write(key: 'user_name', value: user.name);
    await _storage.write(key: 'user_email', value: user.email);
    await _writeOrDelete('user_phone', user.phone);
    await _writeOrDelete('user_institution', user.institution);
    await _writeOrDelete('user_avatar', user.avatar);
    if (user.id != null) {
      await _storage.write(key: 'user_id', value: user.id.toString());
    }
  }

  Future<void> _writeOrDelete(String key, String? value) async {
    if (value == null || value.isEmpty) {
      await _storage.delete(key: key);
    } else {
      await _storage.write(key: key, value: value);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> updateUser(User user) async {
    _user = user;
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      await _saveSession(token, user);
    }
    notifyListeners();
  }

  Future<ApiResponse> updateProfile({
    required String name,
    String? phone,
    String? institution,
  }) async {
    final response = await _apiService.put(
      ApiConfig.profile,
      body: {
        'name': name,
        'phone': phone ?? '',
        'institution': institution ?? '',
      },
    );
    if (response.success && response.data is Map) {
      final data = response.data as Map<String, dynamic>;
      final userData = data['user'] as Map<String, dynamic>?;
      if (userData != null) {
        await updateUser(User.fromJson(userData));
      }
    }
    return response;
  }
}
