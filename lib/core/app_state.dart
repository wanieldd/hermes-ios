import 'dart:async';

import 'package:flutter/foundation.dart';

import 'api/api_client.dart';
import 'api/models.dart';
import 'gateway/gateway_client.dart';
import 'storage/simple_storage.dart';

/// Central app state managed via ChangeNotifier.
class AppState extends ChangeNotifier {
  final SimpleStorage _storage = SimpleStorage();

  ApiClient? _apiClient;
  GatewayClient? _gatewayClient;

  // Connection
  String? _gatewayUrl;
  String? _gatewayToken;
  bool _isConnecting = false;
  String? _connectionError;

  // Status
  StatusResponse? _status;
  ModelInfoResponse? _modelInfo;

  // Sessions
  List<SessionInfo> _sessions = [];
  SessionInfo? _activeSession;
  List<Message> _activeMessages = [];
  bool _isLoadingSessions = false;
  bool _isLoadingMessages = false;

  // Skills
  List<SkillInfo> _skills = [];

  // Memory
  MemoryStatus? _memoryStatus;

  // Currently streaming message content
  String? _streamingContent;
  String? _streamingThinking;
  bool _isStreaming = false;
  StreamSubscription<GatewayEvent>? _eventSubscription;

  // Getters
  ApiClient? get apiClient => _apiClient;
  GatewayClient? get gatewayClient => _gatewayClient;
  String? get gatewayUrl => _gatewayUrl;
  String? get gatewayToken => _gatewayToken;
  bool get isConnecting => _isConnecting;
  String? get connectionError => _connectionError;
  bool get isConnected => _gatewayClient?.isConnected ?? false;
  GatewayConnectionState get connectionState =>
      _gatewayClient?.state ?? GatewayConnectionState.idle;

  StatusResponse? get status => _status;
  ModelInfoResponse? get modelInfo => _modelInfo;

  List<SessionInfo> get sessions => _sessions;
  SessionInfo? get activeSession => _activeSession;
  List<Message> get activeMessages => _activeMessages;
  bool get isLoadingSessions => _isLoadingSessions;
  bool get isLoadingMessages => _isLoadingMessages;

  List<SkillInfo> get skills => _skills;
  MemoryStatus? get memoryStatus => _memoryStatus;

  String? get streamingContent => _streamingContent;
  String? get streamingThinking => _streamingThinking;
  bool get isStreaming => _isStreaming;

  /// Initialize: load saved credentials
  Future<void> init() async {
    await _storage.init();
    _gatewayUrl = await _storage.read('gateway_url');
    _gatewayToken = await _storage.read('gateway_token');

    if (_gatewayUrl != null && _gatewayUrl!.isNotEmpty) {
      _initClients();
    }
  }

  void _initClients() {
    _apiClient?.dispose();
    _gatewayClient?.dispose();
    _eventSubscription?.cancel();

    _apiClient = ApiClient(
      baseUrl: _gatewayUrl!,
      token: _gatewayToken,
    );

    _gatewayClient = GatewayClient();

    _eventSubscription = _gatewayClient!.events.listen(_handleGatewayEvent);
    _gatewayClient!.stateStream.listen((state) {
      notifyListeners();
    });
  }

