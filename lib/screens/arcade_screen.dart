import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ritian_v1/widgets/custom_navigation_drawer.dart';
import '../models/stationery_item.dart';
import 'payment_screen.dart';

class ArcadeScreen extends StatefulWidget {
  const ArcadeScreen({super.key});

  @override
  _ArcadeScreenState createState() => _ArcadeScreenState();
}

class _ArcadeScreenState extends State<ArcadeScreen>
    with SingleTickerProviderStateMixin {
  File? _selectedFile;
  String? _fileUrl;
  int _copies = 1;
  String _printType = 'B/W';
  String _printSide = 'Single Sided';
  String _customInstructions = '';
  bool _isUploading = false;
  bool _isProcessingPayment = false;
  bool _isLoadingItems = true;
  final FocusNode _instructionsFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  List<StationeryItem> _stationeryItems = [];
  List<StationeryItem> _filteredStationeryItems = [];
  final Map<int, int> _stationeryCart = {};

  late AnimationController _buttonController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.bounceOut),
    );

    FirebaseFirestore.instance
        .collection('test')
        .doc('ping')
        .set({'timestamp': FieldValue.serverTimestamp()}).catchError((e) {
      print('Firebase test error: $e');
    });

    _fetchStationeryItems();

// Listen to search input changes
    _searchController.addListener(_filterStationeryItems);
  }

  Future<void> _fetchStationeryItems() async {
    try {
      setState(() {
        _isLoadingItems = true;
      });

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('stationery_products')
          .get();

      List<StationeryItem> items = snapshot.docs.asMap().entries.map((entry) {
        int index = entry.key;
        var doc = entry.value.data() as Map<String, dynamic>;

        int price;
        if (doc['price'] is num) {
          price = (doc['price'] as num).toInt();
        } else if (doc['price'] is String) {
          price = int.tryParse(doc['price'] as String) ?? 0;
        } else {
          price = 0;
        }

        String name = doc['name'] is String ? doc['name'] : 'Unknown Item';
        String imageUrl = doc['imageUrl'] is String
            ? doc['imageUrl']
            : "https://via.placeholder.com/100x100.png?text=Item";
        int stock = doc['isInStock'] == true ? 100 : 0;

        return StationeryItem(
          id: index + 1,
          name: name,
          price: price,
          stock: stock,
          imageUrl: imageUrl,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _stationeryItems = items;
          _filteredStationeryItems = items; // Initialize filtered list
          _isLoadingItems = false;
        });
        debugPrint('Fetched stationery items: ${_stationeryItems.map((i) => {
              'id': i.id,
              'name': i.name,
              'price': i.price
            }).toList()}');
      }
    } catch (e) {
      print('Error fetching stationery items: $e');
      if (mounted) {
        setState(() {
          _isLoadingItems = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching items: $e')),
        );
      }
    }
  }

  void _filterStationeryItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredStationeryItems = _stationeryItems;
      } else {
        _filteredStationeryItems = _stationeryItems
            .where((item) => item.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _instructionsFocusNode.dispose();
    _searchController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  void _selectFile() async {
    File? file;
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        file = File(result.files.single.path!);
        final user = fb_auth.FirebaseAuth.instance.currentUser;
        if (user == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please sign in to upload files')),
            );
          }
          return;
        }

        _instructionsFocusNode.unfocus();

        Future.microtask(() {
          if (mounted) {
            setState(() {
              _isUploading = true;
            });
          }
        });

        final fileName = file.path.split('/').last;
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('users/${user.uid}/purchases/$fileName');
        final uploadTask = storageRef.putFile(file);
        final snapshot = await uploadTask.whenComplete(() {});
        final downloadUrl = await snapshot.ref.getDownloadURL();

        Future.microtask(() {
          if (mounted) {
            setState(() {
              _selectedFile = file;
              _fileUrl = downloadUrl;
              _isUploading = false;
            });
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('File uploaded: $fileName')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No file selected')),
          );
        }
      }
    } catch (e) {
      Future.microtask(() {
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading file: $e')),
        );
      }
    }
  }

  double _calculateTotalCost() {
    double total = 0.0;
    if (_selectedFile != null) {
      total += _copies * (_printType == 'B/W' ? 1.0 : 2.0);
      if (_printSide == 'Single Sided') {
        total *= 0.9;
      }
    }
    for (var entry in _stationeryCart.entries) {
      final item = _stationeryItems.firstWhere(
        (i) => i.id == entry.key,
        orElse: () => StationeryItem(
            id: entry.key, name: 'Unknown', price: 0, stock: 0, imageUrl: ''),
      );
      total += item.price * entry.value;
    }
    return total;
  }

  void _proceedToPayment() async {
    if (_selectedFile == null && _stationeryCart.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select a file or add stationery items')),
        );
      }
      return;
    }

    final totalCost = _calculateTotalCost();
    if (totalCost <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No items to purchase')),
        );
      }
      return;
    }

    _instructionsFocusNode.unfocus();

    setState(() {
      _isProcessingPayment = true;
    });

    await _buttonController.forward();
    await _buttonController.reverse();

