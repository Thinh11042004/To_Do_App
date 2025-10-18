import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/Pay/upgrade_pro_demo_screen.dart';

class UpgradeFlow {
  const UpgradeFlow._();

  static Future<bool> start(BuildContext context) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (AuthService.instance.currentUser == null) {
      final shouldLogin = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Cần đăng nhập'),
          content: const Text('Bạn phải đăng nhập để nâng cấp tài khoản Pro.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Để sau')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Đăng nhập')),
          ],
        ),
      );

      if (shouldLogin != true) {
        return false;
      }

      await navigator.push(MaterialPageRoute(builder: (_) => const LoginScreen()));

      if (AuthService.instance.currentUser == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Đăng nhập thất bại. Vui lòng thử lại.')),
        );
        return false;
      }
    }

    final upgraded = await navigator.push<bool>(
      MaterialPageRoute(builder: (_) => const UpgradeProDemoScreen()),
    );

    return upgraded == true;
  }
}