import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_user_management/core/utils/debouncer.dart';
import 'package:flutter_user_management/features/posts/screens/create_post_screen.dart';
import 'package:flutter_user_management/features/users/bloc/user_bloc.dart';
import 'package:flutter_user_management/features/users/screens/user_detail_screen.dart';
import 'package:flutter_user_management/features/users/widgets/user_list_item.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _debouncer = Debouncer();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  // Load more users when reaching the bottom of the list
  void _onScroll() {
    if (_isBottom && !_isSearching) {
      context.read<UserBloc>().add(const UserLoadMoreEvent());
    }
  }

  // Check if we've scrolled to the bottom of the list
  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  // Clear search and reset the list
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
    });
    context.read<UserBloc>().add(const UserClearSearchEvent());
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (query) {
                setState(() {
                  _isSearching = query.isNotEmpty;
                });

                // Debounce search to avoid too many API calls
                _debouncer.run(() {
                  if (query.isEmpty) {
                    context.read<UserBloc>().add(const UserClearSearchEvent());
                  } else {
                    context.read<UserBloc>().add(UserSearchEvent(query: query));
                  }
                });
              },
            ),
          ),
          // User list with pull-to-refresh
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _clearSearch();
                context.read<UserBloc>().add(const UserRefreshEvent());
              },
              child: BlocConsumer<UserBloc, UserState>(
                listener: (context, state) {
                  // Navigate to user details when a user is selected
                  if (state is UserSelectedState) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserDetailScreen(user: state.user),
                      ),
                    ).then((_) {
                      // Refresh the list when returning from details
                      if (_searchController.text.isEmpty && !_isSearching) {
                        context.read<UserBloc>().add(const UserRefreshEvent());
                      }
                    });
                  }
                },
                builder: (context, state) {
                  // Show loading indicator
                  if (state is UserInitialState || state is UserLoadingState) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  // Show user list or empty state
                  else if (state is UserLoadedState) {
                    return state.users.isEmpty
                        ? Center(
                            child: Text(_isSearching
                                ? 'No users found for your search'
                                : 'No users found'),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: (state.hasReachedMax || _isSearching)
                                ? state.users.length
                                : state.users.length + 1,
                            itemBuilder: (context, index) {
                              // Show loading indicator at the bottom while loading more
                              if (index >= state.users.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              final user = state.users[index];
                              return UserListItem(
                                user: user,
                                onTap: () {
                                  context.read<UserBloc>().add(
                                        UserSelectEvent(userId: user.id),
                                      );
                                },
                              );
                            },
                          );
                  }
                  // Show loading more state
                  else if (state is UserLoadingMoreState) {
                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: state.currentUsers.length + 1,
                      itemBuilder: (context, index) {
                        if (index >= state.currentUsers.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final user = state.currentUsers[index];
                        return UserListItem(
                          user: user,
                          onTap: () {
                            context.read<UserBloc>().add(
                                  UserSelectEvent(userId: user.id),
                                );
                          },
                        );
                      },
                    );
                  }
                  // Show error state
                  else if (state is UserErrorState) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            state.message == 'No internet connection'
                                ? Icons.wifi_off
                                : Icons.error_outline,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.message,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              _clearSearch();
                              context.read<UserBloc>().add(
                                    const UserFetchEvent(limit: 10, skip: 0),
                                  );
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              foregroundColor: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return const Center(child: Text('Something went wrong'));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
