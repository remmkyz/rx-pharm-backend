import 'package:flutter/material.dart';
import '../widgets/wave_header.dart';
import 'dashboard_screen.dart';

class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                WaveHeader(
                  height: 220,
                  child: const SizedBox.shrink(),
                ),
                const HeaderBackButton(),
              ],
            ),
            const SizedBox(height: 24),
            // Shield icon in a soft circle
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE8231F).withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.verified_user,
                color: Color(0xFFE8231F),
                size: 44,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'DISCLAIMER!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE8231F),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
                  children: [
                    TextSpan(
                      text: 'This application is intended to provide '
                          'general health and medication information and is ',
                    ),
                    TextSpan(
                      text: 'NOT',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: ' a substitute for professional medical advice, '
                          'diagnosis, or treatment. This application does not '
                          'prescribe, recommend, or authorize the use of any '
                          'medication without a valid prescription from a '
                          'qualified healthcare professional.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DashboardScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: 0,
                  ).copyWith(
                    backgroundColor: WidgetStateProperty.all(Colors.transparent),
                    shadowColor: WidgetStateProperty.all(Colors.transparent),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE8231F), Color(0xFFF7931E)],
                      ),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: const Text(
                        'Yes, I understand!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
