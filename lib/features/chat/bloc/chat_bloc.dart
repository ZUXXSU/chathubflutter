import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter_app/core/api/api_service.dart';
import 'package:flutter_app/core/api/socket_service.dart';
import 'package:flutter_app/core/models/message.dart';
import 'package:flutter_app/core/models/user.dart';
import 'package:flutter_app/features/chat/bloc/chat_event.dart';
import 'package:flutter_app/features/chat/bloc/chat_state.dart';
import 'package:flutter/foundation.dart';

/// Manages the state for the [ChatScreen] using the BLoC pattern.
///
/// This BLoC handles:
/// - Loading initial messages from the API.
/// - Sending new messages via Socket.io.
/// - Listening for real-time `NEW_MESSAGE` events.
/// - Listening for `START_TYPING` and `STOP_TYPING` events.
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ApiService apiService;
  final SocketService socketService;
  final String chatId;
  final String myUserId; // Need this to identify "my" messages

  // --- CORRECTED SUBSCRIPTION TYPES ---
  /// Holds the *unsubscribe* function for the 'NEW_MESSAGE' event.
  Function? _messageSubscription;
  /// Holds the *unsubscribe* function for the 'START_TYPING' event.
  Function? _typingStartSubscription;
  /// Holds the *unsubscribe* function for the 'STOP_TYPING' event.
  Function? _typingStopSubscription;
  // --- END CORRECTION ---

  ChatBloc({
    required this.apiService,
    required this.socketService,
    required this.chatId,
    required this.myUserId,
  }) : super(ChatLoading()) {
    
    // Register event handlers
    on<LoadMessages>(_onLoadMessages);
    on<SendTextMessage>(_onSendMessage);
    on<MessageReceived>(_onMessageReceived);
    on<TypingStarted>(_onTypingStarted);
    on<TypingStopped>(_onTypingStopped);

    // --- CORRECTED LISTENER ASSIGNMENT ---
    // Listen to socket events and store the "off" function
    _messageSubscription = socketService.socket?.on('NEW_MESSAGE', (data) {
      try {
        if (data['chatId'] == chatId) {
          // Add event to BLoC stream
          add(MessageReceived(Message.fromJson(data['message'])));
        }
      } catch (e) {
        debugPrint('Error parsing received message: $e');
      }
    });

    _typingStartSubscription = socketService.socket?.on('START_TYPING', (data) {
      if (data['chatId'] == chatId) {
        add(TypingStarted());
      }
    });

    _typingStopSubscription = socketService.socket?.on('STOP_TYPING', (data) {
      if (data['chatId'] == chatId) {
        add(TypingStopped());
      }
    });
    // --- END CORRECTION ---

    // Load initial messages
    add(LoadMessages(chatId));
  }

  /// Handles the [LoadMessages] event.
  Future<void> _onLoadMessages(LoadMessages event, Emitter<ChatState> emit) async {
    try {
      emit(ChatLoading());
      final result = await apiService.getMessages(chatId, event.page);
      final messages = Message.fromJsonList(result['messages']);
      
      emit(ChatLoaded(
        messages: messages,
        totalPages: result['totalPages'],
        currentPage: event.page,
      ));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  /// Handles the [SendMessage] event.
  void _onSendMessage(SendMessage event, Emitter<ChatState> emit) {
    if (event.message.trim().isEmpty) return;

    // Emit the message via Socket.io
    socketService.sendMessage(
      chatId: chatId,
      members: event.members,
      message: event.message.trim(),
    );

    // Optimistic UI update: Add the message to the state immediately.
    // The backend will broadcast it back, but we can show it now.
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      
      // Create a temporary local message
      final optimisticMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Temp ID
        content: event.message.trim(),
        attachments: [],
        sender: MessageSender(id: myUserId, name: "Me"), // Use 'myUserId'
        chatId: chatId,
        createdAt: DateTime.now(),
      );

      final updatedMessages = List<Message>.from(currentState.messages)
        ..add(optimisticMessage);
      
      emit(currentState.copyWith(messages: updatedMessages));
    }
  }

  /// Handles the [MessageReceived] event (from socket).
  void _onMessageReceived(MessageReceived event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;

      // Avoid duplicates from optimistic send
      if (event.data.sender.id == myUserId) {
        // If it's my message, find the temp one and replace it
        // (or just ignore if the server echo is reliable)
        return; // Assuming server doesn't echo back to sender
      }
      
      final updatedMessages = List<Message>.from(currentState.messages)
        ..add(event.message);
      
      emit(currentState.copyWith(messages: updatedMessages));
    }
  }

  /// Handles the [TypingStarted] event.
  void _onTypingStarted(TypingStarted event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      emit((state as ChatLoaded).copyWith(isTyping: true));
    }
  }

  /// Handles the [TypingStopped] event.
  void _onTypingStopped(TypingStopped event, Emitter<ChatState> emit) {
     if (state is ChatLoaded) {
      emit((state as ChatLoaded).copyWith(isTyping: false));
    }
  }
  
  // --- CORRECTED CLOSE METHOD ---
  @override
  Future<void> close() {
    // Call the stored "off" functions to unsubscribe
    _messageSubscription?.call();
    _typingStartSubscription?.call();
    _typingStopSubscription?.call();
    return super.close();
  }
  // --- END CORRECTION ---
}

