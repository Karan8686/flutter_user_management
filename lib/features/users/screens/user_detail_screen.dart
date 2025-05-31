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
    _tabController = TabController(length: 3, vsync: this);

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
            Tab(text: 'Profile'),
            Tab(text: 'Posts'),
            Tab(text: 'Todos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileTab(),
          _buildPostsTab(),
          _buildTodosTab(),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Image
          Center(
            child: CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(widget.user.image),
            ),
          ),
          const SizedBox(height: 24),

          // Personal Information
          _buildSection(
            title: 'Personal Information',
            icon: Icons.person_outline,
            children: [
              if (widget.user.birthDate != null)
                _buildInfoRow('Birth Date', widget.user.formattedBirthDate),
              if (widget.user.age != null)
                _buildInfoRow('Age', '${widget.user.age} years'),
              if (widget.user.gender != null)
                _buildInfoRow('Gender', widget.user.gender!),
              if (widget.user.bloodGroup != null)
                _buildInfoRow('Blood Group', widget.user.bloodGroup!),
              if (widget.user.eyeColor != null)
                _buildInfoRow('Eye Color', widget.user.eyeColor!),
              if (widget.user.hair != null)
                _buildInfoRow('Hair',
                    '${widget.user.hair!['color']} ${widget.user.hair!['type']}'),
            ],
          ),
          const SizedBox(height: 16),

          // Contact Information
          _buildSection(
            title: 'Contact Information',
            icon: Icons.contact_mail_outlined,
            children: [
              _buildInfoRow('Email', widget.user.email),
              if (widget.user.phone != null)
                _buildInfoRow('Phone', widget.user.phone!),
              _buildInfoRow('Address', widget.user.formattedAddress),
            ],
          ),
          const SizedBox(height: 16),

          // Professional Information
          _buildSection(
            title: 'Professional Information',
            icon: Icons.business_outlined,
            children: [
              if (widget.user.companyDetails != null) ...[
                _buildInfoRow(
                    'Company', widget.user.companyDetails!['name'] ?? 'N/A'),
                _buildInfoRow('Department',
                    widget.user.companyDetails!['department'] ?? 'N/A'),
                _buildInfoRow(
                    'Position', widget.user.companyDetails!['title'] ?? 'N/A'),
              ],
              if (widget.user.university != null)
                _buildInfoRow('University', widget.user.university!),
              if (widget.user.domain != null)
                _buildInfoRow('Website', widget.user.domain!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
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
