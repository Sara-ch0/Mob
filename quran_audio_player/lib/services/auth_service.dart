import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import 'download_service.dart';
import 'notification_service.dart';
import 'resume_service.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db  = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStream => _auth.authStateChanges();

  // ── Register ──────────────────────────────────────────────────────────────
  static Future<String?> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required DateTime birthDate,
  }) async {
    final age = _age(birthDate);
    if (age < 13) return 'You must be at least 13 years old.';

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password,
      );
      await _db.collection('users').doc(cred.user!.uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'birthDate': Timestamp.fromDate(birthDate),
        'createdAt': FieldValue.serverTimestamp(),
        'monthlyGoalHours': 20,
      });
      await DownloadService.init();
      await NotificationService.restoreIfEnabled();
      return null;
    } on FirebaseAuthException catch (e) {
      return _msg(e.code);
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  static Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await DownloadService.init();
      await NotificationService.restoreIfEnabled();
      return null;
    } on FirebaseAuthException catch (e) {
      return _msg(e.code);
    }
  }

  // ── Forgot password ───────────────────────────────────────────────────────
  static Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _msg(e.code);
    }
  }

  // ── Sign out ──────────────────────────────────────────────────────────────
  static Future<void> signOut() async {
    try {
      await audioHandler.stop();
    } catch (_) {}
    await ResumeService.clear();
    await DownloadService.clear();
    await NotificationService.clear();
    await _auth.signOut();
  }

  // ── Get profile ───────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getProfile() async {
    final uid = currentUser?.uid;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static int _age(DateTime dob) {
    final now = DateTime.now();
    int a = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) a--;
    return a;
  }

  static String _msg(String code) {
    switch (code) {
      case 'email-already-in-use': return 'This email is already registered.';
      case 'invalid-email':        return 'Invalid email address.';
      case 'weak-password':        return 'Password must be at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':   return 'Incorrect email or password.';
      case 'too-many-requests':    return 'Too many attempts. Try later.';
      default:                     return 'An error occurred. Please try again.';
    }
  }
}
