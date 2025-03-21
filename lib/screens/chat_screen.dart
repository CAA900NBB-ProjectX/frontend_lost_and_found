import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/chat_service.dart';
import '../auth/services/auth_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String currentUsername;
  final String receiverUsername;
  final int itemId;
  final String itemName;
  final String receiver;//

  const ChatScreen({
    Key? key,
    required this.chatId,
    required this.currentUsername,
    required this.receiverUsername,
    required this.itemId,
    required this.itemName,
    required this.receiver, //
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _sendingMessage = false;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    setState(() {
      _isLoading = true;
    });

    try {

      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }


      print('Loading messages for chat: ${widget.chatId}');
      final messages = await _chatService.getChatMessages(widget.chatId, token);

      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });


        print('Loaded ${_messages.length} messages');
        if (_messages.isNotEmpty) {
          print('First message: ${_messages.first.content}');
          print('Last message: ${_messages.last.content}');
        }
      }


      _chatService.connectWebSocket(widget.chatId, widget.currentUsername,);


      _chatService.messages.addListener(_onMessagesUpdated);


      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print('Error initializing chat: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load chat: $e')),
        );
      }
    }
  }

  void _onMessagesUpdated() {
    if (mounted) {
      setState(() {
        _messages = _chatService.messages.value;
      });


      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _sendingMessage) return;

    _messageController.clear();
    setState(() {
      _sendingMessage = true;
    });

    try {
      final token = await _authService.getToken();

      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please login again to send messages'))
          );
        }
        return;
      }

      final temporaryId = DateTime.now().millisecondsSinceEpoch;
      final newMessage = ChatMessage(
        id: temporaryId,
        content: messageText,
        type: MessageType.TEXT,
        state: MessageState.SENT,
        senderId: widget.currentUsername,
        receiverId: widget.receiver,//
        createdAt: DateTime.now(),
      );

      setState(() {
        _messages = [..._messages, newMessage];
      });


      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });


      final success = await _chatService.sendMessage(
        content: messageText,
        senderUsername: widget.currentUsername,
        receiverUsername: widget.receiver,
        itemId: widget.itemId,
        chatId: widget.chatId,
        token: token,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message')),
        );
      }
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    } finally {
      setState(() {
        _sendingMessage = false;
      });
    }
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemName),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Messages list
          Expanded(
            child: _messages.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start the conversation!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
                : _buildMessagesList(),
          ),

          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {

    final Map<String, List<ChatMessage>> messagesByDate = {};

    for (var message in _messages) {
      final date = _formatDate(message.createdAt);
      if (!messagesByDate.containsKey(date)) {
        messagesByDate[date] = [];
      }
      messagesByDate[date]!.add(message);
    }

    final List<dynamic> flattenedList = [];
    messagesByDate.forEach((date, messages) {
      flattenedList.add(date);
      flattenedList.addAll(messages);
    });

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: flattenedList.length,
      itemBuilder: (context, index) {
        final item = flattenedList[index];


        if (item is String) {
          return _buildDateHeader(item);
        }


        final message = item as ChatMessage;
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildDateHeader(String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            date,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isMe = message.senderId == widget.currentUsername;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 2, top: 2),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? Colors.purple : Colors.grey[200],
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 12),
            child: Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Message input field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),

            // Send button
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.purple,
              child: IconButton(
                icon: _sendingMessage
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(Icons.send, size: 20, color: Colors.white),
                onPressed: _sendingMessage ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatService.messages.removeListener(_onMessagesUpdated);
    _chatService.disconnectWebSocket();
    super.dispose();
  }
}

