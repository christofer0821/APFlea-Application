import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;

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

class EditListingPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> listing;

  const EditListingPage({super.key, required this.docId, required this.listing});

  @override
  State<EditListingPage> createState() => _EditListingPageState();
}

class _EditListingPageState extends State<EditListingPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController titleController;
  late TextEditingController descController;
  late TextEditingController priceController;
  int quantity = 1;
  double quality = 5;

  String? selectedState;
  String? selectedCity;
  String condition = 'New';
  String selectedCategory = 'Fashion';

  File? _newImageFile;
  final ImagePicker _picker = ImagePicker();
  bool isLoading = false;

  final backgroundColor = const Color(0xFFF5F5F7);
  final highlightBlue = const Color(0xFF2d8cff);

  final List<String> categories = [
    'Fashion', 'Electronics', 'Books', 'Home', 'Beauty', 'Sports', 'Others'
  ];

  @override
  void initState() {
    super.initState();
    final listing = widget.listing;
    titleController = TextEditingController(text: listing['title']);
    descController = TextEditingController(text: listing['description']);
    priceController = TextEditingController(text: listing['price'].toString());
    quantity = listing['quantity'];
    selectedState = listing['locationState'];
    selectedCity = listing['locationCity'];
    condition = listing['condition'];
    quality = (listing['quality'] as num).toDouble();
    selectedCategory = listing['category'] ?? 'Others';
  }

  Future<void> pickNewImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _newImageFile = File(picked.path));
  }

  Future<String> uploadNewImage(File imageFile) async {
    final ref = FirebaseStorage.instance.ref().child('listing_images/${path.basename(imageFile.path)}');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  Future<void> updateListing() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      String imageUrl = widget.listing['imageUrl'];
      if (_newImageFile != null) imageUrl = await uploadNewImage(_newImageFile!);

      await FirebaseFirestore.instance.collection('listings').doc(widget.docId).update({
        'title': titleController.text.trim(),
        'description': descController.text.trim(),
        'price': double.parse(priceController.text.trim()),
        'quantity': quantity,
        'locationState': selectedState,
        'locationCity': selectedCity,
        'condition': condition,
        'quality': quality.round(),
        'category': selectedCategory,
        'imageUrl': imageUrl,
        'updatedAt': Timestamp.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Listing updated")));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
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
              _newImageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_newImageFile!, height: 160, width: double.infinity, fit: BoxFit.cover),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(widget.listing['imageUrl'], height: 160, width: double.infinity, fit: BoxFit.cover),
                    ),
              TextButton.icon(
                onPressed: pickNewImage,
                icon: const Icon(Icons.image_outlined),
                label: const Text("Change Image"),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : updateListing,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: highlightBlue,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
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
}
