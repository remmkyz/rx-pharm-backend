import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import '../widgets/wave_header.dart';
import 'signup_screen.dart';
import 'disclaimer_screen.dart';
import '../services/user_session.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  late final TapGestureRecognizer _signUpTapRecognizer;

  @override
  void initState() {
    super.initState();
    _signUpTapRecognizer = TapGestureRecognizer()
      ..onTap = () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SignUpScreen()),
        );
      };
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _signUpTapRecognizer.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey[600]),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[400]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[400]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE8231F)),
      ),
    );
  }

  void _handleLogin() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    debugPrint('Login attempt: $email / ${password.isNotEmpty}');

    UserSession.email = email;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DisclaimerScreen()),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      UserCredential? userCredential;

      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        userCredential =
            await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn();

        // Clear existing local sign-in state to show system account chooser
        await googleSignIn.signOut();

        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          if (mounted) setState(() => _isLoading = false);
          return;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final OAuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
      }

      if (userCredential.user != null && mounted) {
        final googleDisplayName = userCredential.user?.displayName ?? '';

        if (googleDisplayName.isNotEmpty) {
          final parts = googleDisplayName.split(' ');
          UserSession.firstName = parts.isNotEmpty ? parts.first : '';
          UserSession.lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
          UserSession.name = googleDisplayName;
        } else {
          UserSession.name = 'User';
        }

        UserSession.email = userCredential.user?.email ?? '';

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DisclaimerScreen()),
        );
      }
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign in with Google: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                WaveHeader(
                  height: 200,
                  child: const Center(child: RxLogo(fontSize: 30)),
                ),
                const HeaderBackButton(),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 28),
                  const Text(
                    'Sign in',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Welcome back! please sign in\nto continue',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _fieldDecoration(
                      hint: 'Email',
                      icon: Icons.email_outlined,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: _fieldDecoration(
                      hint: 'Password',
                      icon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(color: Color(0xFFE8231F)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        elevation: 0,
                      ).copyWith(
                        backgroundColor:
                            WidgetStateProperty.all(Colors.transparent),
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
                            'Login',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[400])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('or', style: TextStyle(color: Colors.grey[600])),
                      ),
                      Expanded(child: Divider(color: Colors.grey[400])),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    Center(
                      child: _SocialIconButton(
                        icon: Icons.g_mobiledata,
                        color: Colors.red,
                        onTap: _handleGoogleSignIn,
                      ),
                    ),
                  const SizedBox(height: 20),
                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                        children: [
                          const TextSpan(text: "Don't have an Account? "),
                          TextSpan(
                            text: 'Sign Up',
                            style: const TextStyle(
                              color: Color(0xFFE8231F),
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: _signUpTapRecognizer,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SocialIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}