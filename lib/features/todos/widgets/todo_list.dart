import 'package:flutter/material.dart';
import 'package:flutter_user_management/features/todos/models/todo_model.dart';

class TodoList extends StatelessWidget {
  final List<Todo> todos;

  const TodoList({
    super.key,
    required this.todos,
  });

  @override
  Widget build(BuildContext context) {
    if (todos.isEmpty) {
      return const Center(child: Text('No todos found'));
    }
    
    // Group todos by completion status
    final completedTodos = todos.where((todo) => todo.completed).toList();
    final pendingTodos = todos.where((todo) => !todo.completed).toList();
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pendingTodos.isNotEmpty) ...[
          const Text(
            'Pending',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...pendingTodos.map((todo) => _buildTodoItem(context, todo)),
          const SizedBox(height: 16),
        ],
        if (completedTodos.isNotEmpty) ...[
          const Text(
            'Completed',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...completedTodos.map((todo) => _buildTodoItem(context, todo)),
        ],
      ],
    );
  }

  Widget _buildTodoItem(BuildContext context, Todo todo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          todo.completed ? Icons.check_circle : Icons.circle_outlined,
          color: todo.completed ? Colors.green : Colors.grey,
        ),
        title: Text(
          todo.todo,
          style: TextStyle(
            decoration: todo.completed ? TextDecoration.lineThrough : null,
            color: todo.completed ? Colors.grey : null,
          ),
        ),
      ),
    );
  }
}
