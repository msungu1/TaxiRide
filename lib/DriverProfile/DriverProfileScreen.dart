import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizemore_taxi/Editprofile/EditProfileScreen.dart';
import 'package:sizemore_taxi/changeemail/ChangeEmailScreen.dart';
import 'package:sizemore_taxi/changepassword/ChangePasswordScreen.dart';
import 'package:sizemore_taxi/changephone/ChangePhoneScreen.dart';
import 'package:sizemore_taxi/help/HelpSupportScreen.dart';
import 'package:sizemore_taxi/privacy/PrivacyPolicyScreen.dart';
import 'package:sizemore_taxi/login_screen/LoginScreen.dart';
import 'package:sizemore_taxi/drivernotification/DriverNotificationsScreen.dart';
import 'package:sizemore_taxi/driverwallet/DriverWalletScreen.dart';
import 'package:sizemore_taxi/DriverTrips/DriverTripsScreen.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  int _selectedIndex = 0;
  bool _onlineStatus = false;
  String? name, email, phone, profilePic, vehicleModel, plateNumber;
  double earningsToday = 0.0;
  double earningsWeek = 0.0;
  double driverRating = 4.8;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }

  Future<void> _loadDriverData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('name') ?? 'Driver';
      email = prefs.getString('email') ?? 'Not set';
      phone = prefs.getString('phone') ?? '';
      profilePic = prefs.getString('profilePic');
      vehicleModel = prefs.getString('vehicleModel') ?? 'Toyota Axio';
      plateNumber = prefs.getString('plateNumber') ?? 'KDA 123A';
      earningsToday = prefs.getDouble('earningsToday') ?? 1500.0;
      earningsWeek = prefs.getDouble('earningsWeek') ?? 7500.0;
    });
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("You have been logged out")),
    );
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  /// ---------- HOME TAB ----------
  // ✅ Quick Action Button Helper
  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.blue.shade50,
            child: Icon(icon, color: Colors.blue, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

// ✅ Updated Home Tab
  Widget _buildHomeTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Driver Info + Online Toggle
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 28,
              backgroundImage: (profilePic != null && profilePic!.isNotEmpty)
                  ? NetworkImage(profilePic!)
                  : const AssetImage("assets/default_avatar.png") as ImageProvider,
            ),
            title: Text(
              name ?? "Driver",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              "⭐ ${driverRating.toStringAsFixed(1)} • ${vehicleModel ?? ""}",
              style: const TextStyle(color: Colors.black54),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _onlineStatus ? "Online" : "Offline",
                  style: TextStyle(
                    fontSize: 10,
                    color: _onlineStatus ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: _onlineStatus,
                  activeColor: Colors.green,
                  onChanged: (val) {
                    setState(() => _onlineStatus = val);
                  },
                ),
              ],
            ),
          ),

          // 🔹 Map Placeholder
          Container(
            height: 220,
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                "🗺️ Map View (Google Maps here)",
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
            ),
          ),
          // 🔹 Quick Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _quickAction(Icons.history, "My Trips", () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverTripsScreen()));
                }),
                _quickAction(Icons.account_balance_wallet, "Wallet", () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverWalletScreen()));
                }),
                _quickAction(Icons.notifications, "Notifications", () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverNotificationsScreen()));
                }),
                _quickAction(Icons.settings, "Settings", () {
                  setState(() => _selectedIndex = 2); // Jump to Account tab
                }),
              ],
            ),
          ),

          const Divider(thickness: 1),

          // 🔹 Daily Summary Card
          Card(
            margin: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    "📊 Today's Summary",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text("Earnings", style: TextStyle(color: Colors.black54)),
                          Text(
                            "Ksh ${earningsToday.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text("Weekly", style: TextStyle(color: Colors.black54)),
                          Text(
                            "Ksh ${earningsWeek.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text("Rating", style: TextStyle(color: Colors.black54)),
                          Text(
                            driverRating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  /// ---------- RIDES TAB ----------
  Widget _buildRidesTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.local_taxi, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text("No active rides",
              style: TextStyle(fontSize: 18, color: Colors.black54)),
        ],
      ),
    );
  }

  /// ---------- ACCOUNT TAB ----------
  /// ---------- ACCOUNT TAB ----------
  Widget _buildAccountTab() {
    return ListView(
      children: [
        // 🔹 Profile Header
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: (profilePic != null && profilePic!.isNotEmpty)
                    ? NetworkImage(profilePic!)
                    : const AssetImage("assets/default_avatar.png") as ImageProvider,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? "Driver",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email ?? "Not set",
                      style: const TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                    Text(
                      phone ?? "",
                      style: const TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${vehicleModel ?? ""} • ${plateNumber ?? ""}",
                      style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                          fontSize: 14),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),

        // 🔹 Settings List
        _SettingsTile(
          title: 'Edit Profile',
          icon: Icons.edit,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EditProfileScreen()),
            );
          },
        ),
        _SettingsTile(
          title: 'Change Email',
          icon: Icons.email,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChangeEmailScreen()),
            );
          },
        ),
        _SettingsTile(
          title: 'Change Phone',
          icon: Icons.phone,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChangePhoneScreen()),
            );
          },
        ),
        _SettingsTile(
          title: 'Change Password',
          icon: Icons.lock,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
            );
          },
        ),
        _SettingsTile(
          title: 'Help & Support',
          icon: Icons.help_outline,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
            );
          },
        ),
        _SettingsTile(
          title: 'Privacy Policy',
          icon: Icons.privacy_tip,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
            );
          },
        ),
        _SettingsTile(
          title: 'Logout',
          icon: Icons.logout,
          onTap: () => _logout(context),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _buildHomeTab(),
      _buildRidesTab(),
      _buildAccountTab(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
        ),
        title: Text(
          _selectedIndex == 0
              ? "Home"
              : _selectedIndex == 1
              ? "Rides"
              : "Account",
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_taxi),
            label: "Rides",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Account",
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent, size: 26),
        title: Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        trailing:
        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
