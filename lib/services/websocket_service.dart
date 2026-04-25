import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/leak_data.dart';

class WebSocketService {
  static const String _wsUrl =
      'wss://leak-monitor-backend.onrender.com/ws/sensors/';

  WebSocketChannel? _channel;
  final StreamController<LeakData> _controller =
      StreamController<LeakData>.broadcast();

  Stream<LeakData> get stream => _controller.stream;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  void connect() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _isConnected = true;

      _channel!.stream.listen(
        (message) => _handleMessage(message),
        onError: (error) {
          _isConnected = false;
          Future.delayed(const Duration(seconds: 3), connect);
        },
        onDone: () {
          _isConnected = false;
          Future.delayed(const Duration(seconds: 3), connect);
        },
      );
    } catch (e) {
      _isConnected = false;
      Future.delayed(const Duration(seconds: 3), connect);
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final Map<String, dynamic> json = jsonDecode(message as String);
      final LeakData data = LeakData.fromJson(json);
      if (!_controller.isClosed) _controller.add(data);
    } catch (e) {
      // handle silently
    }
  }

  void dispose() {
    _channel?.sink.close();
    _controller.close();
  }
}
