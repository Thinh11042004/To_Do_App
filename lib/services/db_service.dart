// Centralized Firebase accessors for repositories.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../models/data/repositories/task_repository.dart';
import '../models/data/repositories/task_repository_firebase.dart';

class DbService {
  DbService._();
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;
  static final TaskRepositoryFirebase _taskRepo = TaskRepositoryFirebase(firestore);
  static TaskRepository get tasks => _taskRepo;

  // Initialize and listen to auth state changes
  static Future<void> init() async {
    final auth = FirebaseAuth.instance;

    // Ensure we always have a Firebase user (anonymous for guests)
    User? user = auth.currentUser;
    if (user == null) {
      try {
        final cred = await auth.signInAnonymously();
        user = cred.user;
        debugPrint('✅ Signed in anonymously: ${user?.uid}');
      } catch (e) {
        debugPrint('⚠️ Anonymous sign-in failed: $e');
        user = auth.currentUser; // last attempt
      }
    }

    debugPrint('📝 Initializing DbService with user: ${user?.uid}');
    
    // Set initial user immediately using the resolved user (if any)
    _taskRepo.setUserId(user?.uid);
    
    if (user == null) {
      debugPrint('⚠️ WARNING: No user available for DbService');
    }

    // Listen to auth state changes
    auth.authStateChanges().listen((user) {
      debugPrint('🔄 Auth state changed: ${user?.uid}');
      _taskRepo.setUserId(user?.uid);
    });
  }
}
