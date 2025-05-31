import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'item_detail.dart';

class BuyerHomePage extends StatefulWidget {
  const BuyerHomePage({super.key});

  @override
  State<BuyerHomePage> createState() => _BuyerHomePageState();
}

class _BuyerHomePageState extends State<BuyerHomePage> {
  String? selectedCategory;
  double? minPrice;
  double? maxPrice;
  String priceSort = 'Newest';
  String searchQuery = '';

  final List<String> categoryOptions = [
    'Fashion', 'Electronics', 'Books', 'Home', 'Beauty', 'Sports', 'Others'
  ];

  final Color backgroundColor = const Color(0xFFF5F5F7);
  final Color primaryBlue = const Color(0xFF2D8CFF);
  final Color darkText = const Color(0xFF333333);
  final Color mutedText = const Color(0xFF666666);

  Query _buildQuery() {
    Query query = FirebaseFirestore.instance
        .collection('listings')
        .where('approved', isEqualTo: true)
        .where('isSold', isEqualTo: false);

    if (selectedCategory != null && selectedCategory!.isNotEmpty) {
      query = query.where('category', isEqualTo: selectedCategory);
    }

    if (priceSort == 'Lowest') {
      query = query.orderBy('price', descending: false);
    } else if (priceSort == 'Highest') {
      query = query.orderBy('price', descending: true);
    } else {
      query = query.orderBy('createdAt', descending: true);
    }

    return query;
  }

  bool _withinPriceRange(Map<String, dynamic> item) {
    final price = (item['price'] as num).toDouble();
    if (minPrice != null && price < minPrice!) return false;
    if (maxPrice != null && price > maxPrice!) return false;
    return true;
  }

  bool _matchesSearch(Map<String, dynamic> item) {
    if (searchQuery.isEmpty) return true;
    return item['title']
        .toString()
        .toLowerCase()
        .contains(searchQuery.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          "Announcement",
          style: TextStyle(
            color: darkText,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.filter_list, color: darkText),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text("Filter Listings", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              hint: const Text("Select Category"),
              items: categoryOptions
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) => setState(() => selectedCategory = value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: "Min Price"),
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(() => minPrice = double.tryParse(value)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: "Max Price"),
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(() => maxPrice = double.tryParse(value)),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: priceSort,
              items: ['Newest', 'Lowest', 'Highest']
                  .map((s) => DropdownMenuItem(value: s, child: Text("Sort: $s")))
                  .toList(),
              onChanged: (value) => setState(() => priceSort = value!),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.check),
              label: const Text("Apply Filters"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  selectedCategory = null;
                  minPrice = null;
                  maxPrice = null;
                  priceSort = 'Newest';
                });
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: mutedText,
              ),
              child: const Text("Reset Filters"),
            )
          ],
        ),
      ),
      body: Column(
        children: [
          // 🔔 Announcements
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('announcements')
                .where('target', whereIn: ['buyer', 'both'])
                .orderBy('createdAt', descending: true)
                .limit(3)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SizedBox();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: snapshot.data!.docs.map((doc) {
                  final ann = doc.data() as Map<String, dynamic>;
                  return ListTile(
                    leading: const Icon(Icons.announcement, color: Colors.amber),
                    title: Text(ann['title'] ?? "No Title", style: TextStyle(color: darkText)),
                    subtitle: Text(ann['message'] ?? ""),
                  );
                }).toList(),
              );
            },
          ),

          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by title...',
                prefixIcon: const Icon(Icons.search),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: primaryBlue),
                  borderRadius: BorderRadius.circular(8),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),

          // 📦 Listings
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildQuery().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No listings available"));
                }

                final rawListings = snapshot.data!.docs;
                final listings = rawListings
                    .where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return _withinPriceRange(data) && _matchesSearch(data);
                    })
                    .toList();

                if (listings.isEmpty) {
                  return const Center(child: Text("No listings match your filters"));
                }

                return ListView.builder(
                  itemCount: listings.length,
                  itemBuilder: (context, index) {
                    final doc = listings[index];
                    final item = doc.data() as Map<String, dynamic>;

                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: item['imageUrl'] != null
                            ? Image.network(
                                item['imageUrl'],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.image_not_supported),
                        title: Text(item['title'] ?? 'No Title', style: TextStyle(color: darkText)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("RM ${item['price']} • ${item['quantity']} pcs"),
                            Text("${item['locationCity']}, ${item['locationState']}"),
                            Text("Condition: ${item['condition']} | Quality: ${item['quality']}/10"),
                          ],
                        ),
                        onTap: () {
                          item['id'] = doc.id;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ItemDetailPage(item: item),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
