import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_user_management/features/users/models/user_model.dart';
import 'package:flutter_user_management/features/users/repositories/user_repository.dart';

// Events
abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class UserFetchEvent extends UserEvent {
  final int limit;
  final int skip;

  const UserFetchEvent({
    required this.limit,
    required this.skip,
  });

  @override
  List<Object?> get props => [limit, skip];
}

class UserSearchEvent extends UserEvent {
  final String query;

  const UserSearchEvent({required this.query});

  @override
  List<Object?> get props => [query];
}

class UserLoadMoreEvent extends UserEvent {
  const UserLoadMoreEvent();
}

class UserRefreshEvent extends UserEvent {
  const UserRefreshEvent();
}

class UserSelectEvent extends UserEvent {
  final int userId;

  const UserSelectEvent({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class UserClearSearchEvent extends UserEvent {
  const UserClearSearchEvent();
}

// States
abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object?> get props => [];
}

class UserInitialState extends UserState {}

class UserLoadingState extends UserState {}

class UserLoadingMoreState extends UserState {
  final List<User> currentUsers;
  final int total;

  const UserLoadingMoreState({
    required this.currentUsers,
    required this.total,
  });

  @override
  List<Object?> get props => [currentUsers, total];
}

class UserLoadedState extends UserState {
  final List<User> users;
  final int total;
  final int limit;
  final int skip;
  final bool hasReachedMax;
  final String? searchQuery;

  const UserLoadedState({
    required this.users,
    required this.total,
    required this.limit,
    required this.skip,
    required this.hasReachedMax,
    this.searchQuery,
  });

  @override
  List<Object?> get props =>
      [users, total, limit, skip, hasReachedMax, searchQuery];

  UserLoadedState copyWith({
    List<User>? users,
    int? total,
    int? limit,
    int? skip,
    bool? hasReachedMax,
    String? searchQuery,
  }) {
    return UserLoadedState(
      users: users ?? this.users,
      total: total ?? this.total,
      limit: limit ?? this.limit,
      skip: skip ?? this.skip,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class UserErrorState extends UserState {
  final String message;

  const UserErrorState({required this.message});

  @override
  List<Object?> get props => [message];
}

class UserSelectedState extends UserState {
  final User user;

  const UserSelectedState({required this.user});

  @override
  List<Object?> get props => [user];
}

// BLoC
class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository userRepository;
  List<User> _cachedUsers = [];

  UserBloc({required this.userRepository}) : super(UserInitialState()) {
    on<UserFetchEvent>(_onUserFetch);
    on<UserSearchEvent>(_onUserSearch);
    on<UserLoadMoreEvent>(_onUserLoadMore);
    on<UserRefreshEvent>(_onUserRefresh);
    on<UserSelectEvent>(_onUserSelect);
    on<UserClearSearchEvent>(_onUserClearSearch);
  }

  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorMessage = error.toString();
    if (errorMessage.contains('No internet connection available')) {
      return 'Please check your internet connection and try again.';
    } else if (errorMessage.contains('Unable to connect to the server')) {
      return 'Unable to reach the server. Please check your internet connection.';
    } else if (errorMessage.contains('Connection refused') ||
        errorMessage.contains('Connection reset') ||
        errorMessage.contains('Network is unreachable')) {
      return 'Network connection is unstable. Please check your internet connection.';
    } else if (errorMessage.contains('Unable to find users')) {
      return 'Unable to load users at this time. Please try again later.';
    } else if (errorMessage.contains('User not found')) {
      return 'This user is no longer available.';
    } else {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<void> _onUserFetch(
      UserFetchEvent event, Emitter<UserState> emit) async {
    try {
      emit(UserLoadingState());

      final result = await userRepository.getUsers(
        limit: event.limit,
        skip: event.skip,
      );

      final users = result['users'] as List<User>;
      final total = result['total'] as int;
      final limit = result['limit'] as int;
      final skip = result['skip'] as int;

      _cachedUsers = List.from(users);

      final hasReachedMax =
          users.length < limit || skip + users.length >= total;

      emit(UserLoadedState(
        users: users,
        total: total,
        limit: limit,
        skip: skip,
        hasReachedMax: hasReachedMax,
      ));
    } catch (e) {
      // If we have cached users, show them even if there's an error
      if (_cachedUsers.isNotEmpty) {
        final currentState = state;
        if (currentState is UserLoadedState) {
          emit(UserLoadedState(
            users: _cachedUsers,
            total: currentState.total,
            limit: currentState.limit,
            skip: currentState.skip,
            hasReachedMax: currentState.hasReachedMax,
            searchQuery: currentState.searchQuery,
          ));
        } else {
          emit(UserLoadedState(
            users: _cachedUsers,
            total: _cachedUsers.length,
            limit: event.limit,
            skip: event.skip,
            hasReachedMax: true,
          ));
        }
        // Show error as a snackbar instead of blocking the UI
        emit(UserErrorState(message: _getUserFriendlyErrorMessage(e)));
      } else {
        emit(UserErrorState(message: _getUserFriendlyErrorMessage(e)));
      }
    }
  }

  Future<void> _onUserSearch(
      UserSearchEvent event, Emitter<UserState> emit) async {
    try {
      emit(UserLoadingState());

      final result = await userRepository.getUsers(
        limit: 10,
        skip: 0,
        searchQuery: event.query,
      );

      final users = result['users'] as List<User>;
      final total = result['total'] as int;

      _cachedUsers = List.from(users);

      emit(UserLoadedState(
        users: users,
        total: total,
        limit: 10,
        skip: 0,
        hasReachedMax: true,
        searchQuery: event.query,
      ));
    } catch (e) {
      // If we have cached users, show them even if there's an error
      if (_cachedUsers.isNotEmpty) {
        emit(UserLoadedState(
          users: _cachedUsers,
          total: _cachedUsers.length,
          limit: 10,
          skip: 0,
          hasReachedMax: true,
          searchQuery: event.query,
        ));
        // Show error as a snackbar instead of blocking the UI
        emit(UserErrorState(message: _getUserFriendlyErrorMessage(e)));
      } else {
        emit(UserErrorState(message: _getUserFriendlyErrorMessage(e)));
      }
    }
  }

  Future<void> _onUserLoadMore(
      UserLoadMoreEvent event, Emitter<UserState> emit) async {
    final currentState = state;
    if (currentState is UserLoadedState && !currentState.hasReachedMax) {
      try {
        emit(UserLoadingMoreState(
          currentUsers: currentState.users,
          total: currentState.total,
        ));

        final result = await userRepository.getUsers(
          limit: currentState.limit,
          skip: currentState.skip + currentState.limit,
          searchQuery: currentState.searchQuery,
        );

        final newUsers = result['users'] as List<User>;
        final total = result['total'] as int;
        final limit = result['limit'] as int;
        final skip = result['skip'] as int;

        final allUsers = [...currentState.users, ...newUsers];
        _cachedUsers = List.from(allUsers);

        final hasReachedMax =
            newUsers.length < limit || skip + newUsers.length >= total;

        emit(UserLoadedState(
          users: allUsers,
          total: total,
          limit: limit,
          skip: skip,
          hasReachedMax: hasReachedMax,
          searchQuery: currentState.searchQuery,
        ));
      } catch (e) {
        // If we have cached users, show them even if there's an error
        if (_cachedUsers.isNotEmpty) {
          emit(UserLoadedState(
            users: _cachedUsers,
            total: currentState.total,
            limit: currentState.limit,
            skip: currentState.skip,
            hasReachedMax: currentState.hasReachedMax,
            searchQuery: currentState.searchQuery,
          ));
          // Show error as a snackbar instead of blocking the UI
          emit(UserErrorState(message: _getUserFriendlyErrorMessage(e)));
        } else {
          emit(UserErrorState(message: _getUserFriendlyErrorMessage(e)));
        }
      }
    }
  }

  Future<void> _onUserRefresh(
      UserRefreshEvent event, Emitter<UserState> emit) async {
    try {
      final currentState = state;
      String? searchQuery;

      if (currentState is UserLoadedState) {
        searchQuery = currentState.searchQuery;
      }

      final result = await userRepository.getUsers(
        limit: 10,
        skip: 0,
        searchQuery: searchQuery,
      );

      final users = result['users'] as List<User>;
      final total = result['total'] as int;
      final limit = result['limit'] as int;
      final skip = result['skip'] as int;

      _cachedUsers = List.from(users);

      final hasReachedMax =
          users.length < limit || skip + users.length >= total;

      emit(UserLoadedState(
        users: users,
        total: total,
        limit: limit,
        skip: skip,
        hasReachedMax: hasReachedMax,
        searchQuery: searchQuery,
      ));
    } catch (e) {
      // If we have cached users, show them even if there's an error
      if (_cachedUsers.isNotEmpty) {
        final currentState = state;
        if (currentState is UserLoadedState) {
          emit(UserLoadedState(
            users: _cachedUsers,
            total: currentState.total,
            limit: currentState.limit,
            skip: currentState.skip,
            hasReachedMax: currentState.hasReachedMax,
            searchQuery: currentState.searchQuery,
          ));
        } else {
          emit(UserLoadedState(
            users: _cachedUsers,
            total: _cachedUsers.length,
            limit: 10,
            skip: 0,
            hasReachedMax: true,
          ));
        }
        // Show error as a snackbar instead of blocking the UI
        emit(UserErrorState(message: _getUserFriendlyErrorMessage(e)));
      } else {
        emit(UserErrorState(message: _getUserFriendlyErrorMessage(e)));
      }
    }
  }

  Future<void> _onUserSelect(
      UserSelectEvent event, Emitter<UserState> emit) async {
    try {
      final user = await userRepository.getUserById(event.userId);
      emit(UserSelectedState(user: user));
    } catch (e) {
      emit(UserErrorState(message: _getUserFriendlyErrorMessage(e)));
    }
  }

  Future<void> _onUserClearSearch(
      UserClearSearchEvent event, Emitter<UserState> emit) async {
    try {
      emit(UserLoadingState());

      final result = await userRepository.getUsers(
        limit: 10,
        skip: 0,
      );

      final users = result['users'] as List<User>;
      final total = result['total'] as int;
      final limit = result['limit'] as int;
      final skip = result['skip'] as int;

      _cachedUsers = List.from(users);

      final hasReachedMax =
          users.length < limit || skip + users.length >= total;

      emit(UserLoadedState(
        users: users,
        total: total,
        limit: limit,
        skip: skip,
        hasReachedMax: hasReachedMax,
      ));
    } catch (e) {
      // If we have cached users, show them even if there's an error
      if (_cachedUsers.isNotEmpty) {
        emit(UserLoadedState(
          users: _cachedUsers,
          total: _cachedUsers.length,
          limit: 10,
          skip: 0,
          hasReachedMax: true,
        ));
        // Show error as a snackbar instead of blocking the UI
        emit(UserErrorState(message: _getUserFriendlyErrorMessage(e)));
      } else {
        emit(UserErrorState(message: _getUserFriendlyErrorMessage(e)));
      }
    }
  }
}
