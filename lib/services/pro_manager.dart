import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProManager {
  ProManager._();
  static final ProManager instance = ProManager._();

  // lắng nghe thay đổi để ẩn/hiện UI theo Pro
  final ValueNotifier<bool> isPro = ValueNotifier(false);
  static const _kPro = 'is_pro_demo';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isPro.value = prefs.getBool(_kPro) ?? false;
  }

  Future<void> upgrade() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPro, true);
    isPro.value = true;
  }

  Future<void> downgrade() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPro);
    isPro.value = false;
  }
}
