import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  String id;
  String title;
  String description;
  String category;
  DateTime dueDate;
  bool isCompleted;
  String userId;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.dueDate,
    required this.isCompleted,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "title": title,
      "description": description,
      "category": category,
      "dueDate": dueDate, // Firestore will store this as Timestamp
      "isCompleted": isCompleted,
      "userId": userId,
    };
  }

  static TaskModel fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map["id"],
      title: map["title"],
      description: map["description"],
      category: map["category"],

      // support both Timestamp and String
      dueDate: map["dueDate"] is Timestamp
          ? (map["dueDate"] as Timestamp).toDate()
          : DateTime.parse(map["dueDate"]),

      isCompleted: map["isCompleted"],
      userId: map["userId"],
    );
  }
}
