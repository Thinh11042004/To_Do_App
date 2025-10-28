// Centralized Firebase accessors for repositories.
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/data/repositories/task_repository.dart';
import '../models/data/repositories/task_repository_firebase.dart';

class DbService {
  DbService._();
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;
  static final TaskRepository tasks = TaskRepositoryFirebase(firestore);
}
