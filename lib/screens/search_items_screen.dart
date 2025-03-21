import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../models/item.dart';
import '../services/item_service.dart';

class SearchItemsScreen extends StatefulWidget {
  const SearchItemsScreen({Key? key}) : super(key: key);

  @override
  State<SearchItemsScreen> createState() => _SearchItemsScreenState();
}

class _SearchItemsScreenState extends State<SearchItemsScreen> {
  final _itemService = ItemService();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<Item> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasSearched = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _searchItems() async {
    // Don't search if all fields are empty
    if (_nameController.text.isEmpty &&
        _locationController.text.isEmpty &&
        _descriptionController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter at least one search term';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = true;
    });

    try {
      final results = await _itemService.searchItems(
        _nameController.text.isNotEmpty ? _nameController.text : null,
        _locationController.text.isNotEmpty ? _locationController.text : null,
        _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
      );

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error searching items: $e';
        _isLoading = false;
      });
    }
  }

  void _clearSearch() {
    setState(() {
      _nameController.clear();
      _locationController.clear();
      _descriptionController.clear();
      _searchResults = [];
      _hasSearched = false;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Black background from login page
      appBar: AppBar(
        title: const Text('Search Items'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearSearch,
            tooltip: 'Clear Search',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search form
          Container(
            color: const Color(0xFF2C2C2C), // Dark gray from login page
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),

                // Item name field
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Item name',
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Color(0xFF3A3A3A),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),

                // Location field
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    hintText: 'Location',
                    prefixIcon: Icon(Icons.location_on, color: Colors.grey),
                    filled: true,
                    fillColor: Color(0xFF3A3A3A),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),

                // Description field
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    hintText: 'Description',
                    prefixIcon: Icon(Icons.description, color: Colors.grey),
                    filled: true,
                    fillColor: Color(0xFF3A3A3A),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),

                // Search button
                ElevatedButton(
                  onPressed: _isLoading ? null : _searchItems,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8BC34A), // Green accent from login page
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text('SEARCH'),
                ),
              ],
            ),
          ),

          // Results section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF8BC34A)))
                : _hasSearched && _searchResults.isEmpty
                ? const Center(
              child: Text(
                'No items found matching your search criteria',
                style: TextStyle(color: Colors.white70),
              ),
            )
                : !_hasSearched
                ? const Center(
              child: Text(
                'Search for lost or found items',
                style: TextStyle(color: Colors.white70),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final item = _searchResults[index];
                return _buildItemCard(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(Item item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      color: const Color(0xFF2C2C2C), // Dark gray from login page
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: item.status == "FOUND"
            ? const BorderSide(color: Color(0xFF8BC34A), width: 1)
            : const BorderSide(color: Colors.orange, width: 1),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/view_item',
            arguments: item.itemId,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image or category icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _getCategoryColor(item.categoryId),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: item.images != null && item.images!.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    base64Decode(item.images![0].image.split(',')[1]),
                    fit: BoxFit.cover,
                  ),
                )
                    : Center(
                  child: Icon(
                    _getCategoryIcon(item.categoryId),
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.itemName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: item.status == "FOUND" ? const Color(0xFF8BC34A) : Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: const TextStyle(color: Colors.white70),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.locationFound,
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(item.dateTimeFound),
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
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