import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RideStartedScreen extends StatelessWidget {
  const RideStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF232110),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.arrow_back, color: Colors.white),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Trip in progress',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24), // Placeholder for symmetry
                ],
              ),
            ),

            // Driver Info
            _infoTile(
              imageUrl:
              'https://lh3.googleusercontent.com/aida-public/AB6AXuCUZzn15MnvPBTxM_qVjnM7dXMXWzwBXPEXPqlH5HTDFGpr1xfdvHcr0yxYeipwrGBPQqVPl8QtT_pJVv7FEEqaFzIuKK6pFxK_z8KMjC3BTH2h474fUeQYmvuqtBL9qhJMB9UPVbqXFI0mRjQuiFIlvkWlW-MGX6gIe92nhGW36Apl44Q0kJ4DtUpIhq2nReDfnWmRKInCT8SoQP3xG5Nankg_OPjYxdwMWmGQ6_q1gUQd6PZKpj4n1l6axy18kHt5um2y6iNi3x5R',
              title: 'Ethan Carter',
              subtitle: 'Driver',
              isCircle: true,
            ),

            // Vehicle Info
            _infoTile(
              imageUrl:
              'https://lh3.googleusercontent.com/aida-public/AB6AXuAcA9uxpthnPiowga6d16WjvD2VG7pQCGcaBcCcZ0ElXS3PcZw1sYhGMHrCKtGFmyl38q8bHSF0RN-oaXU2coiC5jp2wYatPu_-oudEiuY8KQTtqotQ_HOEWGMJu4DDVdctVd8IB9jrEnRyeSUkbQ9NHNaiUKG60HTN1l7WVn3_L2PP0H997-RJH1xjpoDw0O6tFyqJ_CVDU08pRmoZJSiyS1KOStyIwaPpaJ5GWQx2thWGpdI-t-kWDJzWOs0Ase3U78PgdoJ0xP8G',
              title: 'Toyota Camry',
              subtitle: 'Vehicle',
            ),

            // Trip Map
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuCQESadzAJbqP-kBkjFN73uudVleU38ipQDB4NOnkmzvHQNVWxrvHjZrY5isC12VeeUVb4ADCK9ZPpg8r5LXegHEHb6VTkhyjAQQSGkThkfej_2FWu25E8SlXYRYYTzsLsaiF9g-xz1b07dq36pNUbIVCrRyXZ0QVSD6Juxqo7gTcNTC1XhzqO3UHuae2A-p5rfVK88LEoNIb13vpIxKNkq_hbE3KvVll7tv07-jsDsjcl-Du8bGUmwZ-K0f0463nbOODO8VjyjgIuA',
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ride Started',
                    style: GoogleFonts.notoSans(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: 0.5,
                      backgroundColor: const Color(0xFF686331),
                      valueColor:
                      const AlwaysStoppedAnimation(Color(0xFFEEDB0B)),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _actionButton('Contact Driver', bg: const Color(0xFF494622), textColor: Colors.white),
                  _actionButton('Emergency', bg: const Color(0xFFEEDB0B), textColor: const Color(0xFF232110)),
                ],
              ),
            ),

            const Spacer(),

            // Bottom Sheet (Payment Info)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF232110),
              ),
              child: Column(
                children: [
                  Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF686331),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _infoTile(
                    icon: Icons.attach_money,
                    title: 'Cash',
                    subtitle: 'Payment',
                    bgIconColor: const Color(0xFF494622),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Fare estimate',
                          style: GoogleFonts.notoSans(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '\$25.00',
                          style: GoogleFonts.notoSans(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _infoTile({
    String? imageUrl,
    IconData? icon,
    required String title,
    required String subtitle,
    bool isCircle = false,
    Color bgIconColor = Colors.transparent,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          if (imageUrl != null)
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: isCircle ? null : BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else if (icon != null)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bgIconColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white),
            ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.notoSans(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500)),
              Text(subtitle,
                  style: GoogleFonts.notoSans(
                      fontSize: 14,
                      color: const Color(0xFFcbc690))),
            ],
          )
        ],
      ),
    );
  }

  Widget _actionButton(String text,
      {required Color bg, required Color textColor}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        height: 40,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.notoSans(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
