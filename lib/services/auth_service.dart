import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _auth = FirebaseAuth.instance;

  Stream<User?> get userChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail(String email, String password) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    if (displayName != null && displayName.trim().isNotEmpty) {
      await cred.user?.updateDisplayName(displayName.trim());
    }
    return cred;
  }

  /// Đăng nhập Google (Firebase)
  Future<UserCredential> signInWithGoogle() async {
    // B1: chọn tài khoản Google
    final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();
    if (gUser == null) {
      throw FirebaseAuthException(code: 'canceled', message: 'Người dùng huỷ đăng nhập Google');
    }
    // B2: lấy token
    final GoogleSignInAuthentication gAuth = await gUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: gAuth.accessToken,
      idToken: gAuth.idToken,
    );
    // B3: đăng nhập Firebase
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    // cố gắng signOut Google nữa cho sạch
    try { await GoogleSignIn().signOut(); } catch (_) {}
    await _auth.signOut();
  }
}
