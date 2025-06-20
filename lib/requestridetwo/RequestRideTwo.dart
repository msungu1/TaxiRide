import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RequestRideTwo extends StatelessWidget {
  const RequestRideTwo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1f1e14),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  Center(
                    child: Text(
                      'Trip in progress',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),


            // Rider Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuAZ-D4amU5Ku_QhxMbVdNMksHDMlwyz-SD3_MmKeLH9C9e2AtvK7OVFNgF2jRQa19xpFf-XBXy8R-BJPpLAsGvQ-FtvUxlVoPu_8BhQPAIp-z2qW3UDoAMpS-Z-MPkvfEGxIjSU7M9mKSWHEsSZPAPRWV19KNHHSK31LNckN50eQqYGgEPqW7hwPTWwJQzuNWq6nXxZJF4G9LYNfHC9_nuNT7_Yx_FrxTgPuKDuxKgb4etxaYH2CKsukcMl_FB5lwg5093GwEhTrAZp',
                    ),

                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sophia Clark',
                        style: GoogleFonts.notoSans(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '254743708135',
                        style: GoogleFonts.notoSans(
                          color: Color(0xFFbebb9d),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Trip Map/Preview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuD1emftmI_A8_6CbLQgEWoasFa56PUggVlcL8hh_CIVP_h33gZi_KusoeNM-ZLALlgsm7hm4QXkllGvVmJfCEAzFjqR1LB3bfuh8tVa7BWiTZI6rh-VqqxlXSev9U4WLQ1JQfMlprxNJ32nq5ofWY3sZp1uCxUVi6gCtGTJSrSvLQfXO72ZwZrr7GQVcF9fJxN6jMZ2d16OeEb_p4yMvgz2HB9xBRrCXVlZU2c8clOh-w7UKFqpvHLNQpdhT_gAR894dNqY6f0BQiVs',
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Pickup and Dropoff
            _locationTile(
              icon: Icons.location_pin,
              title: 'Pickup',
              subtitle: '123 Main St, Ngara Nairobi',
            ),
            _locationTile(
              icon: Icons.location_pin,
              title: 'Dropoff',
              subtitle: 'Parklands Nairobi ',
            ),

            // Trip Details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _tripDetail('Estimated time', '15 min'),
                  _tripDetail('Distance', '5.2 km'),
                ],
              ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Color(0xFF1f1e14),
                        backgroundColor: Color(0xFFEEDB0B),
                        shape: StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Start Trip'),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF403e2b),
                        foregroundColor: Colors.white,
                        shape: StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Contact Rider'),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Bottom Navigation
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF2e2d1f),
                border: Border(
                  top: BorderSide(color: Color(0xFF403e2b)),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  _BottomNavItem(icon: Icons.home, label: 'Home', selected: true),
                  _BottomNavItem(icon: Icons.attach_money, label: 'Earnings'),
                  _BottomNavItem(icon: Icons.account_balance_wallet, label: 'Wallet'),
                  _BottomNavItem(icon: Icons.person, label: 'Account'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationTile({required IconData icon, required String title, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            height: 50,
            width: 48,
            decoration: BoxDecoration(
              color: Color(0xFF403e2b),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.notoSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  color: Color(0xFFbebb9d),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _tripDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.notoSans(color: Color(0xFFbebb9d))),
          Text(value, style: GoogleFonts.notoSans(color: Colors.white)),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : const Color(0xFFbebb9d);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.notoSans(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
