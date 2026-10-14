import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_service.dart';

/// Payload delivered to every registered WebSocket listener.
class WsMessage {
  final String event;
  final dynamic data;

  const WsMessage({required this.event, this.data});
}

typedef WsListener = void Function(WsMessage message);
typedef RemoveListener = void Function();

class WsService {
  static final WsService _instance = WsService._internal();
  factory WsService() => _instance;
  WsService._internal();

  static const _reconnectDelay = Duration(seconds: 3);

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  bool _intentionalDisconnect = false;
  // True once this session has been authenticated on the socket at least
  // once; the next `auth:ok` is then a RE-connect (events may have been
  // missed in between) and fires [onReconnected].
  bool _hadSessionConnect = false;

  /// Fired after the socket re-authenticates following a drop. The sync layer
  /// uses it to re-fetch state that WS events could not deliver meanwhile.
  VoidCallback? onReconnected;

  final List<WsListener> _listeners = [];

  static String get _baseWsUrl =>
      kDebugMode ? 'ws://localhost:3001' : 'wss://diandian.overridedev.com';

  bool get isConnected => _channel != null;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  void connect() {
    _intentionalDisconnect = false;
    _hadSessionConnect = false;
    _connectInternal();
  }

  /// Connects only if no socket is open — safe to call on every app resume
  /// and after every token refresh.
  void ensureConnected() {
    if (_channel != null) return;
    _intentionalDisconnect = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _connectInternal();
  }

  void disconnect() {
    _intentionalDisconnect = true;
    _hadSessionConnect = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  /// Registers a [listener] and returns a function that removes it.
  RemoveListener addListener(WsListener listener) {
    _listeners.add(listener);
    return () => _listeners.remove(listener);
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  void _connectInternal() {
    if (_channel != null) return; // never stack a second socket on the first
    final token = ApiService().accessToken;
    if (token == null) {
      debugPrint('WsService: no access token, skipping connect');
      return;
    }

    // First-message auth: the token is sent as the first frame instead of a
    // ?token= query param, so it can never end up in proxy/access logs.
    // The server replies with an `auth:ok` event once verified.
    final uri = Uri.parse('$_baseWsUrl/ws');

    try {
      _channel = WebSocketChannel.connect(uri);

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      final channel = _channel!;
      channel.ready.then((_) {
        if (identical(channel, _channel)) {
          channel.sink.add(jsonEncode({'type': 'auth', 'token': token}));
        }
      }).catchError((Object e) {
        // Connection failed before opening — onDone handles the reconnect.
        debugPrint('WsService: connect failed: $e');
      });
    } catch (e) {
      debugPrint('WsService: connect error: $e');
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      final message = WsMessage(
        event: json['event'] as String,
        data: json['data'],
      );
      if (message.event == 'auth:ok') {
        if (_hadSessionConnect) onReconnected?.call();
        _hadSessionConnect = true;
      }
      for (final listener in List<WsListener>.of(_listeners)) {
        listener(message);
      }
    } catch (e) {
      debugPrint('WsService: failed to parse message: $e');
    }
  }

  void _onError(Object error) {
    debugPrint('WsService: stream error: $error');
  }

  void _onDone() {
    _channel = null;
    _subscription = null;

    if (!_intentionalDisconnect) {
      debugPrint('WsService: connection closed, reconnecting in ${_reconnectDelay.inSeconds}s');
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, _connectInternal);
  }
}
