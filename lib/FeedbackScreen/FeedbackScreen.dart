
import 'dart:async';
import 'package:flutter/material.dart';
import '../adminapiservice/admin_api_service.dart';
import '../feedbackmodel/FeedbackModel.dart';
import '../sockets/sockets_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({Key? key}) : super(key: key);

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  List<FeedbackModel> feedbackList = [];
  bool isLoading = true;
  String? errorMessage;
  StreamSubscription? _socketSub;

  @override
  void initState() {
    super.initState();
    fetchFeedback();

    // 🔴 live-update while this screen is open
    _socketSub = SocketService.instance.rideUpdates.listen((event) {
      if (!mounted) return;
      if (event['type'] == 'new_feedback') {
        fetchFeedback();
      }
    });
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    super.dispose();
  }

  Future<void> fetchFeedback() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final feedbacks = await AdminApiService.fetchFeedback();
      if (!mounted) return;
      setState(() {
        feedbackList = feedbacks;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Feedback fetch failed: $e");
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('User Feedback'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(onPressed: fetchFeedback, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
            const SizedBox(height: 8),
            Text('Failed to load feedback:\n$errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: fetchFeedback, child: const Text('Retry')),
          ],
        ),
      )
          : feedbackList.isEmpty
          ? const Center(
          child: Text('No feedback available',
              style: TextStyle(color: Colors.white70)))
          : ListView.builder(
        itemCount: feedbackList.length,
        itemBuilder: (context, index) {
          final f = feedbackList[index];
          return GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text('Feedback from ${f.userName}'),
                  content: Text(f.message),
                  actions: [
                    TextButton(
                      child: const Text('Close'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    if (!f.handled)
                      ElevatedButton(
                        child: const Text('Mark Handled'),
                        onPressed: () async {
                          try {
                            await AdminApiService.markFeedbackHandled(f.id);
                          } catch (e) {
                            debugPrint("❌ Mark handled failed: $e");
                          }
                          if (mounted) Navigator.pop(context);
                          fetchFeedback();
                        },
                      ),
                  ],
                ),
              );
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: f.handled
                  ? Colors.green.withOpacity(0.15)
                  : Colors.orange.withOpacity(0.15),
              child: ListTile(
                leading: const Icon(Icons.feedback, color: Colors.white),
                title: Text(f.userName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
                subtitle: Text(
                  f.message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      f.handled ? '✅ Handled' : '⚠️ Unhandled',
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      f.timestamp,
                      style: const TextStyle(fontSize: 10, color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}