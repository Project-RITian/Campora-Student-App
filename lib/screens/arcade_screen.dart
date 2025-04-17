import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ritian_v1/widgets/custom_navigation_drawer.dart';
import '../models/stationery_item.dart';
import 'payment_screen.dart';

class ArcadeScreen extends StatefulWidget {
  const ArcadeScreen({super.key});

  @override
  _ArcadeScreenState createState() => _ArcadeScreenState();
}

class _ArcadeScreenState extends State<ArcadeScreen> {
  File? _selectedFile;
  int _copies = 1;
  bool _isColor = false;
  String _printSide = 'Single Sided';
  String _customInstructions = '';
  final List<StationeryItem> _stationeryItems = [
    StationeryItem(
      id: 1,
      name: "Notebook",
      price: 50, // Price in RITZ
      stock: 100,
      imageUrl: "https://via.placeholder.com/100x100.png?text=Notebook",
    ),
    StationeryItem(
      id: 2,
      name: "Pen",
      price: 10, // Price in RITZ
      stock: 200,
      imageUrl: "https://via.placeholder.com/100x100.png?text=Pen",
    ),
    StationeryItem(
      id: 3,
      name: "Pencil",
      price: 5, // Price in RITZ
      stock: 150,
      imageUrl: "https://via.placeholder.com/100x100.png?text=Pencil",
    ),
    StationeryItem(
      id: 4,
      name: "Eraser",
      price: 3, // Price in RITZ
      stock: 300,
      imageUrl: "https://via.placeholder.com/100x100.png?text=Eraser",
    ),
  ];
  final Map<int, int> _stationeryCart = {};

  void _selectFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'File selected: ${_selectedFile!.path.split('/').last}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file selected')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting file: $e')),
      );
    }
  }

  void _proceedToPayment() {
    if (_selectedFile == null && _stationeryCart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a file or add stationery items')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          file: _selectedFile,
          copies: _copies,
          isColor: _isColor,
          printSide: _printSide,
          customInstructions: _customInstructions,
          stationeryCart: _stationeryCart,
          stationeryItems: _stationeryItems,
          foodCart: {},
          foodItems: [],
        ),
      ),
    );
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
      appBar: AppBar(title: const Text('Arcade')),
      drawer: const CustomNavigationDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - kToolbarHeight - 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upload File for Xerox',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _selectFile,
                child: const Text('Select File'),
              ),
              if (_selectedFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Selected File: ${_selectedFile!.path.split('/').last}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Copies: '),
                  DropdownButton<int>(
                    value: _copies,
                    items: List.generate(10, (index) => index + 1)
                        .map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString()),
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
              Row(
                children: [
                  const Text('Print Type: '),
                  Row(
                    children: [
                      Radio<bool>(
                        value: false,
                        groupValue: _isColor,
                        onChanged: (value) {
                          setState(() {
                            _isColor = value!;
                          });
                        },
                      ),
                      const Text('B/W'),
                      Radio<bool>(
                        value: true,
                        groupValue: _isColor,
                        onChanged: (value) {
                          setState(() {
                            _isColor = value!;
                          });
                        },
                      ),
                      const Text('Color'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Print Side: '),
                  Row(
                    children: [
                      Radio<String>(
                        value: 'Single Sided',
                        groupValue: _printSide,
                        onChanged: (value) {
                          setState(() {
                            _printSide = value!;
                          });
                        },
                      ),
                      const Text('Single Sided'),
                      Radio<String>(
                        value: 'Front and Back',
                        groupValue: _printSide,
                        onChanged: (value) {
                          setState(() {
                            _printSide = value!;
                          });
                        },
                      ),
                      const Text('Front and Back'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text('Custom Instructions:'),
              TextField(
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter any special instructions...',
                ),
                onChanged: (value) {
                  setState(() {
                    _customInstructions = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Stationery Items',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _stationeryItems.length,
                itemBuilder: (context, index) {
                  final item = _stationeryItems[index];
                  final quantity = _stationeryCart[item.id] ?? 0;
                  return Card(
                    color: Colors.white,
                    child: ListTile(
                      leading: SizedBox(
                        height: 80,
                        width: 80,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
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
                            fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${item.price} RITZ',
                              style: const TextStyle(fontSize: 14)),
                          Text('Stock: ${item.stock}',
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () => _removeFromCart(item.id),
                            iconSize: 16,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 24,
                              minHeight: 24,
                            ),
                          ),
                          Text(
                            quantity.toString(),
                            style: const TextStyle(fontSize: 16),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => _addToCart(item.id),
                            iconSize: 16,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 24,
                              minHeight: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _proceedToPayment,
                child: const Text('Proceed to Payment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}