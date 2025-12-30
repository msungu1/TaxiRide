import 'package:flutter/material.dart';
import 'package:sizemore_taxi/usermodel/UserModel.dart';
import 'package:sizemore_taxi/adminapiservice/admin_api_service.dart';
import 'package:sizemore_taxi/UserProvider/UserProvider.dart';
import 'package:provider/provider.dart'; // ✅ This is mandatory!


class PassengerListScreen extends StatefulWidget {
  const PassengerListScreen({super.key});

  @override
  State<PassengerListScreen> createState() => _PassengerListScreenState();
}

class _PassengerListScreenState extends State<PassengerListScreen> {
  List<UserModel> allPassengers = [];
  List<UserModel> filteredPassengers = [];
  bool isLoading = true;
  String searchQuery = '';
  UserModel? selectedUser;

  @override
  void initState() {
    super.initState();
    fetchPassengers();
  }

  void fetchPassengers() async {
    try {
      final users = await AdminApiService.fetchAllUsers();
      setState(() {
        allPassengers = users
            .where((user) => user.role.toLowerCase() == 'rider')
            .toList();
        filteredPassengers = allPassengers;
        isLoading = false;
        selectedUser = null; // reset selection
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching passengers')),
      );
    }
  }

  void onSearchChanged(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredPassengers = allPassengers.where((user) {
        return user.name.toLowerCase().contains(searchQuery) ||
            user.email.toLowerCase().contains(searchQuery) ||
            user.phone.toLowerCase().contains(searchQuery) ||
            (user.nationalId?.toLowerCase() ?? '').contains(searchQuery);
      }).toList();
    });
  }

  Widget buildUserCard(UserModel user) {
    final isSelected = selectedUser?.id == user.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedUser = isSelected ? null : user;
        });
      },
      child: Card(
        color: isSelected ? Colors.red.shade100 : null,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: ListTile(
          leading: CircleAvatar(child: Text(user.name[0].toUpperCase())),
          title: Text(user.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email: ${user.email}'),
              Text('Phone: ${user.phone}'),
              if (user.nationalId != null) Text('ID: ${user.nationalId}'),
            ],
          ),
          trailing: Icon(
            Icons.check_circle,
            color: user.isBlocked ? Colors.grey : Colors.green,
          ),
        ),
      ),
    );
  }

  Widget buildActionButtons() {
    if (selectedUser == null) return const SizedBox.shrink();

    final currentAdminId =Provider.of<UserProvider>(context, listen: false).id;
    final isSelfAction = selectedUser!.id == currentAdminId;

    void showSelfActionWarning(String action) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You can't $action your own admin account.")),
      );
    }


    return Padding(
      padding: const EdgeInsets.all(10),
      child: Wrap(
        spacing: 10,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.block),
            label: const Text('Block'),
            onPressed: selectedUser == null || selectedUser!.isBlocked
                ? null
                : () async {
              if (isSelfAction) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("You can't perform this action on your own account."),
                  ),
                );
                return;
              }

              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Confirm Block"),
                  content: const Text("Are you sure you want to block this user?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text("Block", style: TextStyle(color: Colors.orange)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await AdminApiService.blockUser(selectedUser!.id);
                fetchPassengers();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          ),

          ElevatedButton.icon(
            icon: const Icon(Icons.lock_open),
            label: const Text('Unblock'),
            onPressed: selectedUser == null || !selectedUser!.isBlocked
                ? null
                : () async {
              if (isSelfAction) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("You can't perform this action on your own account."),
                  ),
                );
                return;
              }

              await AdminApiService.unblockUser(selectedUser!.id);
              fetchPassengers();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),

          ElevatedButton.icon(
            icon: const Icon(Icons.delete),
            label: const Text('Delete'),
            onPressed: selectedUser == null
                ? null
                : () async {
              if (isSelfAction) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("You can't perform this action on your own account."),
                  ),
                );
                return;
              }

              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Confirm Delete"),
                  content: const Text("Are you sure you want to delete this user?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text("Delete", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await AdminApiService.deleteUser(selectedUser!.id);
                fetchPassengers();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),

          ElevatedButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text('Edit'),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/edit_user',
                arguments: selectedUser,
              );
            },
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Passengers'),
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
                hintText: 'Search passengers...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: onSearchChanged,
            ),
          ),
          Expanded(
            child: filteredPassengers.isEmpty
                ? const Center(child: Text('No passengers found.'))
                : ListView.builder(
              itemCount: filteredPassengers.length,
              itemBuilder: (context, index) =>
                  buildUserCard(filteredPassengers[index]),
            ),
          ),
          buildActionButtons(),
        ],
      ),
    );
  }
}
