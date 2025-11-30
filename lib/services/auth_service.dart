import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Auth state changes stream
  Stream<firebase_auth.User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Sign in with email and password
  Future<firebase_auth.UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Verify if user has admin role
      await _verifyAdmin(userCredential.user);
      
      return userCredential;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Note: Sign-up functionality removed - this is a private admin dashboard.
  // Admins must be manually added to Firestore after creating their Firebase Auth account.

  // Sign out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // Get current user
  firebase_auth.User? get currentUser => _firebaseAuth.currentUser;

  // Check if user is signed in
  bool get isSignedIn => _firebaseAuth.currentUser != null;

  // Check if current user is admin
  Future<bool> isAdmin() async {
    if (currentUser == null) return false;
    final userDoc = await _firestore.collection('admins').doc(currentUser!.uid).get();
    return userDoc.exists;
  }

  // Verify if user has admin role
  Future<void> _verifyAdmin(firebase_auth.User? user) async {
    if (user == null) throw Exception('User not found');
    
    final userDoc = await _firestore.collection('admins').doc(user.uid).get();
    if (!userDoc.exists) {
      await signOut();
      throw Exception('Access denied. Admin privileges required.');
    }
  }

  // Handle auth exceptions
  Exception _handleAuthException(firebase_auth.FirebaseAuthException e) {
    if (kDebugMode) {
      print('Auth Error: ${e.code} - ${e.message}');
    }
    
    switch (e.code) {
      case 'user-not-found':
        return Exception('No user found for that email.');
      case 'wrong-password':
        return Exception('Incorrect password. Please try again.');
      case 'invalid-email':
        return Exception('The email address is not valid.');
      case 'user-disabled':
        return Exception('This account has been disabled.');
      case 'too-many-requests':
        return Exception('Too many login attempts. Please try again later.');
      case 'operation-not-allowed':
        return Exception('Email/password accounts are not enabled.');
      case 'network-request-failed':
        return Exception('Network error. Please check your connection.');
      case 'email-already-in-use':
        return Exception('An account already exists for that email.');
      case 'weak-password':
        return Exception('The password provided is too weak.');
      default:
        return Exception('An error occurred. Please try again.');
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (currentUser == null) return null;
    
    try {
      final userDoc = await _firestore.collection('admins').doc(currentUser!.uid).get();
      if (userDoc.exists) {
        return {
          'uid': currentUser!.uid,
          'email': currentUser!.email,
          'displayName': currentUser!.displayName,
          'photoURL': currentUser!.photoURL,
          'isAdmin': true,
          ...userDoc.data() ?? {},
        };
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user profile: $e');
      }
      return null;
    }
  }

  // Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    if (currentUser == null) return;
    
    try {
      await currentUser!.updateDisplayName(displayName);
      if (photoURL != null) {
        await currentUser!.updatePhotoURL(photoURL);
      }
      
      // Update in Firestore
      await _firestore.collection('admins').doc(currentUser!.uid).set(
        {
          'displayName': displayName ?? currentUser!.displayName,
          'photoURL': photoURL ?? currentUser!.photoURL,
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error updating profile: $e');
      }
      rethrow;
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Add current user to admins collection (useful if sign-up failed to add them)
  Future<void> addSelfToAdmins() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('No user signed in');
    }

    try {
      await _firestore.collection('admins').doc(user.uid).set({
        'email': user.email ?? '',
        'displayName': user.displayName ?? user.email?.split('@')[0] ?? 'Admin',
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to add user to admins: $e');
    }
  }
}
