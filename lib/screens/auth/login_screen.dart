import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _register = false;
  bool _loading = false;

  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();

  @override
  void dispose() {
    _nameCtl.dispose();
    _emailCtl.dispose();
    _passCtl.dispose();
    super.dispose();
  }

  void _showError(Object e) {
    final msg = (e is FirebaseAuthException && e.message != null)
        ? e.message!
        : e.toString();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submitEmail() async {
    setState(() => _loading = true);
    try {
      if (_register) {
        await AuthService.instance.registerWithEmail(
          email: _emailCtl.text.trim(),
          password: _passCtl.text.trim(),
          displayName: _nameCtl.text.trim(),
        );
      } else {
        await AuthService.instance.signInWithEmail(
          _emailCtl.text.trim(),
          _passCtl.text.trim(),
        );
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _google() async {
    setState(() => _loading = true);
    try {
      await AuthService.instance.signInWithGoogle();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(_register ? 'Đăng ký' : 'Đăng nhập')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _register ? 'Tạo tài khoản mới' : 'Chào mừng quay lại!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          if (_register)
            TextField(
              controller: _nameCtl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Tên hiển thị (tuỳ chọn)',
              ),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailCtl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _passCtl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Mật khẩu'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _loading ? null : _submitEmail,
            child: Text(_register ? 'Đăng ký' : 'Đăng nhập'),
          ),
          const SizedBox(height: 12),
          Row(children: const [
            Expanded(child: Divider()), SizedBox(width: 8), Text('hoặc'), SizedBox(width: 8), Expanded(child: Divider()),
          ]),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.g_mobiledata, size: 28),
            label: const Text('Đăng nhập bằng Google'),
            onPressed: _loading ? null : _google,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _loading ? null : () => setState(() => _register = !_register),
            child: Text(_register ? 'Đã có tài khoản? Đăng nhập' : 'Chưa có tài khoản? Đăng ký'),
          ),
          const SizedBox(height: 24),
          if (_loading)
            Center(
              child: CircularProgressIndicator(color: s.primary),
            ),
        ],
      ),
    );
  }
}
