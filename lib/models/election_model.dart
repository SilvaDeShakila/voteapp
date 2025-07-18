import 'package:cloud_firestore/cloud_firestore.dart';

class ElectionModel {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> options;
  final Map<String, int> votes;
  final String createdBy;
  final bool isActive;

  ElectionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.options,
    required this.votes,
    required this.createdBy,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDate': startDate,
      'endDate': endDate,
      'options': options,
      'votes': votes,
      'createdBy': createdBy,
      'isActive': isActive,
    };
  }

  factory ElectionModel.fromMap(Map<String, dynamic> map) {
    return ElectionModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      options: List<String>.from(map['options']),
      votes: Map<String, int>.from(map['votes']),
      createdBy: map['createdBy'] as String,
      isActive: map['isActive'] as bool? ?? true,
    );
  }
}