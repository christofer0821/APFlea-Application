import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String? _selectedTarget;

  int totalUsers = 0;
  int buyers = 0;
  int sellers = 0;
  int totalListings = 0;
  int approvedListings = 0;
  int soldListings = 0;
  int totalRequests = 0;
  int approvedRequests = 0;
  int rejectedRequests = 0;
  int pendingRequests = 0;
  int totalAnnouncements = 0;

  Map<String, int> usersPerDay = {};

  @override
  void initState() {
    super.initState();
    fetchDashboardStats();
  }

  Future<void> _postAnnouncement() async {
    if (_titleController.text.isEmpty ||
        _messageController.text.isEmpty ||
        _selectedTarget == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Fill all fields")));
      return;
    }

    await FirebaseFirestore.instance.collection('announcements').add({
      'title': _titleController.text.trim(),
      'message': _messageController.text.trim(),
      'target': _selectedTarget,
      'createdAt': Timestamp.now(),
    });

    _titleController.clear();
    _messageController.clear();
    setState(() => _selectedTarget = null);

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Announcement posted")));
  }

  Future<void> fetchDashboardStats() async {
    final usersSnapshot =
        await FirebaseFirestore.instance.collection('users').get();
    final listingsSnapshot =
        await FirebaseFirestore.instance.collection('listings').get();
    final requestsSnapshot =
        await FirebaseFirestore.instance.collection('purchase_requests').get();
    final announcementsSnapshot =
        await FirebaseFirestore.instance.collection('announcements').get();

    final dateFormat = DateFormat('yyyy-MM-dd');
    Map<String, int> dailyCount = {};
    for (var doc in usersSnapshot.docs) {
      final ts = (doc['createdAt'] as Timestamp?)?.toDate();
      if (ts != null) {
        final day = dateFormat.format(ts);
        dailyCount[day] = (dailyCount[day] ?? 0) + 1;
      }
    }

    setState(() {
      totalUsers = usersSnapshot.size;
      buyers = usersSnapshot.docs.where((doc) => doc['role'] == 'buyer').length;
      sellers = usersSnapshot.docs.where((doc) => doc['role'] == 'seller').length;
      totalListings = listingsSnapshot.size;
      approvedListings = listingsSnapshot.docs.where((doc) => doc['approved'] == true).length;
      soldListings = listingsSnapshot.docs.where((doc) => doc['isSold'] == true).length;
      totalRequests = requestsSnapshot.size;
      approvedRequests = requestsSnapshot.docs.where((doc) => doc['status'] == 'approved').length;
      rejectedRequests = requestsSnapshot.docs.where((doc) => doc['status'] == 'rejected').length;
      pendingRequests = requestsSnapshot.docs.where((doc) => doc['status'] == 'pending').length;
      totalAnnouncements = announcementsSnapshot.size;
      usersPerDay = dailyCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = const Color(0xFFF5F5F7);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Post Announcement", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _messageController,
              decoration: const InputDecoration(labelText: "Message"),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedTarget,
              decoration: const InputDecoration(labelText: "Target Audience"),
              items: const [
                DropdownMenuItem(value: "buyer", child: Text("Buyers")),
                DropdownMenuItem(value: "seller", child: Text("Sellers")),
                DropdownMenuItem(value: "both", child: Text("Buyers & Sellers")),
              ],
              onChanged: (val) => setState(() => _selectedTarget = val),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _postAnnouncement,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: const Color(0xFF2d8cff),
              ),
              child: const Text("Post Announcement", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 24),

            const Text("Platform Analytics", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildKpiCard("Total Users", totalUsers.toString()),
                _buildKpiCard("Buyers", buyers.toString()),
                _buildKpiCard("Sellers", sellers.toString()),
                _buildKpiCard("Listings", totalListings.toString()),
                _buildKpiCard("Approved Listings", approvedListings.toString()),
                _buildKpiCard("Sold Listings", soldListings.toString()),
                _buildKpiCard("Requests", totalRequests.toString()),
                _buildKpiCard("Approved Requests", approvedRequests.toString()),
                _buildKpiCard("Rejected Requests", rejectedRequests.toString()),
                _buildKpiCard("Pending Requests", pendingRequests.toString()),
                _buildKpiCard("Announcements", totalAnnouncements.toString()),
              ],
            ),
            const SizedBox(height: 24),

            const Text("Request Status Distribution", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(value: approvedRequests.toDouble(), title: 'Approved', color: Colors.green),
                    PieChartSectionData(value: rejectedRequests.toDouble(), title: 'Rejected', color: Colors.red),
                    PieChartSectionData(value: pendingRequests.toDouble(), title: 'Pending', color: Colors.orange),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Text("User Registrations Over Time", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text("X: Date (Daily), Y: New Users", style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            SizedBox(
              height: 240,
              child: LineChart(
                LineChartData(
                  borderData: FlBorderData(show: true),
                  gridData: FlGridData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      color: Colors.deepPurple,
                      spots: usersPerDay.entries.map((e) {
                        final index = usersPerDay.keys.toList().indexOf(e.key).toDouble();
                        return FlSpot(index, e.value.toDouble());
                      }).toList(),
                    )
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 28,
                        getTitlesWidget: (value, _) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, _) {
                          final index = value.toInt();
                          final keys = usersPerDay.keys.toList();
                          return index >= 0 && index < keys.length
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    DateFormat.Md().format(DateTime.parse(keys[index])),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                )
                              : const SizedBox.shrink();
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
