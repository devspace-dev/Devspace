import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_service.dart';

/// Result wrapper — avoids throwing exceptions into UI code.
class AuthResult {
  final User? user;
  final String? error;
  bool get success => user != null && error == null;
  const AuthResult({this.user, this.error});
}

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final _auth   = FirebaseAuth.instance;
  final _google = GoogleSignIn(scopes: ['email', 'profile']);

  // ── Change this to your college email domain ─────
  static const String _collegeDomain = 'mnit.ac.in';

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ══════════════════════════════════════════════════════════════════════════
  // GOOGLE SIGN-IN  (with college email gate)
  // ══════════════════════════════════════════════════════════════════════════

  Future<AuthResult> signInWithGoogle() async {
    try {
      // Trigger Google account picker
      final googleUser = await _google.signIn();
      if (googleUser == null) {
        return const AuthResult(error: 'Sign-in cancelled');
      }

      // ── College email gate ──────────────────────
      if (!googleUser.email.endsWith('@$_collegeDomain')) {
        await _google.signOut();
        return AuthResult(
          error: 'Please use your @$_collegeDomain college email to sign in.',
        );
      }

      // Exchange Google token for Firebase credential
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken:     googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      final user   = result.user!;

      // First sign-in: create Firestore user doc
      if (result.additionalUserInfo?.isNewUser == true) {
        await _createFirestoreProfile(user, googleUser.displayName ?? '');
      }

      return AuthResult(user: user);
    } on FirebaseAuthException catch (e) {
      return AuthResult(error: _friendlyError(e.code));
    } catch (e) {
      return AuthResult(error: e.toString());
    }
  }

  Future<void> _createFirestoreProfile(User user, String displayName) async {
    // Derive a readable handle from email prefix
    final handle = user.email!
        .split('@')
        .first
        .replaceAll('.', '_')
        .toLowerCase();

    await FirebaseService.instance.upsertUser(
      // We pass minimal data; user can fill the rest in Edit Profile
      _minimalUser(
        uid:         user.uid,
        name:        displayName.isNotEmpty ? displayName : handle,
        handle:      handle,
        email:       user.email!,
        photoUrl:    user.photoURL ?? '',
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SIGN OUT
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _google.signOut()]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  String _friendlyError(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return 'This email is already linked to another sign-in method.';
      case 'network-request-failed':
        return 'No internet connection. Please try again.';
      default:
        return 'Sign-in failed. Please try again.';
    }
  }

  /// Minimal UserModel stub — only what Firestore needs at first sign-in.
  dynamic _minimalUser({
    required String uid,
    required String name,
    required String handle,
    required String email,
    required String photoUrl,
  }) {
    // We return a plain map here to avoid a circular import with UserModel.
    // FirebaseService.upsertUser accepts a UserModel — swap this if preferred.
    return _MinimalUser(
      uid: uid, name: name, handle: handle, photoUrl: photoUrl);
  }
}

/// Lightweight data class used only during first-time profile creation.
class _MinimalUser {
  final String uid;
  final String name;
  final String handle;
  final String photoUrl;
  const _MinimalUser({
    required this.uid, required this.name,
    required this.handle, required this.photoUrl});
}
