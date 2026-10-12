import 'package:flutter/material.dart';

/// The red-to-orange gradient shape with the curved bottom edge,
/// used at the top of both the Welcome and Login screens.
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
        child: Padding(
          padding: const EdgeInsets.only(bottom: 30),
          child: child,
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
class RxLogo extends StatelessWidget {
  final double fontSize;

  const RxLogo({super.key, this.fontSize = 34});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              height: 1.0,
            ),
            children: const [
              TextSpan(text: 'R'),
              TextSpan(
                text: 'x',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        Text(
          'PHARM',
          style: TextStyle(
            fontSize: fontSize * 0.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
            color: Colors.black,
          ),
        ),
        Text(
          'ASSIST',
          style: TextStyle(
            fontSize: fontSize * 0.28,
            fontWeight: FontWeight.w600,
            letterSpacing: 4,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '— Freedom in every prescription —',
          style: TextStyle(
            fontSize: fontSize * 0.22,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}
