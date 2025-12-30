import 'package:flutter/material.dart';
import 'package:sizemore_taxi/usermodel/UserModel.dart';
import 'package:sizemore_taxi/adminapiservice/admin_api_service.dart';

class BlockedUserListScreen extends StatefulWidget {
  const BlockedUserListScreen({super.key});

  @override
  State<BlockedUserListScreen> createState() => _BlockedUserListScreenState();
}

class _BlockedUserListScreenState extends State<BlockedUserListScreen> {
  List<UserModel> allBlockedUsers = [];
  List<UserModel> filteredBlockedUsers = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchBlockedUsers();
  }

  Future<void> fetchBlockedUsers() async {
    try {
      final users = await AdminApiService.fetchAllUsers();
      setState(() {
        allBlockedUsers = users.where((user) => user.isBlocked).toList();
        filteredBlockedUsers = allBlockedUsers;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching blocked users')),
      );
    }
  }

  void onSearchChanged(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredBlockedUsers = allBlockedUsers.where((user) {
        return user.name.toLowerCase().contains(searchQuery) ||
            user.email.toLowerCase().contains(searchQuery) ||
            user.phone.toLowerCase().contains(searchQuery) ||
            (user.nationalId?.toLowerCase() ?? '').contains(searchQuery);
      }).toList();
    });
  }

  Future<void> toggleBlockStatus(UserModel user) async {
    final newStatus = !user.isBlocked;

    try {
      await AdminApiService.updateUser(user.id, {
        'isBlocked': newStatus,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus ? 'User blocked' : 'User unblocked'),
        ),
      );

      await fetchBlockedUsers(); // Refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating user status')),
      );
    }
  }

  Widget buildUserCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(child: Text(user.name[0].toUpperCase())),
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
        trailing: IconButton(
          icon: Icon(
            user.isBlocked ? Icons.lock_open : Icons.block,
            color: user.isBlocked ? Colors.green : Colors.red,
          ),
          onPressed: () => toggleBlockStatus(user),
          tooltip: user.isBlocked ? 'Unblock User' : 'Block User',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Users'),
        backgroundColor: Colors.red.shade700,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search blocked users...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: onSearchChanged,
            ),
          ),
          Expanded(
            child: filteredBlockedUsers.isEmpty
                ? const Center(child: Text('No blocked users found.'))
                : ListView.builder(
              itemCount: filteredBlockedUsers.length,
              itemBuilder: (context, index) =>
                  buildUserCard(filteredBlockedUsers[index]),
            ),
          ),
        ],
      ),
    );
  }
}
