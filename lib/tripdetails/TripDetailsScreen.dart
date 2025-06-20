import 'package:flutter/material.dart';

class TripDetailsScreen extends StatelessWidget {
  const TripDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const darkBg = Color(0xFF171512);
    const lightText = Color(0xFFb5afa1);
    const iconBg = Color(0xFF36332b);

    Widget sectionTitle(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    Widget tripInfoRow(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFFb5afa1), fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: darkBg,
        elevation: 0,
        leading: const Icon(Icons.arrow_back, color: Colors.white),
        centerTitle: true,
        title: const Text('Trip Details',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionTitle('Pickup'),
            ListTile(
              leading: CircleAvatar(backgroundColor: iconBg, child: Icon(Icons.location_pin, color: Colors.white)),
              title: const Text('Pickup Location', style: TextStyle(color: Colors.white)),
              subtitle: Text('123 Elm Street, Ngara', style: TextStyle(color: lightText)),
            ),
            sectionTitle('Dropoff'),
            ListTile(
              leading: CircleAvatar(backgroundColor: iconBg, child: Icon(Icons.location_on, color: Colors.white)),
              title: const Text('Dropoff Location', style: TextStyle(color: Colors.white)),
              subtitle: Text('456 Oak Avenue, Anytown', style: TextStyle(color: lightText)),
            ),
            sectionTitle('Driver'),
            ListTile(
              leading: const CircleAvatar(
                backgroundImage: NetworkImage('https://lh3.googleusercontent.com/...'),
                radius: 28,
              ),
              title: const Text('Ethan Carter', style: TextStyle(color: Colors.white)),
              subtitle: Text('+254743708135', style: TextStyle(color: lightText)),
              trailing: Icon(Icons.phone, color: Colors.white),
            ),
            sectionTitle('Vehicle'),
            ListTile(
              leading: CircleAvatar(backgroundColor: iconBg, child: Icon(Icons.directions_car, color: Colors.white)),
              title: const Text('Car Number: kAZ 789', style: TextStyle(color: Colors.white)),
              subtitle: Text('Sedan', style: TextStyle(color: lightText)),
            ),
            sectionTitle('Trip Information'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  tripInfoRow('Fare', '\$25.00'),
                  tripInfoRow('Status', 'Completed'),
                  tripInfoRow('Scheduled Time', '10:00 AM'),
                  tripInfoRow('Start Time', '10:05 AM'),
                  tripInfoRow('End Time', '10:30 AM'),
                  tripInfoRow('Rating', '5 stars'),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF25231d),
        selectedItemColor: Colors.white,
        unselectedItemColor: lightText,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Rides'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.access_time), label: 'Activity'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}
