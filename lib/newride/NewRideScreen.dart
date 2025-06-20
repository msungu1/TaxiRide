import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NewRideScreen extends StatelessWidget {
  const NewRideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF232110),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 16, 8),
                child: Row(
                  children: [
                    const Spacer(),
                    Text(
                      'New ride',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48), // spacing for symmetry
                  ],
                ),
              ),

              // Profile Info
              _infoRow(
                imageUrl:
                "https://lh3.googleusercontent.com/aida-public/AB6AXuDPICzwY6kedOarhgXirgs5Ittp8w_PPjjAg_yCdHcXTQCXVRijlu9GRM2g4MRTY4LOjLwOTtAzG-w9BhgjLM7U2E5GMDHHQ5OeqwOA-j283SJNrRW_w9FM5vuzllOjipaONq5kV8qsHfgcV8CV7f7ufxFhFaSnSLL3RKBpVFfn7sCXXt6--BKAQ-Y2WLFry24sLMtTs-9kjYi6qVcd-lx6N9nbXeGP-lhnqR_d0ch9w8BKKfqzL_wCjFpXLVO4aNATg5hNdcgEwyTr",
                title: "Sophia",
                subtitle: "4.98 • 123 rides",
              ),

              // Pickup
              _infoRow(
                icon: Icons.location_pin,
                title: "Pickup",
                subtitle: "123 Main St",
              ),

              // Destination
              _infoRow(
                icon: Icons.location_pin,
                title: "Destination",
                subtitle: "456 Oak Ave",
              ),

              // Ride Type
              _infoRow(
                icon: Icons.directions_car,
                title: "Economy",
              ),

              // Price
              _infoRow(
                icon: Icons.attach_money,
                title: "\$15.50",
              ),

            ],
          ),

          // Bottom Button
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEEDB0B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    onPressed: () {},
                    child: Text(
                      "Accept",
                      style: GoogleFonts.spaceGrotesk(
                        color: const Color(0xFF232110),
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow({String? imageUrl, IconData? icon, required String title, String? subtitle}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF232110),
      child: Row(
        children: [
          if (imageUrl != null)
            CircleAvatar(
              radius: 28,
              backgroundImage: NetworkImage(imageUrl),
            )
          else if (icon != null)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF494622),
                borderRadius: BorderRadius.circular(8),
              ),
              height: 48,
              width: 48,
              child: Icon(icon, color: Colors.white, size: 28), // 👈 size increased here
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: const Color(0xFFcbc690),
                    ),
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
