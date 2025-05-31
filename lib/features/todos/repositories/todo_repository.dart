import 'package:flutter_user_management/core/api/api_client.dart';
import 'package:flutter_user_management/features/todos/models/todo_model.dart';

class TodoRepository {
  final ApiClient apiClient;

  TodoRepository({required this.apiClient});

  Future<List<Todo>> getUserTodos(int userId) async {
    try {
      final response = await apiClient.get('/todos/user/$userId');

      // The DummyJSON API returns todos directly in a 'todos' array
      final todosData = response['todos'] as List<dynamic>;

      final List<Todo> todos = todosData
          .map((todoData) => Todo.fromJson(todoData as Map<String, dynamic>))
          .toList();

      return todos;
    } catch (e) {
      print('Error fetching todos: $e');
      // If API fails, return empty list
      return [];
    }
  }
}
