import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/errors.dart';

class AuthService {
  AuthService(this._db);

  final SupabaseClient _db;

  Session? get currentSession => _db.auth.currentSession;
  User? get currentUser => _db.auth.currentUser;

  /// Emits the current session first, then every change (sign in / out /
  /// token refresh).
  Stream<Session?> sessionChanges() async* {
    yield _db.auth.currentSession;
    yield* _db.auth.onAuthStateChange.map((e) => e.session);
  }

  Future<void> signIn(String email, String password) async {
    try {
      await guardSupabase(
        () => _db.auth.signInWithPassword(
          email: email.trim(),
          password: password,
        ),
      );
    } on AppException catch (e) {
      final lower = e.message.toLowerCase();
      if (lower.contains('invalid login') ||
          lower.contains('invalid credentials')) {
        throw const AppException('Invalid email or password');
      }
      rethrow;
    }
  }

  Future<void> signOut() => guardSupabase(() => _db.auth.signOut());

  Future<void> updatePassword(String newPassword) {
    if (newPassword.length < 6) {
      throw const ValidationException('Password must be at least 6 characters');
    }
    return guardSupabase(
      () => _db.auth.updateUser(UserAttributes(password: newPassword)),
    );
  }
}
