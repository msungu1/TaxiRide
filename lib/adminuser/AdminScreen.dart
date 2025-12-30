import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizemore_taxi/usermodel/UserModel.dart';
import 'package:sizemore_taxi/adminapiservice/admin_api_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:csv/csv.dart';
import 'package:sizemore_taxi/feedbackmodel/FeedbackModel.dart';
import 'package:sizemore_taxi/userlist/UserListScreen.dart';
import 'package:sizemore_taxi/driverListscreen /DriverListScreen.dart';
import 'package:sizemore_taxi/passengerlist/PassengerListScreen.dart';
import 'package:sizemore_taxi/blocked/BlockedUserListScreen.dart';
import 'package:sizemore_taxi/FeedbackScreen/FeedbackScreen.dart';

/// Admin Dashboard screen for managing users, feedback, and reports.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<UserModel> users = [];
  List<UserModel> filteredUsers = [];
  List<UserModel> selectedUsers = [];
  bool isLoading = true;

  List<FeedbackModel> feedbackList = [];
  bool isLoadingFeedback = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
    fetchFeedback();
  }

  Future<void> fetchUsers() async {
    try {
      final result = await AdminApiService.fetchAllUsers();
      setState(() {
        users = result;
        filteredUsers = result;
        isLoading = false;
        selectedUsers.clear();
      });
    } catch (e) {
      setState(() => isLoading = false);
      Fluttertoast.showToast(msg: 'Error fetching users: $e');
    }
  }

  Future<void> fetchFeedback() async {
    try {
      final feedback = await AdminApiService.fetchFeedback();
      setState(() {
        feedbackList = feedback;
        isLoadingFeedback = false;
      });
    } catch (e) {
      setState(() => isLoadingFeedback = false);
      Fluttertoast.showToast(msg: 'Error loading feedback: $e');
    }
  }

  Future<void> toggleStatus(UserModel user) async {
    try {
      await AdminApiService.toggleUserStatus(user.id!, !user.isBlocked);
      Fluttertoast.showToast(msg: 'User status updated');
      fetchUsers();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error updating user: $e');
    }
  }

  Future<void> deleteUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.name}?'),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context, false)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AdminApiService.deleteUser(user.id!);
        Fluttertoast.showToast(msg: 'User deleted');
        fetchUsers();
      } catch (e) {
        Fluttertoast.showToast(msg: 'Error deleting user: $e');
      }
    }
  }

  void showUserDetails(UserModel user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("Email: ${user.email}"),
              Text("Phone: ${user.phone}"),
              Text("Role: ${user.role}"),
              Text("National ID: ${user.nationalId}"),
              if (user.role.toLowerCase() == 'driver') ...[
                Text("Car Model: ${user.carModel}"),
                Text("Car Number: ${user.carNumber}"),
                Text("Car Type: ${user.carType}"),
                Text("License Number: ${user.licenseNumber}"),
              ],
              Text("Blocked: ${user.isBlocked}"),
            ],
          ),
        );
      },
    );
  }

  void toggleBulkBlock(bool block) async {
    for (var user in selectedUsers) {
      await AdminApiService.toggleUserStatus(user.id!, block);
    }
    Fluttertoast.showToast(msg: block ? 'Users blocked' : 'Users unblocked');
    fetchUsers();
  }

  void deleteSelectedUsers() async {
    for (var user in selectedUsers) {
      await AdminApiService.deleteUser(user.id!);
    }
    Fluttertoast.showToast(msg: 'Users deleted');
    fetchUsers();
  }

  void exportUsersAsCSV() {
    List<List<String>> rows = [
      ["Name", "Email", "Phone", "Role", "National ID", "Blocked"],
      ...selectedUsers.map((u) => [u.name, u.email, u.phone, u.role, u.nationalId ?? '', u.isBlocked.toString()])
    ];
    String csv = const ListToCsvConverter().convert(rows);
    Fluttertoast.showToast(msg: 'CSV Generated. Copy and paste:\n$csv');
  }

  Widget _buildSquareCard({
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(2, 4),
            )
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }



  /// Navigation card to feedback screen
  Widget feedbackNavigationCard() {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/feedback');
      },
      child: Card(
        color: Colors.orange.withOpacity(0.2),
        margin: const EdgeInsets.all(12),
        child: const ListTile(
          leading: Icon(Icons.feedback, color: Colors.white),
          title: Text('User Feedback', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          subtitle: Text('Tap to view all user feedback', style: TextStyle(color: Colors.white70)),
          trailing: Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalUsers = users.length;
    final activeDrivers = users.where((u) => u.role.toLowerCase() == 'driver' && !u.isBlocked).length;
    final activePassengers = users.where((u) => u.role.toLowerCase() == 'rider' && !u.isBlocked).length;
    final blockedUsers = users.where((u) => u.isBlocked).length;

    return Scaffold(
      backgroundColor: const Color(0xFF0A2647),
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text('Admin Dashboard'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildSquareCard(
                  title: 'Total Users',
                  value: '$totalUsers',
                  color: Colors.blue,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserListScreen())),
                ),
                _buildSquareCard(
                  title: 'Active Drivers',
                  value: '$activeDrivers',
                  color: Colors.green,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverListScreen())),
                ),
                _buildSquareCard(
                  title: 'Active Passengers',
                  value: '$activePassengers',
                  color: Colors.orange,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PassengerListScreen())),
                ),
                _buildSquareCard(
                  title: 'Blocked Users',
                  value: '$blockedUsers',
                  color: Colors.red,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockedUserListScreen())),
                ),
                _buildSquareCard(
                  title: 'User Feedback',
                  value: '${feedbackList.length}',
                  color: Colors.orange, // You can customize this color
                  onTap: () => Navigator.pushNamed(context, '/feedback'),
                ),

              ],
            ),
          ),
          // adminNotifications(),
          // buildFeedbackSection(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        onPressed: () {
          Navigator.pushNamed(context, '/register');
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
