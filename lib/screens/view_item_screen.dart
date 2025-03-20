import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import '../models/item.dart';
import '../services/item_service.dart';
import 'dart:convert';
import '../auth/services/auth_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import 'chat_list_screen.dart';

class ViewItemScreen extends StatefulWidget {
  final int itemId;

  const ViewItemScreen({Key? key, required this.itemId}) : super(key: key);

  @override
  State<ViewItemScreen> createState() => _ViewItemScreenState();
}

class _ViewItemScreenState extends State<ViewItemScreen> {
  final ItemService _itemService = ItemService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  String? _errorMessage;
  Item? _item;
  List<Uint8List> _images = [];

  @override
  void initState() {
    super.initState();
    _fetchItemDetails();
  }

  Future<void> _fetchItemDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final item = await _itemService.getItemById(widget.itemId);

      if (mounted) {
        if (item != null) {
          setState(() {
            _item = item;
            _isLoading = false;
          });


          if (item.images != null && item.images!.isNotEmpty) {
            _loadImagesFromBase64(item.images!);
          }
        } else {
          setState(() {
            _errorMessage = 'Item not found';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load item: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _loadImagesFromBase64(List<ItemImage> images) {
    for (var image in images) {
      try {
        final base64Data = image.image.split(',')[1];
        final imageData = base64Decode(base64Data);

        if (mounted) {
          setState(() {
            _images.add(Uint8List.fromList(imageData));
          });
        }
      } catch (e) {
        print('Error loading image from base64: $e');
      }
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('yyyy-MM-dd HH:mm').format(date);
    } catch (e) {
      return isoDate;
    }
  }

  Future<void> _initiateChat() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Connecting to chat...'),
          ],
        ),
      ),
    );

    try {
      final chatService = ChatService();
      final token = await _authService.getToken();

      if (token == null) {
        if (context.mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to chat'))
        );
        return;
      }


      final String? currentUsername = extractUsernameFromToken(token);
      if (currentUsername == null) {
        if (context.mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to get user information from token'))
        );
        return;
      }

      final int itemId = _item?.itemId ?? 0;
      final String reportedBy = _item?.reportedBy ?? "";


      if (currentUsername == reportedBy) {
        // Close loading dialog
        if (context.mounted) Navigator.pop(context);

        //Bro  if the current user is the reporter, show the chat list
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatListScreen(
                itemId: itemId,
                itemName: _item?.itemName ?? "Item",
                reportedBy: reportedBy,
              ),
            ),
          );
        }
        return;
      }


      final existingChat = await chatService.checkExistingChat(
        token,
        reportedBy,
        itemId,
      );

      String? chatId;

      if (existingChat != null) {
        chatId = existingChat['id'] as String?;
      } else {
        chatId = await chatService.createChat(
          token,
          reportedBy,
          itemId,
        );
      }

      if (context.mounted) Navigator.pop(context);

      if (chatId != null && chatId.isNotEmpty && context.mounted) {
        final String nonNullChatId = chatId;
        final String itemName = _item?.itemName ?? "Item";

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: nonNullChatId,
              currentUsername: currentUsername,
              receiverUsername: reportedBy,
              itemId: itemId,
              itemName: itemName,
              receiver: reportedBy, // need to check n]bro
            ),
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to start chat. Please try again.'))
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'))
      );
    }
  }

  String? extractUsernameFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> data = json.decode(decoded);


      return data['username'] ??
          data['preferred_username'] ??
          data['email'] ??
          data['sub'] ??
          data['userId'] ??
          data['name'];
    } catch (e) {
      print('Error extracting username from token: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_item?.itemName ?? 'Item Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
          : _buildItemDetails(),
    );
  }

  Widget _buildItemDetails() {
    if (_item == null) {
      return const Center(child: Text('No item data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          if (_images.isNotEmpty)
            SizedBox(
              height: 250,
              child: PageView.builder(
                itemCount: _images.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.memory(
                        _images[index],
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),
            )
          else
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _getCategoryColor(_item!.categoryId),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  _getCategoryIcon(_item!.categoryId),
                  size: 80,
                  color: Colors.white,
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Item details
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _item!.itemName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Chip(
                    label: Text(
                      _item!.status,
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: _item!.status == "FOUND" ? Colors.green : Colors.orange,
                  ),
                  const Divider(height: 24),

                  _buildDetailRow(Icons.category, 'Category', _item!.getCategoryName()),
                  _buildDetailRow(Icons.description, 'Description', _item!.description),
                  _buildDetailRow(Icons.location_on, 'Location Found', _item!.locationFound),
                  _buildDetailRow(Icons.calendar_today, 'Date Found', _formatDate(_item!.dateTimeFound)),
                  _buildDetailRow(Icons.person, 'Reported By', _item!.reportedBy),

                  const SizedBox(height: 20),

                  // Contact section
                  const Text(
                    'Contact Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.contact_mail),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _item!.contactInfo,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),


          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _initiateChat,
                  icon: const Icon(Icons.email),
                  label: const Text('Chat'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sharing item details')),
                    );
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(int categoryId) {
    switch (categoryId) {
      case 1: return Icons.devices;
      case 2: return Icons.checkroom;
      case 3: return Icons.watch;
      case 4: return Icons.description;
      default: return Icons.category;
    }
  }

  Color _getCategoryColor(int categoryId) {
    switch (categoryId) {
      case 1: return Colors.blue;
      case 2: return Colors.green;
      case 3: return Colors.orange;
      case 4: return Colors.purple;
      default: return Colors.grey;
    }
  }
}
