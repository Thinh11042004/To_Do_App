// Singleton DB & Repo
import '../features/tasks/data/local/app_database.dart';
import '../features/tasks/data/repositories/task_repository_drift.dart';

class DbService {
  DbService._();
  static final AppDatabase db = AppDatabase();
  static final TaskRepositoryDrift tasks = TaskRepositoryDrift(db);
}
