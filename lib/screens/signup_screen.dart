import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import '../widgets/wave_header.dart';
import 'disclaimer_screen.dart';
import '../services/user_session.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _genderController = TextEditingController();
  final _ageController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _genderController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildCustomTextField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFE8231F), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  TextField(
                    controller: controller,
                    obscureText: obscureText,
                    keyboardType: keyboardType,
                    style: const TextStyle(fontSize: 13, color: Colors.black),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                      isDense: true,
                      contentPadding: const EdgeInsets.only(bottom: 8, top: 2),
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
            ?suffixIcon,
          ],
        ),
      ),
    );
  }

  void _handleSignUp() {
    final firstName = _firstNameController.text.trim();
    final middleName = _middleNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final fullName = '$firstName $lastName'.trim();

    UserSession.firstName = firstName;
    UserSession.middleName = middleName;
    UserSession.lastName = lastName;
    UserSession.name = fullName;
    UserSession.age = _ageController.text.trim();
    UserSession.gender = _genderController.text.trim();
    UserSession.email = _emailController.text.trim();
    UserSession.phone = _phoneController.text.trim();

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
        
        // Ensure former active sessions are cleared so system prompts user selector
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
                  height: 180,
                  child: const Center(child: RxLogo(fontSize: 30)),
                ),
                const HeaderBackButton(),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      children: [
                        TextSpan(text: 'Create Your '),
                        TextSpan(
                          text: 'Account',
                          style: TextStyle(color: Color(0xFFF7931E)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Join us for a Healthier Tomorrow',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),
                  _buildCustomTextField(
                    label: 'First Name',
                    hint: 'Enter your First Name',
                    icon: Icons.person,
                    controller: _firstNameController,
                  ),
                  const SizedBox(height: 12),
                  _buildCustomTextField(
                    label: 'Middle Name',
                    hint: 'Enter your Middle Name',
                    icon: Icons.person,
                    controller: _middleNameController,
                  ),
                  const SizedBox(height: 12),
                  _buildCustomTextField(
                    label: 'Last Name',
                    hint: 'Enter your Last Name',
                    icon: Icons.person,
                    controller: _lastNameController,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCustomTextField(
                          label: 'Gender',
                          hint: 'Pick your Gender',
                          icon: Icons.wc,
                          controller: _genderController,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCustomTextField(
                          label: 'Age',
                          hint: 'Add your Age',
                          icon: Icons.calendar_today_outlined,
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCustomTextField(
                    label: 'Email',
                    hint: 'Enter your Email',
                    icon: Icons.email_outlined,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  _buildCustomTextField(
                    label: 'Phone Number',
                    hint: 'Enter your Phone Number',
                    icon: Icons.phone,
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _buildCustomTextField(
                    label: 'Password',
                    hint: 'Enter your Password',
                    icon: Icons.lock_outline,
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey[500],
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: SizedBox(
                      width: 220,
                      height: 48,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE8231F), Color(0xFFF7931E)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: ElevatedButton(
                          onPressed: _handleSignUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(Icons.arrow_forward, color: Colors.white),
                            ],
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
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[400])),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    Center(
                      child: Container(
                        width: 240,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: _handleGoogleSignIn,
                          borderRadius: BorderRadius.circular(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network(
                                'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
                                height: 22,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.g_mobiledata, size: 28),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Continue with Google',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}