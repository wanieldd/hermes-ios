import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class ApiClient {
  final String baseUrl;
  final String? token;
  final http.Client _client;

  ApiClient({
    required this.baseUrl,
    this.token,
    http.Client? client,
  }) : _client = client ?? http.Client();

  String get _apiBase => '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/api';

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null && token!.isNotEmpty) {
      headers['X-Hermes-Session-Token'] = token!;
    }
    return headers;
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final uri = Uri.parse('$_apiBase$path');
    final response = await _client.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(response.statusCode, response.body);
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$_apiBase$path');
    final response = await _client.post(
      uri,
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(response.statusCode, response.body);
  }

  Future<Map<String, dynamic>> _patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$_apiBase$path');
    final response = await _client.patch(
      uri,
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(response.statusCode, response.body);
  }

  Future<Map<String, dynamic>> _delete(String path) async {
    final uri = Uri.parse('$_apiBase$path');
    final response = await _client.delete(uri, headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(response.statusCode, response.body);
  }

  // -- Status
  Future<StatusResponse> getStatus() async {
    final json = await _get('/status');
    return StatusResponse.fromJson(json);
  }

  // -- Sessions
  Future<SessionListResponse> getSessions({
    int limit = 50,
    int offset = 0,
  }) async {
    final json = await _get('/sessions?limit=$limit&offset=$offset');
    return SessionListResponse.fromJson(json);
  }

  Future<SessionInfo> getSession(String id) async {
    final json = await _get('/sessions/${Uri.encodeComponent(id)}');
    return SessionInfo.fromJson(json);
  }

  Future<List<Message>> getSessionMessages(String id) async {
    final json =
        await _get('/sessions/${Uri.encodeComponent(id)}/messages');
    final messages = (json['messages'] as List<dynamic>?)
            ?.map((e) => Message.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return messages;
  }

  Future<void> deleteSession(String id) async {
    await _delete('/sessions/${Uri.encodeComponent(id)}');
  }

  Future<void> renameSession(String id, String title) async {
    await _patch('/sessions/${Uri.encodeComponent(id)}', body: {'title': title});
  }

  Future<void> archiveSession(String id, bool archived) async {
    await _patch(
      '/sessions/${Uri.encodeComponent(id)}',
      body: {'archived': archived},
    );
  }

  Future<SessionListResponse> searchSessions(String query) async {
    final json =
        await _get('/sessions/search?q=${Uri.encodeComponent(query)}');
    return SessionListResponse.fromJson(json);
  }

  // -- Model
  Future<ModelInfoResponse> getModelInfo() async {
    final json = await _get('/model/info');
    return ModelInfoResponse.fromJson(json);
  }

  Future<void> setModel(String provider, String model) async {
    await _post('/model/set', body: {'provider': provider, 'model': model});
  }

  // -- Skills
  Future<List<SkillInfo>> getSkills() async {
    final json = await _get('/skills');
    final skills = (json['skills'] as List<dynamic>?)
            ?.map((e) => SkillInfo.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return skills;
  }

  // -- Memory
  Future<MemoryStatus> getMemoryStatus() async {
    final json = await _get('/memory');
    return MemoryStatus.fromJson(json);
  }

  // -- Config
  Future<Map<String, dynamic>> getConfig() async {
    return await _get('/config');
  }

  Future<void> updateConfig(Map<String, dynamic> config) async {
    await _patch('/config', body: config);
  }

  // -- Cron
  Future<List<CronJobInfo>> getCronJobs() async {
    final json = await _get('/cron');
    final jobs = (json['jobs'] as List<dynamic>?)
            ?.map((e) => CronJobInfo.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return jobs;
  }

  // -- Webhooks
  Future<List<WebhookInfo>> getWebhooks() async {
    final json = await _get('/webhooks');
    final hooks = (json['webhooks'] as List<dynamic>?)
            ?.map((e) => WebhookInfo.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return hooks;
  }

  // -- WebSocket ticket
  Future<String> getWsTicket() async {
    final json = await _post('/auth/ws-ticket');
    return json['ticket'] as String? ?? '';
  }

  /// Log in with username/password
  Future<Map<String, dynamic>> passwordLogin(String username, String password) async {
    final uri = Uri.parse('$_apiBase/auth/password-login');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// Fetch the session token from the dashboard HTML page
  Future<String> fetchSessionToken() async {
    try {
      final uri = Uri.parse('${baseUrl.replaceAll(RegExp(r'/+$'), '')}/');
      final response = await _client.get(uri);
      if (response.statusCode == 200) {
        final html = response.body;
        final regex = RegExp(r'__HERMES_SESSION_TOKEN__="([^"]+)"');
        final match = regex.firstMatch(html);
        if (match != null) {
          return match.group(1) ?? '';
        }
      }
    } catch (_) {}
    return '';
  }

  void dispose() {
    _client.close();
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;

  ApiException(this.statusCode, this.body);

  @override
  String toString() => 'ApiException($statusCode): $body';
}