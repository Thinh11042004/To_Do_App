// Singleton DB & Repo
import '../models/tasks/data/local/app_database.dart';
import '../models/tasks/data/repositories/task_repository_drift.dart';

class DbService {
  DbService._();
  static final AppDatabase db = AppDatabase();
  static final TaskRepositoryDrift tasks = TaskRepositoryDrift(db);
}
