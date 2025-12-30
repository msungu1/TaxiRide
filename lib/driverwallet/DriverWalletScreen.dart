import 'package:flutter/material.dart';

class DriverWalletScreen extends StatelessWidget {
  const DriverWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with real wallet data from backend
    double balance = 12500.0;
    final List<Map<String, dynamic>> transactions = [
      {"date": "Aug 30, 2025", "amount": 350.0, "type": "Ride"},
      {"date": "Aug 29, 2025", "amount": 500.0, "type": "Ride"},
      {"date": "Aug 28, 2025", "amount": -2000.0, "type": "Withdrawal"},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Wallet"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          // 🔹 Balance Card
          Card(
            margin: const EdgeInsets.all(16),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Colors.blueAccent,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Text("Current Balance",
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text("Ksh ${balance.toStringAsFixed(2)}",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Add withdrawal flow
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blueAccent),
                    child: const Text("Withdraw"),
                  )
                ],
              ),
            ),
          ),

          // 🔹 Transactions
          Expanded(
            child: ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final txn = transactions[index];
                final double amount = txn["amount"] as double; // ✅ cast safely

                return ListTile(
                  leading: Icon(
                    amount > 0 ? Icons.arrow_downward : Icons.arrow_upward,
                    color: amount > 0 ? Colors.green : Colors.red,
                  ),
                  title: Text("${txn["type"]}"),
                  subtitle: Text("${txn["date"]}"),
                  trailing: Text(
                    (amount > 0 ? "+ " : "- ") + "Ksh ${amount.abs()}",
                    style: TextStyle(
                        color: amount > 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
