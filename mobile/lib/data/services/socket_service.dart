import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../core/network/api_endpoints.dart';
import '../../core/storage/local_storage.dart';
import '../models/message_model.dart';
import '../models/notification_model.dart';

/// Socket connection status
enum SocketStatus {
  disconnected,
  connecting,
  connected,
  error,
}

/// Socket service for real-time messaging
class SocketService {
  final LocalStorage _storage;

  io.Socket? _socket;
  SocketStatus _status = SocketStatus.disconnected;

  // Stream controllers for events
  final _statusController = StreamController<SocketStatus>.broadcast();
  final _messageController = StreamController<Message>.broadcast();
  final _typingController = StreamController<TypingEvent>.broadcast();
  final _readController = StreamController<ReadEvent>.broadcast();
  final _onlineController = StreamController<OnlineEvent>.broadcast();
  final _notificationController = StreamController<AppNotification>.broadcast();

  SocketService(this._storage);

  // Public streams
  Stream<SocketStatus> get statusStream => _statusController.stream;
  Stream<Message> get messageStream => _messageController.stream;
  Stream<TypingEvent> get typingStream => _typingController.stream;
  Stream<ReadEvent> get readStream => _readController.stream;
  Stream<OnlineEvent> get onlineStream => _onlineController.stream;
  Stream<AppNotification> get notificationStream =>
      _notificationController.stream;

  SocketStatus get status => _status;
  bool get isConnected => _status == SocketStatus.connected;

  /// Connect to WebSocket server
  Future<void> connect() async {
    if (_socket != null && _socket!.connected) {
      return;
    }

    _setStatus(SocketStatus.connecting);

    try {
      final token = await _storage.getAccessToken();
      if (token == null) {
        _setStatus(SocketStatus.error);
        return;
      }

      // Get base URL without /api/v1
      final baseUrl = ApiEndpoints.serverBaseUrl;

      _socket = io.io(
        baseUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': token})
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(1000)
            .build(),
      );

      _setupEventListeners();
    } catch (e) {
      debugPrint('Socket connection error: $e');
      _setStatus(SocketStatus.error);
    }
  }

  void _setupEventListeners() {
    _socket!
      ..onConnect((_) {
        debugPrint('Socket connected');
        _setStatus(SocketStatus.connected);
      })
      ..onDisconnect((_) {
        debugPrint('Socket disconnected');
        _setStatus(SocketStatus.disconnected);
      })
      ..onConnectError((error) {
        debugPrint('Socket connection error: $error');
        _setStatus(SocketStatus.error);
      })
      ..onError((error) {
        debugPrint('Socket error: $error');
        _setStatus(SocketStatus.error);
      })
      ..on('newMessage', (data) {
        try {
          final messageData = data['message'] as Map<String, dynamic>;
          final message = Message.fromJson(messageData);
          _messageController.add(message);
        } catch (e) {
          debugPrint('Error parsing message: $e');
        }
      })
      ..on('userTyping', (data) {
        try {
          _typingController.add(TypingEvent(
            conversationId: data['conversationId'] as int,
            userId: data['userId'] as int,
            isTyping: data['isTyping'] as bool,
          ));
        } catch (e) {
          debugPrint('Error parsing typing event: $e');
        }
      })
      ..on('messagesRead', (data) {
        try {
          _readController.add(ReadEvent(
            conversationId: data['conversationId'] as int,
            readBy: data['readBy'] as int,
          ));
        } catch (e) {
          debugPrint('Error parsing read event: $e');
        }
      })
      ..on('userOnline', (data) {
        _onlineController.add(OnlineEvent(
          userId: data['userId'] as int,
          isOnline: true,
        ));
      })
      ..on('userOffline', (data) {
        _onlineController.add(OnlineEvent(
          userId: data['userId'] as int,
          isOnline: false,
        ));
      })
      ..on('error', (data) {
        debugPrint('Socket error event: $data');
      })
      ..on('notification', (data) {
        try {
          final notification =
              AppNotification.fromJson(data as Map<String, dynamic>);
          _notificationController.add(notification);
        } catch (e) {
          debugPrint('Error parsing notification: $e');
        }
      });
  }

  void _setStatus(SocketStatus status) {
    _status = status;
    _statusController.add(status);
  }

  /// Join a conversation room
  void joinConversation(int conversationId) {
    _socket?.emit('joinConversation', conversationId);
    debugPrint('Joined conversation $conversationId');
  }

  /// Leave a conversation room
  void leaveConversation(int conversationId) {
    _socket?.emit('leaveConversation', conversationId);
    debugPrint('Left conversation $conversationId');
  }

  /// Send a message
  void sendMessage({
    required int conversationId,
    required String content,
    String messageType = 'text',
  }) {
    _socket?.emit('sendMessage', {
      'conversationId': conversationId,
      'content': content,
      'messageType': messageType,
    });
  }

  /// Send typing indicator
  void sendTyping({
    required int conversationId,
    required bool isTyping,
  }) {
    _socket?.emit('typing', {
      'conversationId': conversationId,
      'isTyping': isTyping,
    });
  }

  /// Mark messages as read
  void markAsRead(int conversationId) {
    _socket?.emit('markRead', conversationId);
  }

  /// Disconnect from server
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _setStatus(SocketStatus.disconnected);
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _statusController.close();
    _messageController.close();
    _typingController.close();
    _readController.close();
    _onlineController.close();
    _notificationController.close();
  }
}

/// Typing event data
class TypingEvent {
  final int conversationId;
  final int userId;
  final bool isTyping;

  const TypingEvent({
    required this.conversationId,
    required this.userId,
    required this.isTyping,
  });
}

/// Read event data
class ReadEvent {
  final int conversationId;
  final int readBy;

  const ReadEvent({
    required this.conversationId,
    required this.readBy,
  });
}

/// Online status event
class OnlineEvent {
  final int userId;
  final bool isOnline;

  const OnlineEvent({
    required this.userId,
    required this.isOnline,
  });
}

/// Provider for socket service
final socketServiceProvider = Provider<SocketService>((ref) {
  final storage = ref.watch(localStorageProvider);
  return SocketService(storage);
});
