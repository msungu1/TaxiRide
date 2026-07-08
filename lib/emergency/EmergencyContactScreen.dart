import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:sizemore_taxi/sockets/sockets_service.dart';

class EmergencyContactScreen extends StatefulWidget {
  final String tripId;
  final String triggeredBy;
  final double? lat;
  final double? lng;

  const EmergencyContactScreen({super.key,
    required this.tripId,
    required this.triggeredBy,
    this.lat,
    this.lng,


  });

  @override
  State<EmergencyContactScreen> createState() => _EmergencyContactScreenState();
}

class _EmergencyContactScreenState extends State<EmergencyContactScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> _playEmergencySound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(
        AssetSource('sounds/alert.mp3'),
      );
    } catch (e) {
      debugPrint("Emergency sound error: $e");
    }
  }

  // Future<void> _sendEmergencyAlert() async {
  //   try {
  //     await _playEmergencySound();
  //
  //     SocketService.instance.socket?.emit('emergency_alert', {
  //       'type': 'passenger_emergency',
  //       'triggeredBy': widget.triggeredBy,
  //       'message': '${widget.triggeredBy == 'driver' ? 'Driver' : 'Passenger'} requested emergency assistance',
  //       'tripId': widget.tripId,
  //       'timestamp': DateTime.now().toIso8601String(),
  //     });
  //
  //     if (!mounted) return;
  //     _showSnackBar('Emergency alert sent successfully');
  //   } catch (e) {
  //     debugPrint("Emergency alert error: $e");
  //     if (!mounted) return;
  //     _showSnackBar('Failed to send emergency alert: $e');
  //   }
  // }
  Future<void> _sendEmergencyAlert() async {
    try {
      await _playEmergencySound();

      SocketService.instance.socket?.emit('emergency_alert', {
        'type': 'passenger_emergency',
        'triggeredBy': widget.triggeredBy,
        'message': '${widget.triggeredBy == 'driver' ? 'Driver' : 'Passenger'} requested emergency assistance',
        'tripId': widget.tripId,
        'lat': widget.lat,
        'lng': widget.lng,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      _showSnackBar('Emergency alert sent successfully');
    } catch (e) {
      debugPrint("Emergency alert error: $e");
      if (!mounted) return;
      _showSnackBar('Failed to send emergency alert: $e');
    }
  }
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF221112),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTopContent(context),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopContent(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        const SizedBox(height: 20),
        Text(
          'Need Assistance?',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'In case of an emergency, contact our admin team immediately.',
            style: GoogleFonts.notoSans(
              fontSize: 17,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 30),
        _buildEmergencyButton(),
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'By tapping this button, an emergency alert will instantly be sent to the admin team with your trip details.',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFc89295),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Center(
              child: Text(
                'Contact Admin',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildEmergencyButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFea2832),
          minimumSize: const Size.fromHeight(55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: _sendEmergencyAlert,
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
        label: const Text(
          'Emergency - Contact Admin',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF331a1b),
        border: Border(
          top: BorderSide(color: Color(0xFF472426)),
        ),
      ),

    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = isActive ? Colors.white : const Color(0xFFc89295);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
