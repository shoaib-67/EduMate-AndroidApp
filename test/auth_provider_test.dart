import 'package:edumate/providers/auth_provider.dart';
import 'package:edumate/services/api_service.dart';
import 'package:edumate/services/session_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _UnavailableStorage implements SessionStorage {
  @override
  Future<String?> read({required String key}) async =>
      throw StateError('storage unavailable');

  @override
  Future<void> write({required String key, required String value}) async =>
      throw StateError('storage unavailable');

  @override
  Future<void> delete({required String key}) async =>
      throw StateError('storage unavailable');

  @override
  Future<void> deleteAll() async => throw StateError('storage unavailable');
}

void main() {
  test('unavailable session storage does not trap the app on splash', () async {
    final api = ApiService();
    addTearDown(api.dispose);
    final auth = AuthProvider(api, storage: _UnavailableStorage());
    addTearDown(auth.dispose);

    await auth.initialize();

    expect(auth.isInitialized, isTrue);
    expect(auth.isLoggedIn, isFalse);
  });
}
