// AUTO-ADDED: Repository contract
import '../../domain/entities/task_entity.dart';

abstract class TaskRepository {
  Stream<List<TaskEntity>> watchAll({int limit});
  Future<List<TaskEntity>> getAllOnce();
  Future<int> add(TaskEntity task);
  Future<void> update(TaskEntity task);
  Future<void> delete(int id);
}
