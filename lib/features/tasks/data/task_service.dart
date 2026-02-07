import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'task_model.dart';



class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _taskCollection =
  FirebaseFirestore.instance.collection('tasks');

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  // CREATE TASK
  Future<void> addTask(TaskModel task) async {
    await _taskCollection.doc(task.id).set(task.toMap());
  }

  // GET ALL TASKS FOR CURRENT USER
  Stream<List<TaskModel>> getTasksForUser(String userId) {
    return _firestore
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data()))
          .toList(),
    );
  }



  // EDIT TASK
  Future<void> editTask(String taskId, Map<String, dynamic> data) async {
    await _taskCollection.doc(taskId).update(data);
  }

  // DELETE TASK
  Future<void> deleteTask(String id) async {
    await _taskCollection.doc(id).delete();
  }

  // TOGGLE COMPLETE
  Future<void> toggleTaskCompletion(String id, bool value) async {
    await _taskCollection.doc(id).update({"isCompleted": value});
  }
}
