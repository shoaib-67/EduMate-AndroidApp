import 'package:web/web.dart' as web;

class SessionStorage {
  const SessionStorage();

  String _key(String key) => 'edumate_$key';

  Future<String?> read({required String key}) async =>
      web.window.sessionStorage.getItem(_key(key));

  Future<void> write({required String key, required String value}) async {
    web.window.sessionStorage.setItem(_key(key), value);
  }

  Future<void> delete({required String key}) async {
    web.window.sessionStorage.removeItem(_key(key));
  }

  Future<void> deleteAll() async {
    final storage = web.window.sessionStorage;
    final keys = [
      for (var index = 0; index < storage.length; index++)
        if (storage.key(index) case final key? when key.startsWith('edumate_'))
          key,
    ];
    for (final key in keys) {
      storage.removeItem(key);
    }
  }
}
