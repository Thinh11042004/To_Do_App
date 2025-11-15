import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/Pay/upgrade_pro_demo_screen.dart';

class UpgradeFlow {
  const UpgradeFlow._();

  static Future<bool> start(BuildContext context) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final currentUser = AuthService.instance.currentUser;
    final isAnonymous = currentUser?.isAnonymous ?? true;
    
    if (currentUser == null || isAnonymous) {
      final shouldLogin = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Cần đăng nhập'),
          content: const Text('Bạn phải đăng nhập tài khoản thật để nâng cấp tài khoản Pro. Tài khoản guest không thể nâng cấp.'),
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

      final newUser = AuthService.instance.currentUser;
      if (newUser == null || newUser.isAnonymous) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Đăng nhập thất bại hoặc đây là tài khoản guest. Vui lòng đăng nhập bằng tài khoản thật.')),
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