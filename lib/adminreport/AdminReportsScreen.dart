import 'package:flutter/material.dart';
import '../adminapiservice/admin_api_service.dart';
import '../reportmodel/ReportModel.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  List<ReportModel> reports = [];
  bool isLoading = true;
  String statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    fetchReports();
  }

  Future<void> fetchReports() async {
    try {
      final result = await AdminApiService.fetchReports();
      setState(() {
        reports = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = statusFilter == 'All'
        ? reports
        : reports.where((r) => r.status == statusFilter).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('User Reports')),
      body: Column(
        children: [
          DropdownButton<String>(
            value: statusFilter,
            onChanged: (value) => setState(() => statusFilter = value!),
            items: const [
              DropdownMenuItem(value: 'All', child: Text('All')),
              DropdownMenuItem(value: 'Pending', child: Text('Pending')),
              DropdownMenuItem(value: 'Resolved', child: Text('Resolved')),
              DropdownMenuItem(value: 'Escalated', child: Text('Escalated')),
            ],
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final report = filtered[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(report.message),
                    subtitle: Text('Date: ${report.date.toLocal()} \nStatus: ${report.status}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
