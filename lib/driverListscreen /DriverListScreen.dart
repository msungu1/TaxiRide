import 'package:flutter/material.dart';
import 'package:sizemore_taxi/usermodel/UserModel.dart';
import 'package:sizemore_taxi/adminapiservice/admin_api_service.dart';

class DriverListScreen extends StatefulWidget {
  const DriverListScreen({super.key});

  @override
  State<DriverListScreen> createState() => _DriverListScreenState();
}

class _DriverListScreenState extends State<DriverListScreen> {
  List<UserModel> allDrivers = [];
  List<UserModel> filteredDrivers = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchDrivers();
  }

  void fetchDrivers() async {
    try {
      final users = await AdminApiService.fetchAllUsers();
      final activeDrivers = users
          .where((u) => u.role.toLowerCase() == 'driver' && !u.isBlocked)
          .toList();
      setState(() {
        allDrivers = activeDrivers;
        filteredDrivers = activeDrivers;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching drivers')),
      );
    }
  }

  void onSearchChanged(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredDrivers = allDrivers.where((user) {
        return user.name.toLowerCase().contains(searchQuery) ||
            user.email.toLowerCase().contains(searchQuery) ||
            user.phone.toLowerCase().contains(searchQuery) ||
            (user.nationalId?.toLowerCase() ?? '').contains(searchQuery);
      }).toList();
    });
  }

  Widget buildUserCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(user.name[0].toUpperCase()),
        ),
        title: Text(user.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${user.email}'),
            Text('Phone: ${user.phone}'),
            Text('Role: ${user.role}'),
            if (user.nationalId != null) Text('ID: ${user.nationalId}'),
          ],
        ),
        trailing: const Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Drivers'),
        backgroundColor: Colors.green.shade700,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by name, email, phone, or ID',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: onSearchChanged,
            ),
          ),
          Expanded(
            child: filteredDrivers.isEmpty
                ? const Center(child: Text('No active drivers found.'))
                : ListView.builder(
              itemCount: filteredDrivers.length,
              itemBuilder: (context, index) =>
                  buildUserCard(filteredDrivers[index]),
            ),
          ),
        ],
      ),
    );
  }
}
