import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final DateTime createdAt;
  final bool isAdmin;
  final String? profilePhotoUrl; // Add this field

  UserModel({
    required this.uid,
    required this.email,
    required this.createdAt,
    this.isAdmin = false,
    this.profilePhotoUrl, // Add this parameter
  });

  // Convert UserModel to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'createdAt': createdAt,
      'isAdmin': isAdmin,
      'profilePhotoUrl': profilePhotoUrl, // Add this field
    };
  }

  // Create UserModel from Firestore map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      email: map['email'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isAdmin: map['isAdmin'] as bool? ?? false,
      profilePhotoUrl: map['profilePhotoUrl'] as String?, // Add this field
    );
  }
}