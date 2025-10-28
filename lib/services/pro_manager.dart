import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';

class ProManager {
  ProManager._();
  static final ProManager instance = ProManager._();

  // Lắng nghe thay đổi để ẩn/hiện UI theo Pro
  final ValueNotifier<bool> isPro = ValueNotifier(false);

  // Lưu trạng thái Pro theo từng UID để tránh khách (guest) bị Pro
  static const _kPrefix = 'is_pro_demo_uid_';

  Future<void> init() async {
    // Mặc định: chưa đăng nhập => không Pro
    isPro.value = false;

    // Đồng bộ ngay trạng thái hiện tại (nếu đã có user)
    await _loadForUser(AuthService.instance.currentUser?.uid);

    // Theo dõi thay đổi đăng nhập
    AuthService.instance.userChanges.listen((user) {
      _loadForUser(user?.uid);
    });
  }

  String _keyFor(String uid) => '$_kPrefix$uid';

  bool _isAnonymousUser(String? uid) {
    if (uid == null) return true;
    final user = AuthService.instance.currentUser;
    // Check if user is anonymous
    return user?.isAnonymous ?? true;
  }

  Future<void> _loadForUser(String? uid) async {
    final prefs = await SharedPreferences.getInstance();
    if (uid == null || _isAnonymousUser(uid)) {
      // Khách (guest/anonymous): luôn là false
      isPro.value = false;
      return;
    }
    isPro.value = prefs.getBool(_keyFor(uid)) ?? false;
  }

  Future<void> upgrade() async {
    final user = AuthService.instance.currentUser;
    if (user == null || user.isAnonymous) {
      throw StateError('Bạn phải đăng nhập tài khoản thật để nâng cấp Pro. Tài khoản guest không thể nâng cấp.');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFor(user.uid), true);
    isPro.value = true;
  }

  Future<void> downgrade() async {
    final user = AuthService.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    if (user == null) {
      // Khách: đảm bảo false
      isPro.value = false;
      return;
    }
    await prefs.remove(_keyFor(user.uid));
    isPro.value = false;
  }

  Future<void> resetPro() async {
    final user = AuthService.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    if (user == null) {
      isPro.value = false;
      return;
    }
    await prefs.setBool(_keyFor(user.uid), false);
    isPro.value = false;
  }

  bool get isEffectivePro => AuthService.instance.currentUser != null && isPro.value;
}
