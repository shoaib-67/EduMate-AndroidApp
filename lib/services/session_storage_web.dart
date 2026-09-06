import 'dart:html' as html;

class SessionStorage {
  const SessionStorage();

  String _key(String key) => 'edumate_$key';

  Future<String?> read({required String key}) async =>
      html.window.sessionStorage[_key(key)];

  Future<void> write({required String key, required String value}) async {
    html.window.sessionStorage[_key(key)] = value;
  }

  Future<void> delete({required String key}) async {
    html.window.sessionStorage.remove(_key(key));
  }

  Future<void> deleteAll() async {
    final keys = html.window.sessionStorage.keys
        .where((key) => key.startsWith('edumate_'))
        .toList();
    for (final key in keys) {
      html.window.sessionStorage.remove(key);
    }
  }
}
