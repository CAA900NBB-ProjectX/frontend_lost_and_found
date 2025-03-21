import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../models/item.dart';
import '../services/item_service.dart';
import 'dart:convert';
import '../auth/services/auth_service.dart';

class UploadItemScreen extends StatefulWidget {
  const UploadItemScreen({Key? key}) : super(key: key);

  @override
  State<UploadItemScreen> createState() => _UploadItemScreenState();
}

class _UploadItemScreenState extends State<UploadItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemService = ItemService();

  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  // Authentication service for getting user details
  final _authService = AuthService();
  String _reporterUsername = "";
  String _contactEmail = "";

  int _categoryId = 1; // Default category
  DateTime _dateFound = DateTime.now();
  String _status = "FOUND"; // Default status
  bool _isLoading = false;
  String? _errorMessage;
  Item? _createdItem;

  // Image picking
  final ImagePicker _picker = ImagePicker();
  List<XFile>? _selectedImages;
  List<Uint8List> _imageBytes = [];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser != null && mounted) {
        setState(() {
          _reporterUsername = currentUser.username;
          _contactEmail = currentUser.email;
        });
      }
    } catch (e) {
      print("Error loading user info: $e");
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateFound,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dateFound) {
      setState(() {
        _dateFound = picked;
      });
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = images;
          _loadImageBytes();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking images: $e';
      });
    }
  }

  Future<void> _loadImageBytes() async {
    if (_selectedImages == null) return;

    _imageBytes.clear();
    for (var image in _selectedImages!) {
      try {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes.add(bytes);
        });
      } catch (e) {
        print('Error loading image: $e');
      }
    }
  }

  Future<void> _submitItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _createdItem = null;
    });

    try {
      // Get current user
      final authUser = await _authService.getCurrentUser();
      if (authUser == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please log in to submit an item';
        });
        return;
      }

      // Format date for backend
      final formattedDate = _dateFound.toIso8601String();

      final newItem = Item(
        itemName: _nameController.text,
        description: _descriptionController.text,
        categoryId: _categoryId,
        locationFound: _locationController.text,
        dateTimeFound: formattedDate,
        reportedBy: authUser.username, // Use actual user ID from auth system
        contactInfo: authUser.email,    // Use actual email from auth system
        status: _status,
      );

      // First create the item
      final createdItem = await _itemService.createItem(newItem);

      if (createdItem != null && _imageBytes.isNotEmpty && createdItem.itemId != null) {
        // Then upload images for this item
        for (int i = 0; i < _imageBytes.length; i++) {
          final success = await _itemService.uploadItemImage(
            createdItem.itemId!,
            _imageBytes[i],
            'image_${i + 1}.jpg',
          );

          if (!success) {
            setState(() {
              _errorMessage = 'Warning: Some images may not have uploaded correctly';
            });
          }
        }
      }

      setState(() {
        _isLoading = false;
        if (createdItem != null) {
          _createdItem = createdItem;
          _formKey.currentState!.reset();
          _selectedImages = null;
          _imageBytes.clear();
          _dateFound = DateTime.now();
          _categoryId = 1;
          _status = "FOUND";
        } else {
          _errorMessage = 'Failed to create item. Please try again.';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_status == "FOUND" ? 'Report Found Item' : 'Report Lost Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status selector
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Item Status',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: "FOUND",
                            label: Text('Found Item'),
                            icon: Icon(Icons.search),
                          ),
                          ButtonSegment(
                            value: "LOST",
                            label: Text('Lost Item'),
                            icon: Icon(Icons.help_outline),
                          ),
                        ],
                        selected: {_status},
                        onSelectionChanged: (Set<String> selectedStatus) {
                          setState(() {
                            _status = selectedStatus.first;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  color: Colors.red.shade100,
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (_createdItem != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  color: Colors.green.shade100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Item successfully reported!',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Item ID: ${_createdItem!.itemId}'),
                      Text('Item Name: ${_createdItem!.itemName}'),

                      const SizedBox(height: 8),
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/view_item',
                              arguments: _createdItem!.itemId,
                            );
                          },
                          icon: const Icon(Icons.visibility),
                          label: const Text('View Item'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Image picker
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Item Images',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _pickImages,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Select Images'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8BC34A), // Green accent from login page
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      if (_imageBytes.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _imageBytes.length,
                            itemBuilder: (context, index) {
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 100,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    _imageBytes[index],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Item details form
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name*',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description*',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                value: _categoryId,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Electronics')),
                  DropdownMenuItem(value: 2, child: Text('Clothing')),
                  DropdownMenuItem(value: 3, child: Text('Accessories')),
                  DropdownMenuItem(value: 4, child: Text('Documents')),
                  DropdownMenuItem(value: 5, child: Text('Other')),
                ],
                onChanged: (value) {
                  setState(() {
                    _categoryId = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location Found/Lost*',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter where the item was found/lost';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date Picker
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date Found/Lost',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    DateFormat('yyyy-MM-dd').format(_dateFound),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Display user info (non-editable)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade700),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Your Information",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.person, color: Color(0xFF8BC34A), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          "Username: $_reporterUsername",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.email, color: Color(0xFF8BC34A), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          "Contact: $_contactEmail",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _submitItem,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF8BC34A), // Green accent from login page
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_status == "FOUND" ? 'SUBMIT FOUND ITEM' : 'SUBMIT LOST ITEM'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}