import 'package:flutter/material.dart';

/// The red-to-orange gradient shape with the curved bottom edge,
/// used at the top of authentication and main screens.
class WaveHeader extends StatelessWidget {
  final double height;
  final Widget child;

  const WaveHeader({
    super.key,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _WaveClipper(),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8231F), // red
              Color(0xFFF7931E), // orange
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Center(
            child: child,
          ),
        ),
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height + 40,
      size.width,
      size.height - 40,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// A small circular back button, meant to sit in a Stack on top of a
/// WaveHeader. Only renders if there's actually a previous screen to
/// go back to.
class HeaderBackButton extends StatelessWidget {
  const HeaderBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Navigator.canPop(context)) return const SizedBox.shrink();

    return Positioned(
      top: 16,
      left: 16,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 2,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => Navigator.pop(context),
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
          ),
        ),
      ),
    );
  }
}

/// The branded RxLogo enclosed in a white rounded container card with shadow.
class RxLogo extends StatelessWidget {
  final double width;
  final double height;

  const RxLogo({
    super.key,
    this.width = 115,
    this.height = 115,
    double? fontSize, // Kept for backwards compatibility if passed elsewhere
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Graphic "Rx" Icon styling
          SizedBox(
            height: 38,
            width: 44,
            child: Stack(
              children: [
                const Positioned(
                  left: 2,
                  top: 0,
                  child: Text(
                    'P',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2C3137),
                      height: 1.0,
                    ),
                  ),
                ),
                Positioned(
                  left: 2,
                  top: 8,
                  child: Container(
                    width: 4.5,
                    height: 28,
                    color: const Color(0xFF2C3137),
                  ),
                ),
                const Positioned(
                  right: 2,
                  bottom: 2,
                  child: Text(
                    'x',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFF4711E),
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),

          // PHARM Text
          const Text(
            'PHARM',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.2,
              color: Color(0xFF2C3137),
              height: 1.0,
            ),
          ),
          const SizedBox(height: 1),

          // ASSIST Text
          const Text(
            'ASSIST',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.4,
              color: Color(0xFFF4711E),
              height: 1.0,
            ),
          ),
          const SizedBox(height: 3),

          // Tagline Divider
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 6, height: 0.8, color: Colors.grey.shade400),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  'PRECISION IN EVERY PRESCRIPTION',
                  style: TextStyle(
                    fontSize: 3.8,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    color: Color(0xFF2C3137),
                  ),
                ),
              ),
              Container(width: 6, height: 0.8, color: Colors.grey.shade400),
            ],
          ),
        ],
      ),
    );
  }
}