import 'dart:async';
import 'dart:convert';
import 'package:web_socket_client/web_socket_client.dart';

class ChatWebService {
  static final _instance = ChatWebService._internal();
  factory ChatWebService() => _instance;

  ChatWebService._internal();

  final _searchResultController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _contentController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get searchResultStream =>
      _searchResultController.stream;
  Stream<Map<String, dynamic>> get contentStream => _contentController.stream;

  WebSocket? _socket;
  StreamSubscription? _messageSub;
  bool _isConnecting = false;

  Future<void> connect() async {
    if (_socket != null || _isConnecting) return;
    _isConnecting = true;

    try {
      final socket = WebSocket(Uri.parse('ws://localhost:8000/ws/chat'));
      _socket = socket;

      _messageSub = socket.messages.listen(
        _handleMessage,
        onError: (_) => _handleDisconnect(),
        onDone: _handleDisconnect,
      );
    } finally {
      _isConnecting = false;
    }
  }

  void _handleMessage(dynamic message) {
    Map<String, dynamic> data;
    try {
      data = message is String
          ? json.decode(message) as Map<String, dynamic>
          : (message as Map).cast<String, dynamic>();
    } catch (_) {
      return;
    }

    switch (data['type']) {
      case 'search_result':
        _searchResultController.add(data);
        break;
      case 'content':
        _contentController.add(data);
        break;
      default:
        break;
    }
  }

  Future<void> chat(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    if (_socket == null) {
      await connect();
    }

    _socket?.send(json.encode({'query': trimmed}));
  }

  void _handleDisconnect() {
    _messageSub?.cancel();
    _messageSub = null;
    _socket = null;
  }

  Future<void> dispose() async {
    await _messageSub?.cancel();
    _socket?.close();
    await _searchResultController.close();
    await _contentController.close();
  }
}
