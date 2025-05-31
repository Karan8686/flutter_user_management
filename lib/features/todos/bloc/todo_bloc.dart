import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_user_management/features/todos/models/todo_model.dart';
import 'package:flutter_user_management/features/todos/repositories/todo_repository.dart';

// Events
abstract class TodoEvent extends Equatable {
  const TodoEvent();

  @override
  List<Object?> get props => [];
}

class TodoFetchEvent extends TodoEvent {
  final int userId;

  const TodoFetchEvent({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// States
abstract class TodoState extends Equatable {
  const TodoState();

  @override
  List<Object?> get props => [];
}

class TodoInitialState extends TodoState {}

class TodoLoadingState extends TodoState {}

class TodoLoadedState extends TodoState {
  final List<Todo> todos;
  final int userId;

  const TodoLoadedState({
    required this.todos,
    required this.userId,
  });

  @override
  List<Object?> get props => [todos, userId];
}

class TodoErrorState extends TodoState {
  final String message;

  const TodoErrorState({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC
class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final TodoRepository todoRepository;

  TodoBloc({required this.todoRepository}) : super(TodoInitialState()) {
    on<TodoFetchEvent>(_onTodoFetch);
  }

  Future<void> _onTodoFetch(TodoFetchEvent event, Emitter<TodoState> emit) async {
    try {
      emit(TodoLoadingState());
      
      final todos = await todoRepository.getUserTodos(event.userId);
      
      emit(TodoLoadedState(
        todos: todos,
        userId: event.userId,
      ));
    } catch (e) {
      emit(TodoErrorState(message: e.toString()));
    }
  }
}
