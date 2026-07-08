import 'dart:async';
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
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    fetchDrivers();

    // Keep online status fresh while this screen is open
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) fetchDrivers(silent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void fetchDrivers({bool silent = false}) async {
    if (!silent) setState(() => isLoading = true);
    try {
      final users = await AdminApiService.fetchAllUsers();
      final activeDrivers = users
          .where((u) => u.role.toLowerCase() == 'driver' && !u.isBlocked)
          .toList();

      // Online drivers first
      activeDrivers.sort((a, b) {
        final aOnline = a.isOnline ? 0 : 1;
        final bOnline = b.isOnline ? 0 : 1;
        return aOnline.compareTo(bOnline);
      });

      if (!mounted) return;
      setState(() {
        allDrivers = activeDrivers;
        filteredDrivers = _applySearch(activeDrivers, searchQuery);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error fetching drivers')),
        );
      }
    }
  }

  List<UserModel> _applySearch(List<UserModel> source, String query) {
    if (query.isEmpty) return source;
    return source.where((user) {
      return user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.phone.toLowerCase().contains(query) ||
          (user.nationalId?.toLowerCase() ?? '').contains(query);
    }).toList();
  }

  void onSearchChanged(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredDrivers = _applySearch(allDrivers, searchQuery);
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
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.circle,
              color: user.isOnline ? Colors.green : Colors.grey,
              size: 14,
            ),
            const SizedBox(height: 4),
            Text(
              user.isOnline ? 'Online' : 'Offline',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: user.isOnline ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onlineCount = allDrivers.where((d) => d.isOnline).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Drivers'),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(onPressed: () => fetchDrivers(), icon: const Icon(Icons.refresh)),
        ],
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$onlineCount online now',
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
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