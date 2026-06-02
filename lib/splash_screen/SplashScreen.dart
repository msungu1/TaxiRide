// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});
//
//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _fadeAnimation;
//   late Animation<double> _scaleAnimation;
//   late Animation<Offset> _slideAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1800), // Slightly slower for elegance
//     );
//
//     _fadeAnimation = CurvedAnimation(
//       parent: _controller,
//       curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
//     );
//
//     _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _controller,
//         curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
//       ),
//     );
//
//     // Adds a rising effect
//     _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
//       CurvedAnimation(
//         parent: _controller,
//         curve: const Interval(0.2, 1.0, curve: Curves.fastOutSlowIn),
//       ),
//     );
//
//     _controller.forward();
//
//     Timer(const Duration(seconds: 8), () {
//       if (mounted) {
//         Navigator.pushReplacementNamed(context, '/login');
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         // NEW: Beautiful Gradient Background
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Color(0xFF2C2C2C), // Dark Charcoal
//               Color(0xFF000000), // Pure Black
//             ],
//           ),
//         ),
//         child: Center(
//           child: FadeTransition(
//             opacity: _fadeAnimation,
//             child: ScaleTransition(
//               scale: _scaleAnimation,
//               child: SlideTransition(
//                 position: _slideAnimation,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     // Icon with a soft Glow
//                     Container(
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         boxShadow: [
//                           BoxShadow(
//                             color: const Color(0xFFFBC02D).withOpacity(0.2),
//                             blurRadius: 40,
//                             spreadRadius: 10,
//                           ),
//                         ],
//                       ),
//                       child: const Icon(
//                         Icons.local_taxi_rounded,
//                         size: 90,
//                         color: Color(0xFFFBC02D), // Signature Yellow
//                       ),
//                     ),
//                     const SizedBox(height: 30),
//                     // Refined Typography
//                     Text(
//                       'SIZEMORETAXI',
//                       style: GoogleFonts.montserrat(
//                         textStyle: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 28,
//                           fontWeight: FontWeight.w900, // Extra Bold
//                           letterSpacing: 8.0,          // High spacing = Premium look
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     // Accent Line
//                     Container(
//                       height: 2,
//                       width: 40,
//                       color: const Color(0xFFFBC02D),
//                     ),
//                     const SizedBox(height: 12),
//                     Text(
//                       'YOUR PREMIUM RIDE',
//                       style: TextStyle(
//                         color: Colors.white.withAlpha(150),
//                         fontSize: 12,
//                         fontWeight: FontWeight.w300,
//                         letterSpacing: 2.0,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Initial Fade In
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
    );

    // Entrance Scale (Pop effect)
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    // Subtle slide up
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // Heartbeat/Pulse effect
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.04), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.04, end: 1.0), weight: 50),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Floating Animation (Y-axis drift)
    _floatAnimation = Tween<double>(begin: 0.0, end: -12.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOutSine),
      ),
    );

    _controller.forward();

    // Adjusted timer to 6 seconds
    Timer(const Duration(seconds: 6), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Match the background gradient from the reference
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2C2C2C), // Dark Charcoal
              Color(0xFF000000), // Pure Black
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- ANIMATED LOGO SECTION (Based on Reference) ---
                    AnimatedBuilder(
                      animation: _floatAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _floatAnimation.value),
                          child: child,
                        );
                      },
                      child: ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          height: 180, // Size matched to reference
                          width: 180,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            // Teal/Cyan color from reference
                            color: Color(0xFF008080),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(90),
                            child: Padding(
                              padding: const EdgeInsets.all(25), // Increased padding
                              child: Image.asset(
                                'assets/images/logo.png', // Switched to logo asset
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.local_taxi_rounded,
                                  size: 70,
                                  color: Color(0xFFFBC02D),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 60), // Increased spacing

                    // --- TEXT SECTION (Based on Reference) ---
                    Text(
                      'SIZEMORETAXI',
                      style: GoogleFonts.montserrat(
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 26, // Matched font size
                          fontWeight: FontWeight.w900,
                          letterSpacing: 6.0, // Matched spacing
                        ),
                      ),
                    ),
                    const SizedBox(height: 15), // Adjusted spacing

                    // Orange Decorative Line (Matched to reference)
                    Container(
                      height: 1.5,
                      width: 40,
                      color: const Color(0xFFE6A23C), // Orange/Gold
                    ),
                    const SizedBox(height: 15), // Adjusted spacing

                    Text(
                      'YOUR PREMIUM RIDE',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10, // Matched font size
                        fontWeight: FontWeight.w300,
                        letterSpacing: 3.0, // Matched spacing
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}