import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AIService {
  // Replace YOUR_COMPUTER_IP with your actual local Wi-Fi IP (e.g., 192.168.1.15)
  static const String _localComputerIp = '192.168.0.31'; 

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    } else {
      // Use computer's Wi-Fi IP for physical devices, or 10.0.2.2 for emulator
      return 'http://$_localComputerIp:3000/api';
    }
  }

  static Future<String?> getAIReply(String message) async {
    final url = Uri.parse('$baseUrl/chat');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'message': message}),
          )
          .timeout(const Duration(seconds: 10)); // Added timeout check

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reply'];
      } else {
        print('Server Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Network Exception: $e');
      return null;
    }
  }
}