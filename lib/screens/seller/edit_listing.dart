import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;

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
  late TextEditingController quantityController;
  late TextEditingController locationController;

  late String condition;
  late double quality;
  File? _newImageFile;
  bool isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final listing = widget.listing;
    titleController = TextEditingController(text: listing['title']);
    descController = TextEditingController(text: listing['description']);
    priceController = TextEditingController(text: listing['price'].toString());
    quantityController = TextEditingController(text: listing['quantity'].toString());
    locationController = TextEditingController(text: listing['location']);
    condition = listing['condition'];
    quality = (listing['quality'] as num).toDouble();
  }

  Future<void> pickNewImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _newImageFile = File(picked.path));
    }
  }

  Future<String> uploadNewImage(File imageFile) async {
    final fileName = path.basename(imageFile.path);
    final ref = FirebaseStorage.instance.ref().child('listing_images/$fileName');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  Future<void> updateListing() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      String imageUrl = widget.listing['imageUrl'];

      if (_newImageFile != null) {
        imageUrl = await uploadNewImage(_newImageFile!);
      }

      await FirebaseFirestore.instance.collection('listings').doc(widget.docId).update({
        'title': titleController.text.trim(),
        'description': descController.text.trim(),
        'price': double.parse(priceController.text.trim()),
        'quantity': int.parse(quantityController.text.trim()),
        'location': locationController.text.trim(),
        'condition': condition,
        'quality': quality.round(),
        'imageUrl': imageUrl,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Listing updated")),
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
    final listing = widget.listing;

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Listing")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Title"),
                validator: (value) => value!.trim().isEmpty ? "Enter title" : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: descController,
                decoration: const InputDecoration(labelText: "Description"),
                validator: (value) => value!.trim().isEmpty ? "Enter description" : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Price (RM)"),
                validator: (value) {
                  final parsed = double.tryParse(value ?? '');
                  if (parsed == null || parsed <= 0) return "Enter a valid price";
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Quantity"),
                validator: (value) {
                  final parsed = int.tryParse(value ?? '');
                  if (parsed == null || parsed < 1) return "Enter valid quantity";
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: locationController,
                decoration: const InputDecoration(labelText: "Location"),
                validator: (value) => value!.trim().length < 3 ? "Enter a valid location" : null,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: condition,
                decoration: const InputDecoration(labelText: "Condition"),
                items: const [
                  DropdownMenuItem(value: 'New', child: Text("New")),
                  DropdownMenuItem(value: 'Used', child: Text("Used")),
                ],
                onChanged: (value) => setState(() => condition = value!),
              ),
              const SizedBox(height: 12),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Quality (1–10)"),
                  Slider(
                    value: quality,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: quality.round().toString(),
                    onChanged: (value) => setState(() => quality = value),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _newImageFile != null
                  ? Image.file(_newImageFile!, height: 150)
                  : Image.network(listing['imageUrl'], height: 150),
              TextButton.icon(
                onPressed: pickNewImage,
                icon: const Icon(Icons.image),
                label: const Text("Change Image"),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: isLoading ? null : updateListing,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save Changes"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
