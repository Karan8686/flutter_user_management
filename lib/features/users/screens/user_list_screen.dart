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

  void _onScroll() {
    if (_isBottom && !_isSearching) {
      context.read<UserBloc>().add(const UserLoadMoreEvent());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
    });
    context.read<UserBloc>().add(const UserClearSearchEvent());
    // Remove focus from search field
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
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _clearSearch();
                context.read<UserBloc>().add(const UserRefreshEvent());
              },
              child: BlocConsumer<UserBloc, UserState>(
                listener: (context, state) {
                  if (state is UserErrorState) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message)),
                    );
                  } else if (state is UserSelectedState) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserDetailScreen(user: state.user),
                      ),
                    ).then((_) {
                      // When returning from detail screen, ensure we're in the right state
                      if (_searchController.text.isEmpty && !_isSearching) {
                        context.read<UserBloc>().add(const UserRefreshEvent());
                      }
                    });
                  }
                },
                builder: (context, state) {
                  if (state is UserInitialState || state is UserLoadingState) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is UserLoadedState) {
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
                  } else if (state is UserLoadingMoreState) {
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
                  } else if (state is UserErrorState) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(state.message),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              _clearSearch();
                              context.read<UserBloc>().add(
                                    const UserFetchEvent(limit: 10, skip: 0),
                                  );
                            },
                            child: const Text('Retry'),
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
