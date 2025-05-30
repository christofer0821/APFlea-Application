import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final quantityController = TextEditingController();

  String? selectedState;
  String? selectedCity;
  String condition = 'New';
  double quality = 5;

  File? _imageFile;
  bool isLoading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<String> uploadImage(File imageFile) async {
    final fileName = path.basename(imageFile.path);
    final ref = FirebaseStorage.instance.ref().child('listing_images/$fileName');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
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
      final sellerId = FirebaseAuth.instance.currentUser!.uid;

      // Add listing first
      final docRef = await FirebaseFirestore.instance.collection('listings').add({
        'title': titleController.text.trim(),
        'description': descController.text.trim(),
        'price': double.parse(priceController.text.trim()),
        'quantity': int.parse(quantityController.text.trim()),
        'imageUrl': imageUrl,
        'sellerId': sellerId,
        'createdAt': DateTime.now().toIso8601String(),
        'locationState': selectedState,
        'locationCity': selectedCity,
        'condition': condition,
        'quality': quality.round(),
        'approved': false,
        'isSold': false,
      });

      // ✅ Now add the document ID into the same document
      await docRef.update({
        'id': docRef.id,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Listing added successfully!")),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Listing")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Title"),
                validator: (value) => value!.isEmpty ? "Enter title" : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: descController,
                decoration: const InputDecoration(labelText: "Description"),
                validator: (value) => value!.isEmpty ? "Enter description" : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Price"),
                validator: (value) => value!.isEmpty ? "Enter price" : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Quantity"),
                validator: (value) => value!.isEmpty ? "Enter quantity" : null,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: selectedState,
                decoration: const InputDecoration(labelText: "State"),
                items: malaysiaLocations.keys.map((state) {
                  return DropdownMenuItem(value: state, child: Text(state));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedState = value;
                    selectedCity = null;
                  });
                },
                validator: (value) => value == null ? "Please select a state" : null,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: selectedCity,
                decoration: const InputDecoration(labelText: "City"),
                items: selectedState == null
                    ? []
                    : malaysiaLocations[selectedState]!
                        .map((city) => DropdownMenuItem(value: city, child: Text(city)))
                        .toList(),
                onChanged: (value) => setState(() => selectedCity = value),
                validator: (value) => value == null ? "Please select a city" : null,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: condition,
                decoration: const InputDecoration(labelText: "Condition"),
                items: ['New', 'Used'].map((label) {
                  return DropdownMenuItem(value: label, child: Text(label));
                }).toList(),
                onChanged: (value) => setState(() => condition = value!),
              ),
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
                  ? Image.file(_imageFile!, height: 150)
                  : const Text("No image selected"),
              TextButton.icon(
                onPressed: pickImage,
                icon: const Icon(Icons.image),
                label: const Text("Select Image"),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: isLoading ? null : saveListing,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit Listing"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
