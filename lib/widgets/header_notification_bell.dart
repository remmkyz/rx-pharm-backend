import 'package:flutter/material.dart';
import '../services/user_data_service.dart';

class HeaderNotificationBell extends StatelessWidget {
  const HeaderNotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: UserDataService.hasActiveNotifications(),
      builder: (context, snapshot) {
        final hasBadge = snapshot.data ?? true;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_none, color: Colors.white, size: 26),
            if (hasBadge)
              Positioned(
                right: -1,
                top: -1,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}