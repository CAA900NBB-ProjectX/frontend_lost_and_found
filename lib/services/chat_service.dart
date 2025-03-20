import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:stomp_dart_client/stomp.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import '/config/api_config.dart';


class MessageType {
  static const String TEXT = "TEXT";
  static const String IMAGE = "IMAGE";
}


class MessageState {
  static const String SENT = "SENT";
  static const String DELIVERED = "DELIVERED";
  static const String READ = "READ";
}


class ChatMessage {
  final dynamic id;
  final String content;
  final String type;
  final String state;
  final String senderId;
  final String receiverId;
  final DateTime createdAt;
  final List<int>? media;


  ChatMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.state,
    required this.senderId,
    required this.receiverId,
    required this.createdAt,
    this.media,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {

    dynamic messageId = json['id'];
    if (messageId is String && int.tryParse(messageId) != null) {
      messageId = int.parse(messageId);
    }

    return ChatMessage(
      id: messageId ?? 0,
      content: json['content'] ?? '',
      type: json['type'] ?? MessageType.TEXT,
      state: json['state'] ?? MessageState.SENT,
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      media: json['media'] != null && json['media'] != ''
          ? (json['media'] is List
          ? List<int>.from(json['media'])
          : null)
          : null,
    );
  }
}


class ChatService {
  StompClient? _stompClient;

  final ValueNotifier<List<ChatMessage>> messages = ValueNotifier<List<ChatMessage>>([]);

  final Map<String, List<ChatMessage>> _messagesCache = {};

  Future<Map<String, dynamic>?> checkExistingChat(String token, String itemPostedUserId, int itemId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.checkChatUrl}?token=$token&ItemPostedUser=$itemPostedUserId&itemId=$itemId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': '69420',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> chats = json.decode(response.body);
        if (chats.isNotEmpty) {
          return chats[0];
        }
      }
      return null;
    } catch (e) {
      print('Error checking existing chat: $e');
      return null;
    }
  }


  Future<String?> createChat(String token, String receiverUsername, int itemId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.createChatUrl}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': '69420',
        },
        body: json.encode({
          'token':token,
          'receiverId': receiverUsername,
          'itemId': itemId,
        }),
      );

      print('Create chat response status: ${response.statusCode}');
      print('Create chat response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['response'];
      }
      return null;
    } catch (e) {
      print('Error creating chat: $e');
      return null;
    }
  }

  Future<List<ChatMessage>> getChatMessages(String chatId, String token) async {
    try {

      if (_messagesCache.containsKey(chatId)) {
        print('Returning cached messages for chat $chatId');

        messages.value = _messagesCache[chatId]!;

        _refreshMessages(chatId, token);
        return _messagesCache[chatId]!;
      }


      final response = await http.get(
        Uri.parse('${ApiConfig.getChatMessagesUrl}/$chatId'),
        headers:{
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': '69420',
        },
      );

      print('Get messages response status: ${response.statusCode}');
      print('Get messages response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> messagesList = json.decode(response.body);
        print('Parsed ${messagesList.length} messages from server');

        final chatMessages = messagesList.map((json) => ChatMessage.fromJson(json)).toList();


        chatMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));


        _messagesCache[chatId] = chatMessages;


        messages.value = chatMessages;

        return chatMessages;
      }
      print('Error getting messages: HTTP ${response.statusCode}');
      return [];
    } catch (e) {
      print('Error getting chat messages: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getChatList(String token, int itemId, String itemPostedUserId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.getChatListUrl}?token=$token&ItemPostedUser=$itemPostedUserId&itemId=$itemId'),
        headers: {
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': '69420',
        },
      );

      print('Get chat list response status: ${response.statusCode}');
      print('Get chat list response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> chatList = json.decode(response.body);
        return List<Map<String, dynamic>>.from(chatList);
      }
      return [];
    } catch (e) {
      print('Error getting chat list: $e');
      return [];
    }
  }

  Future<void> _refreshMessages(String chatId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.getChatMessagesUrl}/$chatId'),
        headers:{
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': '69420',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> messagesList = json.decode(response.body);
        final chatMessages = messagesList.map((json) => ChatMessage.fromJson(json)).toList();


        chatMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));


        _messagesCache[chatId] = chatMessages;

        messages.value = chatMessages;
      }
    } catch (e) {
      print('Error refreshing messages: $e');
    }
  }


  Future<bool> sendMessage({
    required String content,
    required String senderUsername,
    required String receiverUsername,
    required int itemId,
    required String chatId,
    required String token,
  }) async {
    try {
      final message = {
        'content': content,
        'senderId': senderUsername,
        'receiverId': receiverUsername,
        'itemId': itemId,
        'type': MessageType.TEXT,
        'chatId': chatId,
      };

      final response = await http.post(
        Uri.parse(ApiConfig.sendMessageUrl),
        headers: {
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': '69420',
        },
        body: json.encode(message),
      );

      print('Send message response status: ${response.statusCode}');
      print('Send message response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {

        _refreshMessages(chatId, token);
        return true;
      }
      return false;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }


  void connectWebSocket(String chatId, String userId) {
    try {
      print('Attempting to connect to WebSocket at ${ApiConfig.wsEndpoint}');

      _stompClient = StompClient(
        config: StompConfig.SockJS(
          url: ApiConfig.wsEndpoint,
          onConnect: (frame) {
            print('Connected to WebSocket');


            _stompClient?.subscribe(
              destination: '/chat/$chatId',
              callback: (frame) {
                print('Received message from WebSocket: ${frame.body}');
                if (frame.body != null) {
                  try {
                    final data = json.decode(frame.body!);
                    final newMessage = ChatMessage.fromJson(data);


                    if (_messagesCache.containsKey(chatId)) {
                      _messagesCache[chatId]!.add(newMessage);
                    } else {
                      _messagesCache[chatId] = [newMessage];
                    }


                    final updatedMessages = List<ChatMessage>.from(messages.value);
                    updatedMessages.add(newMessage);
                    messages.value = updatedMessages;
                  } catch (e) {
                    print('Error processing WebSocket message: $e');
                  }
                }
              },
            );
          },
          onWebSocketError: (error) => print('WebSocket error: $error'),
          onStompError: (frame) => print('STOMP error: ${frame.body}'),
          stompConnectHeaders: {'userId': userId},
          webSocketConnectHeaders: {'userId': userId},
        ),
      );

      _stompClient?.activate();
    } catch (e) {
      print('Failed to connect to WebSocket: $e');

    }
  }

  void disconnectWebSocket() {
    _stompClient?.deactivate();
    print('Disconnected from WebSocket');
  }
}
