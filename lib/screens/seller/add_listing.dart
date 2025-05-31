import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'seller_main.dart';

class AddListingPage extends StatefulWidget {
  const AddListingPage({super.key});

  @override
  State<AddListingPage> createState() => _AddListingPageState();
}

class _AddListingPageState extends State<AddListingPage> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descController = TextEditingController();
  final priceController = TextEditingController();
  int quantity = 1;
  double quality = 5;

  String? selectedState;
  String? selectedCity;
  String selectedCategory = 'Fashion';
  String condition = 'New';
  File? _imageFile;
  bool isLoading = false;
  final _picker = ImagePicker();

  final Color backgroundColor = const Color(0xFFF5F5F7);
  final Color darkText = const Color(0xFF333333);

  Future<void> pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      final fileName = path.basename(imageFile.path);
      final ref = FirebaseStorage.instance.ref().child('listing_images/$fileName');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint("Image upload failed: $e");
      return null;
    }
  }

  Future<void> saveListing() async {
    if (!_formKey.currentState!.validate() || _imageFile == null || selectedState == null || selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields and select an image.")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final imageUrl = await uploadImage(_imageFile!);
      if (imageUrl == null) throw Exception("Image upload failed");

      final sellerId = FirebaseAuth.instance.currentUser!.uid;

      final docRef = await FirebaseFirestore.instance.collection('listings').add({
        'title': titleController.text.trim(),
        'description': descController.text.trim(),
        'price': double.parse(priceController.text.trim()),
        'quantity': quantity,
        'imageUrl': imageUrl,
        'sellerId': sellerId,
        'createdAt': Timestamp.now(),
        'locationState': selectedState,
        'locationCity': selectedCity,
        'condition': condition,
        'quality': quality.round(),
        'category': selectedCategory,
        'approved': false,
        'isSold': false,
      });

      await docRef.update({'id': docRef.id});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Listing added successfully!")),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SellerMainPage()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildInput(titleController, "Title"),
              _buildInput(descController, "Description"),
              _buildPriceInput(),
              _buildQuantityInput(),

              _buildDropdown("State", selectedState, malaysiaLocations.keys.toList(), (val) {
                setState(() {
                  selectedState = val;
                  selectedCity = null;
                });
              }, required: true),

              if (selectedState != null)
                _buildDropdown("City", selectedCity, malaysiaLocations[selectedState]!, (val) {
                  setState(() => selectedCity = val);
                }, required: true),

              _buildDropdown("Category", selectedCategory, categories, (val) {
                setState(() => selectedCategory = val!);
              }),

              _buildDropdown("Condition", condition, ['New', 'Used'], (val) {
                setState(() => condition = val!);
              }),

              const SizedBox(height: 12),
              Row(
                children: [
                  const Text("Quality (1–10):"),
                  Expanded(
                    child: Slider(
                      value: quality,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: quality.round().toString(),
                      onChanged: (val) => setState(() => quality = val),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              _imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_imageFile!, height: 160, width: double.infinity, fit: BoxFit.cover),
                    )
                  : Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade300,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.image, size: 48, color: Colors.grey),
                    ),
              TextButton.icon(
                onPressed: pickImage,
                icon: const Icon(Icons.image_outlined),
                label: const Text("Select Image"),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : saveListing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2d8cff),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Add Listing", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (value) => value!.isEmpty ? "Enter $label" : null,
      ),
    );
  }

  Widget _buildPriceInput() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: priceController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: "Price",
          prefixText: "RM ",
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          final parsed = double.tryParse(value ?? '');
          if (parsed == null || parsed <= 0) return "Enter a valid price";
          return null;
        },
      ),
    );
  }

  Widget _buildQuantityInput() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Text("Quantity:"),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
          ),
          Text(quantity.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => setState(() => quantity++),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>(
    String label,
    T? value,
    List<T> items,
    Function(T?) onChanged, {
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item.toString()))).toList(),
        onChanged: onChanged,
        validator: required ? (val) => val == null ? "Select $label" : null : null,
      ),
    );
  }

  final List<String> categories = [
    'Fashion', 'Electronics', 'Books', 'Home', 'Beauty', 'Sports', 'Others'
  ];
}

const Map<String, List<String>> malaysiaLocations = {
  'Selangor': ['Shah Alam', 'Petaling Jaya', 'Subang Jaya'],
  'Kuala Lumpur': ['Bukit Bintang', 'Cheras', 'Setapak'],
  'Johor': ['Johor Bahru', 'Batu Pahat', 'Muar'],
  'Penang': ['George Town', 'Butterworth'],
  'Sabah': ['Kota Kinabalu', 'Sandakan'],
  'Sarawak': ['Kuching', 'Miri'],
  'Perak': ['Ipoh', 'Taiping'],
  'Negeri Sembilan': ['Seremban', 'Nilai'],
  'Kelantan': ['Kota Bharu'],
  'Pahang': ['Kuantan', 'Temerloh'],
  'Terengganu': ['Kuala Terengganu'],
  'Melaka': ['Melaka City'],
  'Perlis': ['Kangar'],
  'Putrajaya': ['Presint 1', 'Presint 2'],
  'Labuan': ['Victoria'],
};
