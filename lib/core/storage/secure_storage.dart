import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static final SecureStorage _instance = SecureStorage._();
  factory SecureStorage() => _instance;
  SecureStorage._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyGatewayUrl = 'gateway_url';
  static const _keyGatewayToken = 'gateway_token';
  static const _keyProfileName = 'profile_name';

  Future<void> saveGatewayUrl(String url) =>
      _storage.write(key: _keyGatewayUrl, value: url);

  Future<String?> getGatewayUrl() => _storage.read(key: _keyGatewayUrl);

  Future<void> saveGatewayToken(String token) =>
      _storage.write(key: _keyGatewayToken, value: token);

  Future<String?> getGatewayToken() => _storage.read(key: _keyGatewayToken);

  Future<void> saveProfileName(String name) =>
      _storage.write(key: _keyProfileName, value: name);

  Future<String?> getProfileName() => _storage.read(key: _keyProfileName);

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}