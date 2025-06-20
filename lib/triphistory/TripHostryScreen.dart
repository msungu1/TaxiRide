import 'package:flutter/material.dart';

class TripHistoryScreen extends StatelessWidget {
  const TripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final trips = [
      {
        'status': 'Completed',
        'pickup': '123 Elm Street',
        'dropoff': '456 Oak Avenue',
        'price': '\$15.50',
      },
      {
        'status': 'Completed',
        'pickup': '789 Pine Street',
        'dropoff': '101 Maple Drive',
        'price': '\$12.75',
      },
      {
        'status': 'Completed',
        'pickup': '222 Cedar Lane',
        'dropoff': '333 Birch Road',
        'price': '\$18.20',
      },
      {
        'status': 'Completed',
        'pickup': '444 Spruce Court',
        'dropoff': '555 Willow Place',
        'price': '\$20.00',
      },
      {
        'status': 'Cancelled',
        'pickup': '666 Ash Street',
        'dropoff': '777 Beech Avenue',
        'price': '\$0.00',
      },
      {
        'status': 'Requested',
        'pickup': '888 Cherry Lane',
        'dropoff': '999 Chestnut Road',
        'price': '\$22.50',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF181611),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181611),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Your Trips',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: const Icon(Icons.arrow_back, color: Colors.white),
      ),
      body: ListView.builder(
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];
          final status = trip['status'];
          IconData icon;
          Color iconColor = Colors.white;

          switch (status) {
            case 'Completed':
              icon = Icons.check_circle;
              break;
            case 'Cancelled':
              icon = Icons.cancel;
              break;
            case 'Requested':
              icon = Icons.access_time;
              break;
            default:
              icon = Icons.help;
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF393428)),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF393428),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${trip['pickup']} • ${trip['dropoff']}',
                        style: const TextStyle(
                          color: Color(0xFFbab19c),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  trip['price']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF27241b),
        selectedItemColor: Colors.black,
        unselectedItemColor: const Color(0xFFbab19c),
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_taxi),
            label: 'Trips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
