import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_config.dart';
import '../storage/session_store.dart';

class RealtimeClient {
  RealtimeClient(this.sessionStore);

  final SessionStore sessionStore;
  final _events = StreamController<Map<String, dynamic>>.broadcast();
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Future<void>? _connecting;

  Stream<Map<String, dynamic>> get events => _events.stream;

  Future<void> connect() async {
    if (AppConfig.realtimeUrl.isEmpty || _channel != null) return;
    if (_connecting != null) return _connecting;
    final token = await sessionStore.accessToken;
    if (token == null || token.isEmpty) return;
    _connecting = _open(token);
    try {
      await _connecting;
    } finally {
      _connecting = null;
    }
  }

  Future<void> _open(String token) async {
    final channel = WebSocketChannel.connect(Uri.parse(AppConfig.realtimeUrl));
    _channel = channel;
    try {
      await channel.ready;
      channel.sink.add(
        jsonEncode({
          'type': 'subscribe',
          'topics': ['customer'],
          'accessToken': token,
        }),
      );
      _subscription = channel.stream.listen(
        (message) {
          try {
            final decoded = jsonDecode(message as String);
            if (decoded is Map<String, dynamic>) _events.add(decoded);
          } on FormatException {
            // Ignore malformed frames; subsequent valid events remain usable.
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          _events.addError(error, stackTrace);
        },
      );
    } catch (_) {
      _channel = null;
      await channel.sink.close();
      rethrow;
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _channel?.sink.close();
    await _events.close();
  }
}

