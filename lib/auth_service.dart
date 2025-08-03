import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign Up
  static Future<Map<String, dynamic>> signUp(String email, String password) async {
    try {
      // Create the user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Verify we have a user
      final user = userCredential.user;
      if (user == null) {
        return {'user': null, 'error': 'Failed to create user account'};
      }
      
      // Wait a moment for Firebase to complete the user creation
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Get the current user to ensure everything is properly initialized
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.uid != user.uid) {
        return {'user': null, 'error': 'User account creation incomplete'};
      }
      
      return {'user': currentUser, 'error': null};
    } catch (e) {
      print('Sign Up Error Details: ${e.toString()}');  // More detailed error logging
      String errorMessage;
      if (e.toString().contains('email-already-in-use')) {
        errorMessage = 'This email is already registered';
      } else if (e.toString().contains('weak-password')) {
        errorMessage = 'Password is too weak';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Invalid email address';
      } else if (e.toString().contains('network-request-failed')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('PigeonUserDetails')) {
        // Handle the specific casting error
        await Future.delayed(const Duration(milliseconds: 1000)); // Wait longer
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          return {'user': currentUser, 'error': null};
        }
        errorMessage = 'Error during user creation. Please try again.';
      } else {
        errorMessage = 'Error: ${e.toString()}';
      }
      return {'user': null, 'error': errorMessage};
    }
  }

  // Sign In
  static Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      // Attempt sign in
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Verify we have a user
      final user = userCredential.user;
      if (user == null) {
        return {'user': null, 'error': 'Failed to sign in'};
      }
      
      // Wait a moment for Firebase to complete the sign in
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Get the current user to ensure everything is properly initialized
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.uid != user.uid) {
        return {'user': null, 'error': 'Sign in incomplete'};
      }
      
      return {'user': currentUser, 'error': null};
    } catch (e) {
      print('Sign In Error: $e');
      String errorMessage;
      if (e.toString().contains('user-not-found')) {
        errorMessage = 'No account exists with this email';
      } else if (e.toString().contains('wrong-password')) {
        errorMessage = 'Incorrect password';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Invalid email address';
      } else if (e.toString().contains('invalid-credential')) {
        errorMessage = 'Invalid email or password';
      } else if (e.toString().contains('network-request-failed')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('PigeonUserDetails')) {
        // Handle the specific casting error
        await Future.delayed(const Duration(milliseconds: 1000));
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          return {'user': currentUser, 'error': null};
        }
        errorMessage = 'Error during sign in. Please try again.';
      } else {
        errorMessage = 'Sign in failed: ${e.toString()}';
      }
      return {'user': null, 'error': errorMessage};
    }
  }

  // Save user data to Firestore using UserModel
  static Future<void> saveUserModel(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toMap());
  }

  // Fetch user data from Firestore as UserModel
  static Future<UserModel?> getUserModel(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  // (Legacy) Save user data to Firestore
  static Future<void> saveUserData(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).set(data);
  }

  // Update user profile photo
  static Future<void> updateProfilePhoto(String photoUrl) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updatePhotoURL(photoUrl);
      await _firestore.collection('users').doc(user.uid).update({
        'profilePhotoUrl': photoUrl,
      });
    }
  }
} 