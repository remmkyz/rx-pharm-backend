import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_helper.dart';
import '../services/user_session.dart';
import '../widgets/wave_header.dart';
import 'user_info_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import '../widgets/header_notification_bell.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final File? imageFile;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.imageFile,
  });
}

class AskAiScreen extends StatefulWidget {
  const AskAiScreen({super.key});

  @override
  State<AskAiScreen> createState() => _AskAiScreenState();
}

class _AskAiScreenState extends State<AskAiScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _getUserDisplayName({bool fullName = false}) {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    String name = 'User';

    if (firebaseUser?.displayName != null && firebaseUser!.displayName!.isNotEmpty) {
      name = firebaseUser.displayName!;
    } else if (UserSession.name.isNotEmpty && UserSession.name != 'User') {
      name = UserSession.name;
    }

    if (!fullName) {
      return name.split(' ').first;
    }
    return name;
  }

  Future<void> _handleLogout(BuildContext context) async {
    await AuthHelper.performLogout(context);
  }

  Future<void> _send([File? selectedImage]) async {
    final text = _controller.text.trim();
    if (text.isEmpty && selectedImage == null) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
        imageFile: selectedImage,
      ));
      _controller.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      final String backendUrl = 'https://rx-pharm-backend.onrender.com';

      String? imageBase64;
      if (selectedImage != null) {
        final bytes = await selectedImage.readAsBytes();
        imageBase64 = base64Encode(bytes);
      }

      final response = await http.post(
        Uri.parse('$backendUrl/api/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': text,
          if (imageBase64 != null) 'image': imageBase64,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['reply'] ?? 'No response received.';

        if (!mounted) return;
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            text: reply,
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text: 'Error connecting: $e',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    }

    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFFFF6644)),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    _send(File(pickedFile.path));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Color(0xFFFF6644)),
                title: const Text('Take a Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final pickedFile = await picker.pickImage(source: ImageSource.camera);
                  if (pickedFile != null) {
                    _send(File(pickedFile.path));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasMessages = _messages.isNotEmpty;
    final firstName = _getUserDisplayName(fullName: false);
    final fullName = _getUserDisplayName(fullName: true);

    return Scaffold(
      key: _scaffoldKey,
      drawer: _DashboardDrawer(
        fullName: fullName,
        onLogout: () => _handleLogout(context),
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _AskAiHeader(
            onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          Expanded(
            child: hasMessages
                ? _ChatList(
                    messages: _messages,
                    isTyping: _isTyping,
                    scrollController: _scrollController,
                  )
                : _AskAiHero(userName: firstName),
          ),
          _ChatInputBar(
            controller: _controller,
            onSend: () => _send(),
            onPickImage: _pickImage,
          ),
        ],
      ),
    );
  }
}

class _AskAiHeader extends StatelessWidget {
  final VoidCallback onMenuPressed;

  const _AskAiHeader({required this.onMenuPressed});

  @override
  Widget build(BuildContext context) {
    return WaveHeader(
      height: 220,
      child: Stack(
        children: [
          // Centered white-boxed RxLogo
          const Center(
            child: RxLogo(
              width: 110,
              height: 110,
            ),
          ),
          // Top action buttons row (Back / Menu / Notification Bell)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (Navigator.canPop(context)) ...[
                      Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => Navigator.pop(context),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    InkWell(
                      onTap: onMenuPressed,
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.menu, color: Colors.white, size: 26),
                      ),
                    ),
                  ],
                ),
                const HeaderNotificationBell(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AskAiHero extends StatelessWidget {
  final String userName;

  const _AskAiHero({required this.userName});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          children: [
            Text(
              'Hello, $userName',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            RichText(
              textAlign: TextAlign.center,
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  height: 1.2,
                ),
                children: [
                  TextSpan(text: 'How Can I Help\nWith Your\n'),
                  TextSpan(
                    text: 'Medical Concern?',
                    style: TextStyle(
                      color: Color(0xFFFF6644),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Image.asset(
              'assets/images/medicine_illustration.png',
              height: 180,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.medication_liquid_sharp,
                  size: 140,
                  color: const Color(0xFFFF6644).withValues(alpha: 0.2),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatList extends StatelessWidget {
  final List<ChatMessage> messages;
  final bool isTyping;
  final ScrollController scrollController;

  const _ChatList({
    required this.messages,
    required this.isTyping,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length + (isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length && isTyping) {
          return const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'AI is typing...',
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ),
          );
        }

        final msg = messages[index];
        return Align(
          alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: msg.isUser ? const Color(0xFFFF7426) : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (msg.imageFile != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      msg.imageFile!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (msg.text.isNotEmpty) const SizedBox(height: 8),
                ],
                if (msg.text.isNotEmpty)
                  Text(
                    msg.text,
                    style: TextStyle(
                      color: msg.isUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onPickImage;

  const _ChatInputBar({
    required this.controller,
    required this.onSend,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFF6644),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.white, size: 24),
                onPressed: onPickImage,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                decoration: const InputDecoration(
                  hintText: 'Ask anything...',
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFF6644),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white, size: 28),
                onPressed: onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardDrawer extends StatelessWidget {
  final String fullName;
  final VoidCallback onLogout;

  const _DashboardDrawer({
    required this.fullName,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF7F2FA),
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFB074),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      fullName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _DrawerCardMenuItem(
                      icon: Icons.person_outline,
                      title: 'User',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UserInfoScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _DrawerCardMenuItem(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _DrawerCardMenuItem(
                      icon: Icons.access_time,
                      title: 'History',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HistoryScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: const Icon(
                      Icons.logout,
                      color: Color(0xFFFFB074),
                    ),
                    title: const Text(
                      'Log out',
                      style: TextStyle(
                        color: Color(0xFFFFB074),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onLogout();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerCardMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerCardMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFFFFB074),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Color(0xFFFFB074),
        ),
        onTap: onTap,
      ),
    );
  }
}