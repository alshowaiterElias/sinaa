import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../repositories/chat_repository.dart';
import '../services/socket_service.dart';
import 'auth_provider.dart';

/// State for conversations list
class ConversationsState {
  final List<Conversation> conversations;
  final bool isLoading;
  final String? error;

  const ConversationsState({
    this.conversations = const [],
    this.isLoading = false,
    this.error,
  });

  ConversationsState copyWith({
    List<Conversation>? conversations,
    bool? isLoading,
    String? error,
  }) {
    return ConversationsState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for conversations list
class ConversationsNotifier extends Notifier<ConversationsState> {
  @override
  ConversationsState build() => const ConversationsState();

  ChatRepository get _repository => ref.read(chatRepositoryProvider);

  Future<void> loadConversations() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final conversations = await _repository.getConversations();
      state = state.copyWith(conversations: conversations, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void updateConversationMessage(int conversationId, Message message) {
    final updated = state.conversations.map((conv) {
      if (conv.id == conversationId) {
        return Conversation(
          id: conv.id,
          user1Id: conv.user1Id,
          user2Id: conv.user2Id,
          projectId: conv.projectId,
          lastMessageAt: message.createdAt,
          createdAt: conv.createdAt,
          user1: conv.user1,
          user2: conv.user2,
          otherUser: conv.otherUser,
          project: conv.project,
          lastMessage: LastMessage(
            id: message.id,
            content: message.content,
            messageType: message.messageType,
            senderId: message.senderId,
            senderName: message.sender?.fullName,
            createdAt: message.createdAt,
          ),
          unreadCount: conv.unreadCount + 1,
        );
      }
      return conv;
    }).toList();

    // Sort by last message time
    updated.sort((a, b) => (b.lastMessageAt ?? b.createdAt)
        .compareTo(a.lastMessageAt ?? a.createdAt));

    state = state.copyWith(conversations: updated);
  }

  /// Clear unread count for a conversation (when user enters the chat)
  void clearUnreadCount(int conversationId) {
    final updated = state.conversations.map((conv) {
      if (conv.id == conversationId && conv.unreadCount > 0) {
        return Conversation(
          id: conv.id,
          user1Id: conv.user1Id,
          user2Id: conv.user2Id,
          projectId: conv.projectId,
          lastMessageAt: conv.lastMessageAt,
          createdAt: conv.createdAt,
          user1: conv.user1,
          user2: conv.user2,
          otherUser: conv.otherUser,
          project: conv.project,
          lastMessage: conv.lastMessage,
          unreadCount: 0,
        );
      }
      return conv;
    }).toList();

    state = state.copyWith(conversations: updated);
  }
}

/// State for a single chat
class ChatState {
  final ConversationDetail? conversation;
  final List<Message> messages;
  final bool isLoading;
  final bool isSending;
  final String? error;
  final Map<int, bool> typingUsers;

  const ChatState({
    this.conversation,
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
    this.typingUsers = const {},
  });

  ChatState copyWith({
    ConversationDetail? conversation,
    List<Message>? messages,
    bool? isLoading,
    bool? isSending,
    String? error,
    Map<int, bool>? typingUsers,
  }) {
    return ChatState(
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error,
      typingUsers: typingUsers ?? this.typingUsers,
    );
  }
}

/// Notifier for a single chat (uses StateNotifier pattern for family)
class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;
  final int conversationId;
  StreamSubscription<Message>? _messageSubscription;
  StreamSubscription<TypingEvent>? _typingSubscription;

  ChatNotifier(this._ref, this.conversationId) : super(const ChatState()) {
    _setupListeners();
  }

  ChatRepository get _repository => _ref.read(chatRepositoryProvider);
  SocketService get _socketService => _ref.read(socketServiceProvider);

  void _setupListeners() {
    _messageSubscription = _socketService.messageStream.listen((message) {
      if (message.conversationId == conversationId) {
        _addMessage(message);
      }
    });

    _typingSubscription = _socketService.typingStream.listen((event) {
      if (event.conversationId == conversationId) {
        _updateTyping(event.userId, event.isTyping);
      }
    });
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _socketService.leaveConversation(conversationId);
    super.dispose();
  }

  Future<void> loadMessages({int page = 1}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response =
          await _repository.getConversation(conversationId, page: page);
      state = state.copyWith(
        conversation: response.conversation,
        messages: page == 1
            ? response.messages
            : [...state.messages, ...response.messages],
        isLoading: false,
      );

      // Join socket room
      _socketService.joinConversation(conversationId);

      // Mark as read and clear badge immediately
      _repository.markAsRead(conversationId);
      _ref
          .read(conversationsProvider.notifier)
          .clearUnreadCount(conversationId);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> sendMessage(String content,
      {String messageType = 'text'}) async {
    if (content.trim().isEmpty) return false;

    state = state.copyWith(isSending: true);

    try {
      // Try socket first
      if (_socketService.isConnected) {
        _socketService.sendMessage(
          conversationId: conversationId,
          content: content.trim(),
          messageType: messageType,
        );
        state = state.copyWith(isSending: false);
        return true;
      }

      // Fallback to REST
      final message = await _repository.sendMessage(
        conversationId: conversationId,
        content: content.trim(),
        messageType: messageType,
      );
      _addMessage(message);
      state = state.copyWith(isSending: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSending: false, error: e.toString());
      return false;
    }
  }

  void sendTyping(bool isTyping) {
    _socketService.sendTyping(
        conversationId: conversationId, isTyping: isTyping);
  }

  void _addMessage(Message message) {
    // Check if message already exists
    if (state.messages.any((m) => m.id == message.id)) return;

    state = state.copyWith(
      messages: [...state.messages, message],
    );

    // Also update conversations list
    _ref
        .read(conversationsProvider.notifier)
        .updateConversationMessage(conversationId, message);
  }

  void _updateTyping(int userId, bool isTyping) {
    final updated = Map<int, bool>.from(state.typingUsers);
    if (isTyping) {
      updated[userId] = true;
    } else {
      updated.remove(userId);
    }
    state = state.copyWith(typingUsers: updated);
  }
}

/// Provider for conversations list
final conversationsProvider =
    NotifierProvider<ConversationsNotifier, ConversationsState>(
  ConversationsNotifier.new,
);

/// Provider for a single chat (by conversation ID)
final chatProvider = StateNotifierProvider.family<ChatNotifier, ChatState, int>(
  (ref, conversationId) => ChatNotifier(ref, conversationId),
);

/// Socket connection status provider
final socketStatusProvider = StreamProvider<SocketStatus>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return socketService.statusStream;
});

/// Initialize socket when user logs in
final socketInitProvider = Provider<void>((ref) {
  final isLoggedIn = ref.watch(isAuthenticatedProvider);
  final socketService = ref.watch(socketServiceProvider);

  if (isLoggedIn) {
    socketService.connect();
  } else {
    socketService.disconnect();
  }
});