// Create a copy of the cart before passing to PaymentScreen
    final cartCopy = Map<int, int>.from(_stationeryCart);
    debugPrint('Stationery cart before navigating to PaymentScreen: $cartCopy');

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          file: _selectedFile,
          fileUrl: _fileUrl,
          copies: _copies,
          isColor: _printType == 'Color',
          printSide: _printSide,
          customInstructions: _customInstructions,
          stationeryCart: cartCopy,
          stationeryItems: _stationeryItems,
          foodCart: {},
          foodItems: [],
          isTakeaway: false,
        ),
      ),
    );

    if (mounted) {
      setState(() {
        _isProcessingPayment = false;
      });
    }
  }

  void _addToCart(int itemId) {
    setState(() {
      _stationeryCart[itemId] = (_stationeryCart[itemId] ?? 0) + 1;
      debugPrint('Added item $itemId to cart. Current cart: $_stationeryCart');
    });
  }

  void _removeFromCart(int itemId) {
    setState(() {
      if (_stationeryCart[itemId] != null && _stationeryCart[itemId]! > 0) {
        _stationeryCart[itemId] = _stationeryCart[itemId]! - 1;
        if (_stationeryCart[itemId] == 0) _stationeryCart.remove(itemId);
        debugPrint(
            'Removed item $itemId from cart. Current cart: $_stationeryCart');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomNavigationDrawer.buildAppBar(context, 'Arcade'),
      drawer: const CustomNavigationDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0C4D83), Color(0xFF64B5F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Xerox & Stationery',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 500),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upload File for Xerox',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0C4D83),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _isUploading
                          ? const Center(child: CircularProgressIndicator())
                          : GestureDetector(
                              onTap: _selectFile,
                              child: Container(
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF0C4D83),
                                      Color(0xFF64B5F6)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.upload_file,
                                        color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Select File',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      if (_selectedFile != null && !_isUploading)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Text(
                            'Selected File: ${_selectedFile!.path.split('/').last}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Copies: ',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.black87)),
                          DropdownButton<int>(
                            value: _copies,
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: Colors.black87),
                            items: List.generate(10, (index) => index + 1)
                                .map<DropdownMenuItem<int>>((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text(value.toString(),
                                    style: const TextStyle(fontSize: 16)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _copies = value!;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Print Type: ',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.black87)),
                          DropdownButton<String>(
                            value: _printType,
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: Colors.black87),
                            items: ['B/W', 'Color']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value,
                                    style: const TextStyle(fontSize: 16)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _printType = value!;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Print Side: ',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.black87)),
                          DropdownButton<String>(
                            value: _printSide,
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: Colors.black87),
                            items: ['Single Sided', 'Front and Back']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value,
                                    style: const TextStyle(fontSize: 16)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _printSide = value!;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('Custom Instructions:',
                          style:
                              TextStyle(fontSize: 16, color: Colors.black87)),
                      TextField(
                        focusNode: _instructionsFocusNode,
                        maxLines: 3,
                        enabled: !_isUploading,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          hintText: 'Enter any special instructions...',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _customInstructions = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Stationery Items',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0C4D83),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search stationery items...',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        prefixIcon:
                            const Icon(Icons.search, color: Color(0xFF0C4D83)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _isLoadingItems
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredStationeryItems.isEmpty
                            ? const Center(
                                child: Text(
                                  'No items found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                cacheExtent: 1000,
                                itemCount: _filteredStationeryItems.length,
                                itemBuilder: (context, index) {
                                  final item = _filteredStationeryItems[index];
                                  final quantity =
                                      _stationeryCart[item.id] ?? 0;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12.0),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12.0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(8.0),
                                      leading: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        child: Container(
                                          height: 80,
                                          width: 80,
                                          decoration: const BoxDecoration(
                                            color: Colors.grey,
                                          ),
                                          child: Image.network(
                                            item.imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(Icons.error,
                                                        size: 50),
                                          ),
                                        ),
                                      ),
                                      title: Flexible(
                                        child: Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.visible,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${item.price} RITZ',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.teal[300],
                                            ),
                                          ),
                                          Text(
                                            'Stock: ${item.stock}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          GestureDetector(
                                            onTap: () =>
                                                _removeFromCart(item.id),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.all(6.0),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.remove,
                                                size: 16,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8.0),
                                            child: Text(
                                              quantity.toString(),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF0C4D83),
                                              ),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => _addToCart(item.id),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.all(6.0),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFF0C4D83),
                                                    Color(0xFF64B5F6)
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.add,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: _isProcessingPayment
          ? const CircularProgressIndicator()
          : GestureDetector(
              onTap: _proceedToPayment,
              child: AnimatedBuilder(
                animation: _buttonScaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _buttonScaleAnimation.value,
                    child: Container(
                      height: 60,
                      width: 60,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0C4D83), Color(0xFF64B5F6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
