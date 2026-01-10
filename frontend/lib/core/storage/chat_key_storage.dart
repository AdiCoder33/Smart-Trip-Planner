import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ChatKey {
  final String key;
  final int version;

  const ChatKey({required this.key, required this.version});
}

class ChatKeyStorage {
  final FlutterSecureStorage storage;

  const ChatKeyStorage(this.storage);

  Future<ChatKey?> getKey(String tripId) async {
    final key = await storage.read(key: _keyKey(tripId));
    if (key == null || key.isEmpty) {
      return null;
    }
    final versionRaw = await storage.read(key: _versionKey(tripId));
    final version = int.tryParse(versionRaw ?? '') ?? 1;
    return ChatKey(key: key, version: version);
  }

  Future<void> saveKey(String tripId, String key, int version) async {
    await storage.write(key: _keyKey(tripId), value: key);
    await storage.write(key: _versionKey(tripId), value: version.toString());
  }

  Future<void> clearKey(String tripId) async {
    await storage.delete(key: _keyKey(tripId));
    await storage.delete(key: _versionKey(tripId));
  }

  String _keyKey(String tripId) => 'chat_key_$tripId';

  String _versionKey(String tripId) => 'chat_key_version_$tripId';
}
