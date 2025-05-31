import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_user_management/core/api/api_client.dart';
import 'package:flutter_user_management/features/posts/bloc/post_bloc.dart';
import 'package:flutter_user_management/features/posts/repositories/post_repository.dart';
import 'package:flutter_user_management/features/todos/bloc/todo_bloc.dart';
import 'package:flutter_user_management/features/todos/repositories/todo_repository.dart';
import 'package:flutter_user_management/features/users/bloc/user_bloc.dart';
import 'package:flutter_user_management/features/users/repositories/user_repository.dart';
import 'package:flutter_user_management/app.dart';

void main() {
  final apiClient = ApiClient();
  final userRepository = UserRepository(apiClient: apiClient);
  final postRepository = PostRepository(apiClient: apiClient);
  final todoRepository = TodoRepository(apiClient: apiClient);

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<UserBloc>(
          create: (context) => UserBloc(userRepository: userRepository)
            ..add(const UserFetchEvent(limit: 10, skip: 0)),
        ),
        BlocProvider<PostBloc>(
          create: (context) => PostBloc(postRepository: postRepository),
        ),
        BlocProvider<TodoBloc>(
          create: (context) => TodoBloc(todoRepository: todoRepository),
        ),
      ],
      child: const App(),
    ),
  );
}
