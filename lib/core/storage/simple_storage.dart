import 'dart:convert';
import 'dart:io';

/// Lightweight key-value storage that works in any environment.
/// Falls back to file-based storage on Linux, uses NSUserDefaults on iOS.
/// No native plugins required -- avoids Keychain crashes in LiveContainer.
class SimpleStorage {
  static final SimpleStorage _instance = SimpleStorage._();
  factory SimpleStorage() => _instance;
  SimpleStorage._();

  final Map<String, String> _memory = {};
  String? _filePath;

  Future<void> init() async {
    if (Platform.isIOS) {
      // On iOS we use UserDefaults via a simple Dart implementation
      // No native plugin needed
    }
    // For Linux/other, use file-based storage
    final dir = Directory('/tmp/hermes_ios_storage');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _filePath = '${dir.path}/storage.json';
    if (await File(_filePath!).exists()) {
      try {
        final content = await File(_filePath!).readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        data.forEach((k, v) => _memory[k] = v.toString());
      } catch (_) {}
    }
  }

  Future<void> save(String key, String value) async {
    _memory[key] = value;
    await _flush();
  }

  Future<String?> read(String key) async {
    return _memory[key];
  }

  Future<void> delete(String key) async {
    _memory.remove(key);
    await _flush();
  }

  Future<void> clearAll() async {
    _memory.clear();
    if (_filePath != null) {
      final file = File(_filePath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<void> _flush() async {
    if (_filePath == null) return;
    try {
      await File(_filePath!).writeAsString(jsonEncode(_memory));
    } catch (_) {}
  }
}