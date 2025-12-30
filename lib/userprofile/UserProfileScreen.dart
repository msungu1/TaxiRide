import 'package:flutter/material.dart';
import 'package:sizemore_taxi/usermodel/UserModel.dart';
import 'package:sizemore_taxi/adminapiservice/admin_api_service.dart';

class UserProfileScreen extends StatefulWidget {
  final UserModel user;

  const UserProfileScreen({super.key, required this.user});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late UserModel _user;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  Future<void> _toggleBlockStatus() async {
    setState(() => _isLoading = true);
    try {
      await AdminApiService.toggleUserStatus(_user.id, !_user.isBlocked);
      setState(() {
        _user = _user.copyWith(isBlocked: !_user.isBlocked); // Assuming copyWith exists
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_user.isBlocked ? 'User blocked' : 'User unblocked'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Are you sure you want to delete this user? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AdminApiService.deleteUser(_user.id);
        Navigator.pop(context); // Go back after deleting
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: ${e.toString()}')),
        );
      }
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_user.name}'),
        backgroundColor: Colors.red.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteUser,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                child: Text(
                  _user.name[0].toUpperCase(),
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _infoRow('Name', _user.name),
            _infoRow('Email', _user.email),
            _infoRow('Phone', _user.phone),
            _infoRow('Role', _user.role),
            if (_user.nationalId != null)
              _infoRow('National ID', _user.nationalId!),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(_user.isBlocked ? Icons.lock_open : Icons.block),
                    label: Text(_user.isBlocked ? 'Unblock User' : 'Block User'),
                    onPressed: _toggleBlockStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _user.isBlocked ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
