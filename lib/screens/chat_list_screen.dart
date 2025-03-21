import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../services/chat_service.dart';
import '../auth/services/auth_service.dart';
import 'chat_screen.dart';


Map<String, dynamic>? globalChatData;


class ChatListScreen extends StatefulWidget {
  final int itemId;
  final String itemName;
  final String reportedBy;

  const ChatListScreen({
    Key? key,
    required this.itemId,
    required this.itemName,
    required this.reportedBy,
  }) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _authService.getToken();

      if (token == null) {
        setState(() {
          _errorMessage = 'Please log in to view chats';
          _isLoading = false;
        });
        return;
      }


      _currentUserId = _getUserIdFromToken(token);

      if (_currentUserId == null) {
        setState(() {
          _errorMessage = 'Unable to get user information';
          _isLoading = false;
        });
        return;
      }

      final chats = await _chatService.getChatList(token, widget.itemId, widget.reportedBy);

      setState(() {
        _chats = chats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load chats: $e';
        _isLoading = false;
      });
    }
  }

  String? _getUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> data = json.decode(decoded);

      return data['sub'] ?? data['user_id'] ?? data['id'] ?? data['userId'];
    } catch (e) {
      print('Error extracting user ID from token: $e');
      return null;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      DateTime dateTime;
      if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else if (timestamp is List) {
        dateTime = DateTime(
          timestamp[0],
          timestamp[1],
          timestamp[2],
          timestamp[3] ?? 0,
          timestamp[4] ?? 0,
          timestamp[5] ?? 0,
        );
      } else {
        return 'Unknown';
      }

      return DateFormat('MMM d, h:mm a').format(dateTime);
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chats for ${widget.itemName}'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
          child: Text(_errorMessage!, style: TextStyle(color: Colors.red)))
          : _chats.isEmpty
          ? _buildEmptyState()
          : _buildChatList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No chats yet',
            style: TextStyle(fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'No one has contacted you about this item yet',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _chats.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final chat = _chats[index];


        final isSender = _currentUserId == chat['senderUsername'].toString();
        final otherUserId = isSender
            ? chat['receiverUsername'].toString()
            : chat['senderUsername'].toString();
        final otherUserName = chat['otherUserName'] ?? '$otherUserId';
        print('User  - $chat');
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.purple.withOpacity(0.2),
            child: Text(
              otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.purple),
            ),
          ),
          title: Text(otherUserName),
          subtitle: chat['lastMessage'] != null
              ? Text(
            chat['lastMessage'],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
              : const Text(
              'No messages yet', style: TextStyle(fontStyle: FontStyle.italic)),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTimestamp(chat['lastMessageTime']),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              chat['unreadCount'] != null && chat['unreadCount'] > 0
                  ? Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.purple,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  chat['unreadCount'].toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              )
                  : const SizedBox(),
            ],
          ),
          onTap: () => _openChat(chat),
        );
      },
    );
  }

  void _openChat(Map<String, dynamic> chat) async {
    final token = await _authService.getToken();
    if (token == null || _currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in again to view the chat')),
      );
      return;
    }
    globalChatData = chat;
    print('Chat Data Stored Globally: $globalChatData');

    final isSender = _currentUserId == chat['senderId'].toString();
    final otherUserId = isSender
        ? chat['receiverId'].toString()
        : chat['senderId'].toString();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChatScreen(
              chatId: chat['id'],
              currentUsername: _currentUserId!,
              receiverUsername: otherUserId,
              itemId: widget.itemId,
              itemName: widget.itemName,
              receiver:chat['senderUsername']
            ),
      ),
    ).then((_) => _loadChats());
  }
}