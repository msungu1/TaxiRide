import 'package:flutter/material.dart';
import 'package:sizemore_taxi/adminapiservice/admin_api_service.dart';
import 'package:sizemore_taxi/RatingModel.dart';

class RatingsScreen extends StatefulWidget {
  const RatingsScreen({super.key});

  @override
  State<RatingsScreen> createState() => _RatingsScreenState();
}

class _RatingsScreenState extends State<RatingsScreen> {
  List<RatingModel> ratingsList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRatings();
  }

  Future<void> fetchRatings() async {
    setState(() => isLoading = true);
    try {
      final ratings = await AdminApiService.fetchRatings();
      setState(() {
        ratingsList = ratings;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load ratings: $e")),
      );
    }
  }

  Widget _buildStars(int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < count ? Icons.star : Icons.star_border,
          color: const Color(0xFFFFD60A),
          size: 18,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Driver Ratings'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(onPressed: fetchRatings, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ratingsList.isEmpty
          ? const Center(
        child: Text('No ratings yet', style: TextStyle(color: Colors.white70)),
      )
          : ListView.builder(
        itemCount: ratingsList.length,
        itemBuilder: (context, index) {
          final r = ratingsList[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Colors.white.withOpacity(0.05),
            child: ListTile(
              leading: const Icon(Icons.local_taxi, color: Colors.white),
              title: Text(
                r.driverName,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              subtitle: Text(
                "${r.carModel} • ${r.carNumber}\nRated by ${r.riderName}",
                style: const TextStyle(color: Colors.white70),
              ),
              isThreeLine: true,
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildStars(r.stars),
                  const SizedBox(height: 4),
                  Text(
                    r.timestamp.length >= 10 ? r.timestamp.substring(0, 10) : r.timestamp,
                    style: const TextStyle(fontSize: 10, color: Colors.white54),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}