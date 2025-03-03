import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import '../models/item.dart';
import '../services/item_service.dart';
import '../services/auth_service.dart';
import '../widgets/app_scaffold.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final ItemService _itemService = ItemService();
  final AuthService _authService = AuthService();
  late TabController _tabController;
  List<Item> _allItems = [];
  List<Item> _foundItems = [];
  List<Item> _lostItems = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _itemService.getAllItems();

      if (mounted) {
        setState(() {
          _allItems = items;
          _foundItems = items.where((item) => item.status == "FOUND").toList();
          _lostItems = items.where((item) => item.status == "LOST").toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load items: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Found It!',
      currentRoute: '/home',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadItems,
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Found Items'),
          Tab(text: 'Lost Items'),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
          : TabBarView(
        controller: _tabController,
        children: [
          _buildItemGrid(_foundItems),
          _buildItemGrid(_lostItems),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/upload_item').then((_) => _loadItems());
        },
        label: Text(_tabController.index == 0 ? 'Report Found Item' : 'Report Lost Item'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildItemGrid(List<Item> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text('No items available', style: TextStyle(fontSize: 18)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadItems,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildItemTile(item);
        },
      ),
    );
  }

  Widget _buildItemTile(Item item) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/view_item',
          arguments: item.itemId,
        ).then((_) => _loadItems());
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image or placeholder
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: _getCategoryColor(item.categoryId),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                width: double.infinity,
                child: item.imageIdsList != null && item.imageIdsList!.isNotEmpty
                    ? FutureBuilder<List<int>?>(
                  future: _itemService.getItemImage(item.imageIdsList![0]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData &&
                        snapshot.data != null) {
                      return ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: Image.memory(
                          Uint8List.fromList(snapshot.data!),
                          fit: BoxFit.cover,
                        ),
                      );
                    } else {
                      return Center(
                        child: Icon(
                          _getCategoryIcon(item.categoryId),
                          size: 40,
                          color: Colors.white,
                        ),
                      );
                    }
                  },
                )
                    : Center(
                  child: Icon(
                    _getCategoryIcon(item.categoryId),
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Item details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.getCategoryName(),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Location: ${item.locationFound}',
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Date: ${_formatDate(item.dateTimeFound)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
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