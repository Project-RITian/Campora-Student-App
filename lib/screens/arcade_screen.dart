import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ritian_v1/widgets/custom_navigation_drawer.dart';
import '../models/stationery_item.dart';
import 'payment_screen.dart';
import 'dart:math';

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
  final FocusNode _instructionsFocusNode = FocusNode();
  final List<StationeryItem> _stationeryItems = [
    StationeryItem(
      id: 1,
      name: "Notebook",
      price: 50,
      stock: 100,
      imageUrl: "https://via.placeholder.com/100x100.png?text=Notebook",
    ),
    StationeryItem(
      id: 2,
      name: "Pen",
      price: 10,
      stock: 200,
      imageUrl: "https://via.placeholder.com/100x100.png?text=Pen",
    ),
    StationeryItem(
      id: 3,
      name: "Pencil",
      price: 5,
      stock: 150,
      imageUrl: "https://via.placeholder.com/100x100.png?text=Pencil",
    ),
    StationeryItem(
      id: 4,
      name: "Eraser",
      price: 3,
      stock: 300,
      imageUrl: "https://via.placeholder.com/100x100.png?text=Eraser",
    ),
  ];
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
    // Test Firebase connectivity
    FirebaseFirestore.instance
        .collection('test')
        .doc('ping')
        .set({'timestamp': FieldValue.serverTimestamp()}).catchError((e) {
      print('Firebase test error: $e');
    });
  }

  @override
  void dispose() {
    _instructionsFocusNode.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  Future<String> _generateUniquePin(String userId) async {
    final random = Random();
    final purchasesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('purchases');
    List<String> existingPins = [];

    final querySnapshot = await purchasesRef.get();
    existingPins =
        querySnapshot.docs.map((doc) => doc['pin'] as String).toList();

    String newPin;
    do {
      newPin = (100 + random.nextInt(900)).toString();
    } while (existingPins.contains(newPin));

    return newPin;
  }

  Future<void> _logPurchase() async {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final purchasesRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('purchases');
      final totalCost = _calculateTotalCost();
      final pin = await _generateUniquePin(user.uid);

      final stationeryItems = _stationeryCart.entries.map((entry) {
        final item = _stationeryItems.firstWhere((i) => i.id == entry.key);
        return {
          'id': item.id,
          'name': item.name,
          'price': item.price,
          'quantity': entry.value,
        };
      }).toList();

      Map<String, dynamic>? xeroxDetails;
      if (_selectedFile != null && _fileUrl != null) {
        xeroxDetails = {
          'fileName': _selectedFile!.path.split('/').last,
          'fileUrl': _fileUrl,
          'copies': _copies,
          'printType': _printType,
          'printSide': _printSide,
          'customInstructions': _customInstructions,
        };
      }

      await purchasesRef.add({
        'type': 'arcade',
        'pin': pin,
        'xeroxDetails': xeroxDetails,
        'stationeryItems': stationeryItems,
        'totalCost': totalCost,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error logging purchase: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging purchase: $e')),
      );
    }
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please sign in to upload files')),
          );
          return;
        }

        _instructionsFocusNode.unfocus();

        Future.microtask(() {
          setState(() {
            _isUploading = true;
          });
        });

        final fileName = file.path.split('/').last;
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('users/${user.uid}/purchases/$fileName');
        final uploadTask = storageRef.putFile(file);
        final snapshot = await uploadTask.whenComplete(() {});
        final downloadUrl = await snapshot.ref.getDownloadURL();

        Future.microtask(() {
          setState(() {
            _selectedFile = file;
            _fileUrl = downloadUrl;
            _isUploading = false;
          });
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File uploaded: $fileName')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file selected')),
        );
      }
    } catch (e) {
      Future.microtask(() {
        setState(() {
          _isUploading = false;
        });
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading file: $e')),
      );
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
      final item = _stationeryItems.firstWhere((i) => i.id == entry.key);
      total += item.price * entry.value;
    }
    return total;
  }

  void _proceedToPayment() async {
    if (_selectedFile == null && _stationeryCart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a file or add stationery items')),
      );
      return;
    }

    final totalCost = _calculateTotalCost();
    if (totalCost <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No items to purchase')),
      );
      return;
    }

    _instructionsFocusNode.unfocus();

    setState(() {
      _isProcessingPayment = true;
    });

    await _buttonController.forward();
    await _buttonController.reverse();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          file: _selectedFile,
          copies: _copies,
          isColor: _printType == 'Color',
          printSide: _printSide,
          customInstructions: _customInstructions,
          stationeryCart: _stationeryCart,
          stationeryItems: _stationeryItems,
          foodCart: {},
          foodItems: [],
          isTakeaway: false,
        ),
      ),
    );

    await _logPurchase();

    setState(() {
      _isProcessingPayment = false;
    });
  }

  void _addToCart(int itemId) {
    setState(() {
      _stationeryCart[itemId] = (_stationeryCart[itemId] ?? 0) + 1;
    });
  }

  void _removeFromCart(int itemId) {
    setState(() {
      if (_stationeryCart[itemId] != null && _stationeryCart[itemId]! > 0) {
        _stationeryCart[itemId] = _stationeryCart[itemId]! - 1;
        if (_stationeryCart[itemId] == 0) _stationeryCart.remove(itemId);
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
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      cacheExtent: 1000,
                      itemCount: _stationeryItems.length,
                      itemBuilder: (context, index) {
                        final item = _stationeryItems[index];
                        final quantity = _stationeryCart[item.id] ?? 0;
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
                              borderRadius: BorderRadius.circular(8.0),
                              child: Container(
                                height: 80,
                                width: 80,
                                decoration: const BoxDecoration(
                                  color: Colors.grey,
                                ),
                                child: Image.network(
                                  item.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.error, size: 50),
                                ),
                              ),
                            ),
                            title: Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                  onTap: () => _removeFromCart(item.id),
                                  child: Container(
                                    padding: const EdgeInsets.all(6.0),
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
                                    padding: const EdgeInsets.all(6.0),
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
