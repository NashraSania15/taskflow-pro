import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // SIGN UP
  Future<String?> signup(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 🔔 SEND VERIFICATION EMAIL
      await cred.user!.sendEmailVerification();

      return "success";
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  
// FORGOT PASSWORD
  Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return "success";
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }


  // LOGIN
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return "success";
    } on FirebaseAuthException catch (e) {
      return e.message;     // return error message
    }
  }

  // LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }

  // USER STREAM
  Stream<User?> get userStream => _auth.authStateChanges();


  // DELETE ACCOUNT (AUTH + DATA)
  Future<String?> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return "No user logged in";

      // Delete Firestore user data
      final uid = user.uid;
      await FirebaseFirestore.instance
          .collection("tasks")
          .where("userId", isEqualTo: uid)
          .get()
          .then((snapshot) async {
        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }
      });

      // Delete auth account
      await user.delete();

      return "success";
    } on FirebaseAuthException catch (e) {
      // Usually requires recent login
      return e.code == 'requires-recent-login'
          ? "Please re-login and try again"
          : e.message;
    } catch (e) {
      return "Something went wrong";
    }
  }
}


