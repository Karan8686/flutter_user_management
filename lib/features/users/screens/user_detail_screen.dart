import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_user_management/features/posts/bloc/post_bloc.dart';
import 'package:flutter_user_management/features/posts/widgets/post_list.dart';
import 'package:flutter_user_management/features/todos/bloc/todo_bloc.dart';
import 'package:flutter_user_management/features/todos/widgets/todo_list.dart';
import 'package:flutter_user_management/features/users/models/user_model.dart';

class UserDetailScreen extends StatefulWidget {
  final User user;

  const UserDetailScreen({
    super.key,
    required this.user,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Fetch posts and todos for this user
    context.read<PostBloc>().add(PostFetchEvent(userId: widget.user.id));
    context.read<TodoBloc>().add(TodoFetchEvent(userId: widget.user.id));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user.fullName),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Posts'),
            Tab(text: 'Todos'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildUserInfo(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPostsTab(),
                _buildTodosTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: NetworkImage(widget.user.image),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.fullName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(widget.user.email),
                if (widget.user.phone != null) ...[
                  const SizedBox(height: 4),
                  Text(widget.user.phone!),
                ],
                if (widget.user.address != null) ...[
                  const SizedBox(height: 4),
                  Text(widget.user.address!),
                ],
                if (widget.user.company != null) ...[
                  const SizedBox(height: 4),
                  Text('Works at ${widget.user.company!}'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    return BlocBuilder<PostBloc, PostState>(
      builder: (context, state) {
        if (state is PostLoadingState) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is PostLoadedState && state.userId == widget.user.id) {
          return PostList(posts: state.posts);
        } else if (state is PostErrorState) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(state.message),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<PostBloc>().add(
                          PostFetchEvent(userId: widget.user.id),
                        );
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return const Center(child: Text('No posts found'));
      },
    );
  }

  Widget _buildTodosTab() {
    return BlocBuilder<TodoBloc, TodoState>(
      builder: (context, state) {
        if (state is TodoLoadingState) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is TodoLoadedState && state.userId == widget.user.id) {
          return TodoList(todos: state.todos);
        } else if (state is TodoErrorState) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(state.message),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<TodoBloc>().add(
                          TodoFetchEvent(userId: widget.user.id),
                        );
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return const Center(child: Text('No todos found'));
      },
    );
  }
}
