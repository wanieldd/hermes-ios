import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../api/models.dart';

/// JSON-RPC WebSocket client using dart:io WebSocket directly.
class GatewayClient {
  WebSocket? _ws;
  StreamSubscription<dynamic>? _subscription;
  GatewayConnectionState _state = GatewayConnectionState.idle;
  int _nextId = 0;
  final Map<String, Completer<Map<String, dynamic>>> _pending = {};
  final StreamController<GatewayEvent> _eventController =
      StreamController<GatewayEvent>.broadcast();
  final StreamController<GatewayConnectionState> _stateController =
      StreamController<GatewayConnectionState>.broadcast();

  Timer? _reconnectTimer;
  String? _lastUrl;
  String? _lastToken;
  bool _intentionalClose = false;
  int _reconnectAttempts = 0;

  Stream<GatewayEvent> get events => _eventController.stream;
  Stream<GatewayConnectionState> get stateStream => _stateController.stream;
  GatewayConnectionState get state => _state;
  bool get isConnected => _state == GatewayConnectionState.open;

  void _setState(GatewayConnectionState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  Future<void> connect(String url, {String? token}) async {
    _intentionalClose = false;
    _lastUrl = url;
    _lastToken = token;
    _reconnectAttempts = 0;

    final wsScheme = url.startsWith('https') ? 'wss' : 'ws';
    final cleanUrl = url.replaceAll(RegExp(r'/+$'), '');
    final host = Uri.parse(cleanUrl).host;
    final port = Uri.parse(cleanUrl).port;
    final path = token != null && token.isNotEmpty
        ? '/api/ws?token=$token'
        : '/api/ws';

    _setState(GatewayConnectionState.connecting);

    try {
      // Close old connection if any
      await _subscription?.cancel();
      _ws?.close();
      _ws = null;

      // Connect using dart:io WebSocket
      final wsHeaders = <String, String>{};
      if (token != null && token.isNotEmpty) {
        wsHeaders['X-Hermes-Session-Token'] = token;
      }
      _ws = await WebSocket.connect(
        '$wsScheme://$host:$port$path',
        headers: wsHeaders,
      );

      _subscription = _ws!.listen(
        _handleMessage,
        onError: (error) {
          if (!_intentionalClose) {
            _setState(GatewayConnectionState.error);
            _rejectAllPending(Exception('WebSocket error: $error'));
            _scheduleReconnect();
          }
        },
        onDone: () {
          if (!_intentionalClose) {
            _setState(GatewayConnectionState.closed);
            _rejectAllPending(Exception('WebSocket closed'));
            _scheduleReconnect();
          }
        },
        cancelOnError: false,
      );

      _setState(GatewayConnectionState.open);
    } catch (e) {
      _setState(GatewayConnectionState.error);
      _scheduleReconnect();
      rethrow;
    }
  }

  Future<void> disconnect() async {
    _intentionalClose = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    await _subscription?.cancel();
    _subscription = null;
    await _ws?.close();
    _ws = null;
    _setState(GatewayConnectionState.closed);
    _rejectAllPending(Exception('Disconnected'));
  }

  void _scheduleReconnect() {
    if (_intentionalClose) return;
    _reconnectTimer?.cancel();
    _reconnectAttempts++;
    final baseMs = 5000;
    final maxMs = 30000;
    var delayMs = (baseMs * (1 << (_reconnectAttempts - 1))).clamp(0, maxMs);
    _reconnectTimer = Timer(Duration(milliseconds: delayMs), () {
      if (_lastUrl != null) {
        connect(_lastUrl!, token: _lastToken).catchError((_) {});
      }
    });
  }

  Future<Map<String, dynamic>> request(
    String method, {
    Map<String, dynamic>? params,
    Duration timeout = const Duration(seconds: 120),
  }) async {
    if (!isConnected) {
      throw Exception('Gateway not connected');
    }

    final id = 'r${_nextId++}';
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;

    final frame = {
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      if (params != null) 'params': params,
    };

    _ws!.add(jsonEncode(frame));

    Timer(timeout, () {
      if (!completer.isCompleted) {
        _pending.remove(id);
        completer.completeError(TimeoutException('Request $method timed out'));
      }
    });

    return completer.future;
  }

  Future<void> submitPrompt(String sessionId, String text) async {
    await request('prompt.submit', params: {
      'session_id': sessionId,
      'text': text,
    });
  }

  Future<Map<String, dynamic>> createSession({String? title}) async {
    return await request('session.create', params: {
      if (title != null) 'title': title,
    });
  }

  void _handleMessage(dynamic data) {
    try {
      final decoded = jsonDecode(data as String);
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('id') && decoded['id'] != null) {
          final id = decoded['id'].toString();
          final completer = _pending.remove(id);
          if (completer != null) {
            if (decoded.containsKey('error')) {
              completer.completeError(
                Exception(decoded['error'].toString()),
              );
            } else {
              completer.complete(
                decoded['result'] as Map<String, dynamic>? ?? {},
              );
            }
          }
        }
        if (decoded.containsKey('type') && decoded.containsKey('params')) {
          final event = GatewayEvent.fromJson(decoded);
          _eventController.add(event);
        }
      }
    } catch (_) {}
  }

  void _rejectAllPending(Exception error) {
    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    }
    _pending.clear();
  }

  void dispose() {
    _intentionalClose = true;
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _ws?.close();
    _eventController.close();
    _stateController.close();
  }
}