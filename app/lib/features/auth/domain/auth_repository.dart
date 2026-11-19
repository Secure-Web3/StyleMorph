import 'package:firebase_auth/firebase_auth.dart';

/// Clean Architecture domain repository interface for StyleMorph authentication & provisioning.
abstract class AuthRepository {
  /// Stream emitting real-time authentication state updates.
  Stream<User?> get authStateChanges;

  /// Returns the currently signed-in user or null.
  User? get currentUser;

  /// Authenticates an existing user using email & password.
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Registers a new user with email & password and provisions their Firestore document.
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Authenticates with Google and provisions the Firestore document if new.
  Future<UserCredential?> signInWithGoogle();

  /// Authenticates with Apple and provisions the Firestore document if new.
  Future<UserCredential?> signInWithApple();

  /// Sends a password reset email to the specified address.
  Future<void> sendPasswordResetEmail({required String email});

  /// Ensures a user record document exists in the `users` Firestore collection.
  Future<void> provisionFirestoreUser(
    User user, {
    required String authProvider,
    String? firstName,
    String? lastName,
  });

  /// Signs out the currently authenticated user.
  Future<void> signOut();
}