  /// Connect to the gateway
  Future<bool> connect(String url, {String? token}) async {
    _isConnecting = true;
    _connectionError = null;
    notifyListeners();

    try {
      // Normalize URL
      if (!url.startsWith('http')) {
        url = 'http://$url';
      }
      final uri = Uri.parse(url);
      _gatewayUrl = '${uri.scheme}://${uri.host}:${uri.port}';
      _gatewayToken = token ?? '';

      await _storage.save('gateway_url', _gatewayUrl!);
      if (_gatewayToken!.isNotEmpty) {
        await _storage.save('gateway_token', _gatewayToken!);
      }

      _initClients();

      // Test REST connection
      _status = await _apiClient!.getStatus();

      // Connect WebSocket
      await _gatewayClient!.connect(_gatewayUrl!, token: _gatewayToken);

      // Load initial data
      _loadInitialData();

      _isConnecting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isConnecting = false;
      _connectionError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Disconnect
  Future<void> disconnect() async {
    await _gatewayClient?.disconnect();
    _apiClient?.dispose();
    _apiClient = null;
    _gatewayClient = null;
    _status = null;
    _sessions = [];
    _activeSession = null;
    _activeMessages = [];
    _skills = [];
    _memoryStatus = null;
    _streamingContent = null;
    _streamingThinking = null;
    _isStreaming = false;
    notifyListeners();
  }

  /// Clear saved credentials and disconnect
  Future<void> clearCredentials() async {
    await disconnect();
    await _storage.clearAll();
    _gatewayUrl = null;
    _gatewayToken = null;
    notifyListeners();
  }

  Future<void> _loadInitialData() async {
    try {
      _sessions = (await _apiClient!.getSessions(limit: 50)).sessions;
    } catch (_) {}
    try {
      _modelInfo = await _apiClient!.getModelInfo();
    } catch (_) {}
    try {
      _skills = await _apiClient!.getSkills();
    } catch (_) {}
    try {
      _memoryStatus = await _apiClient!.getMemoryStatus();
    } catch (_) {}
    notifyListeners();
  }

  /// Load sessions
  Future<void> loadSessions() async {
    _isLoadingSessions = true;
    notifyListeners();
    try {
      _sessions = (await _apiClient!.getSessions(limit: 50)).sessions;
    } catch (_) {}
    _isLoadingSessions = false;
    notifyListeners();
  }

  /// Select a session and load its messages
  Future<void> selectSession(String id) async {
    _isLoadingMessages = true;
    notifyListeners();

    try {
      _activeSession = await _apiClient!.getSession(id);
      _activeMessages = await _apiClient!.getSessionMessages(id);
    } catch (_) {}
    _isLoadingMessages = false;
    notifyListeners();
  }

  /// Create a new session
  Future<String?> createSession({String? title}) async {
    try {
      final result = await _gatewayClient!.createSession(title: title);
      final sessionId = result['session_id'] as String?;
      if (sessionId != null) {
        await selectSession(sessionId);
        await loadSessions();
      }
      return sessionId;
    } catch (e) {
      return null;
    }
  }

  /// Delete a session
  Future<void> deleteSession(String id) async {
    try {
      await _apiClient!.deleteSession(id);
      if (_activeSession?.id == id) {
        _activeSession = null;
        _activeMessages = [];
      }
      await loadSessions();
    } catch (_) {}
  }

  /// Rename a session
  Future<void> renameSession(String id, String title) async {
    try {
      await _apiClient!.renameSession(id, title);
      await loadSessions();
      if (_activeSession?.id == id) {
        _activeSession = await _apiClient!.getSession(id);
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Send a prompt
  Future<void> sendPrompt(String text) async {
    if (_activeSession == null || _gatewayClient == null) return;

    _isStreaming = true;
    _streamingContent = '';
    _streamingThinking = '';
    notifyListeners();

    try {
      await _gatewayClient!.submitPrompt(_activeSession!.id, text);
    } catch (e) {
      _isStreaming = false;
      _streamingContent = null;
      _streamingThinking = null;
      notifyListeners();
    }
  }

  void _handleGatewayEvent(GatewayEvent event) {
    switch (event.type) {
      case GatewayEventType.messageDelta:
        final text = event.payload?['text'] as String? ?? '';
        _streamingContent = (_streamingContent ?? '') + text;
        notifyListeners();
        break;

      case GatewayEventType.messageComplete:
        _isStreaming = false;
        _streamingContent = null;
        _streamingThinking = null;
        // Reload messages to get the full message
        if (_activeSession != null) {
          _apiClient!
              .getSessionMessages(_activeSession!.id)
              .then((msgs) {
            _activeMessages = msgs;
            notifyListeners();
          });
        }
        notifyListeners();
        break;

      case GatewayEventType.thinkingDelta:
        final text = event.payload?['text'] as String? ?? '';
        _streamingThinking = (_streamingThinking ?? '') + text;
        notifyListeners();
        break;

      case GatewayEventType.toolStart:
        notifyListeners();
        break;

      case GatewayEventType.toolComplete:
        notifyListeners();
        break;

      case GatewayEventType.sessionInfo:
        // Session info changed, reload
        loadSessions();
        break;

      case GatewayEventType.statusUpdate:
        // Refresh status
        _apiClient?.getStatus().then((s) {
          _status = s;
          notifyListeners();
        });
        break;

      case GatewayEventType.error:
        _isStreaming = false;
        notifyListeners();
        break;

      default:
        break;
    }
  }

  /// Set the model
  Future<void> setModel(String provider, String model) async {
    try {
      await _apiClient!.setModel(provider, model);
      _modelInfo = await _apiClient!.getModelInfo();
      notifyListeners();
    } catch (_) {}
  }

  /// Refresh the API client (e.g., after token change)
  void refreshApiClient() {
    if (_gatewayUrl != null) {
      _apiClient = ApiClient(
        baseUrl: _gatewayUrl!,
        token: _gatewayToken,
      );
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _gatewayClient?.dispose();
    _apiClient?.dispose();
    super.dispose();
  }
}