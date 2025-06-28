import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static Future<void> initializeFirebase() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(); // ✅ Prevent duplicate initialization
    }
  }
}
