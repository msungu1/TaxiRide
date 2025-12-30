import 'package:flutter/material.dart';
import '../adminapiservice/admin_api_service.dart';
import '../feedbackmodel/FeedbackModel.dart'; // Assuming you have this

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({Key? key}) : super(key: key);

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  List<FeedbackModel> feedbackList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFeedback();
  }

  Future<void> fetchFeedback() async {
    setState(() => isLoading = true);
    final feedbacks = await AdminApiService.fetchFeedback();
    setState(() {
      feedbackList = feedbacks;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('User Feedback'),
        backgroundColor: Colors.deepPurple,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
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
                          await AdminApiService
                              .markFeedbackHandled(f.id);
                          Navigator.pop(context);
                          fetchFeedback();
                        },
                      ),
                  ],
                ),
              );
            },
            child: Card(
              margin: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: f.handled
                  ? Colors.green.withOpacity(0.15)
                  : Colors.orange.withOpacity(0.15),
              child: ListTile(
                leading:
                const Icon(Icons.feedback, color: Colors.white),
                title: Text(f.userName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
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
                      style: const TextStyle(
                          fontSize: 12, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      f.timestamp,
                      style: const TextStyle(
                          fontSize: 10, color: Colors.white54),
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
