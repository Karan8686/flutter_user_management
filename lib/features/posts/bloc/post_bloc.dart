import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_user_management/features/posts/models/post_model.dart';
import 'package:flutter_user_management/features/posts/repositories/post_repository.dart';

// Events
abstract class PostEvent extends Equatable {
  const PostEvent();

  @override
  List<Object?> get props => [];
}

class PostInitializeEvent extends PostEvent {
  const PostInitializeEvent();
}

class PostFetchEvent extends PostEvent {
  final int userId;

  const PostFetchEvent({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class PostCreateEvent extends PostEvent {
  final String title;
  final String body;
  final int userId;

  const PostCreateEvent({
    required this.title,
    required this.body,
    required this.userId,
  });

  @override
  List<Object?> get props => [title, body, userId];
}

class PostFetchAllLocalEvent extends PostEvent {
  const PostFetchAllLocalEvent();
}

// States
abstract class PostState extends Equatable {
  const PostState();

  @override
  List<Object?> get props => [];
}

class PostInitialState extends PostState {}

class PostLoadingState extends PostState {}

class PostLoadedState extends PostState {
  final List<Post> posts;
  final int userId;

  const PostLoadedState({
    required this.posts,
    required this.userId,
  });

  @override
  List<Object?> get props => [posts, userId];
}

class PostLocalLoadedState extends PostState {
  final List<Post> posts;

  const PostLocalLoadedState({
    required this.posts,
  });

  @override
  List<Object?> get props => [posts];
}

class PostErrorState extends PostState {
  final String message;

  const PostErrorState({required this.message});

  @override
  List<Object?> get props => [message];
}

class PostCreatedState extends PostState {
  final Post post;

  const PostCreatedState({required this.post});

  @override
  List<Object?> get props => [post];
}

// BLoC
class PostBloc extends Bloc<PostEvent, PostState> {
  final PostRepository postRepository;
  List<Post> _cachedPosts = [];

  PostBloc({required this.postRepository}) : super(PostInitialState()) {
    on<PostInitializeEvent>(_onInitialize);
    on<PostFetchEvent>(_onPostFetch);
    on<PostCreateEvent>(_onPostCreate);
    on<PostFetchAllLocalEvent>(_onPostFetchAllLocal);

    // Initialize immediately when bloc is created
    add(const PostInitializeEvent());
  }

  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorMessage = error.toString();
    if (errorMessage.contains('No internet connection')) {
      return 'No internet connection';
    } else if (errorMessage.contains('User not found')) {
      return 'User not found';
    } else if (errorMessage.contains('Post not found')) {
      return 'Post not found';
    } else {
      return 'Something went wrong';
    }
  }

  Future<void> _onInitialize(
      PostInitializeEvent event, Emitter<PostState> emit) async {
    try {
      emit(PostLoadingState());

      // Wait for repository to be ready
      await postRepository.ready;

      // Fetch local posts after initialization
      final posts = await postRepository.getAllLocalPosts();
      _cachedPosts = List.from(posts);
      emit(PostLocalLoadedState(posts: posts));
    } catch (e) {
      // If we have cached posts, show them even if there's an error
      if (_cachedPosts.isNotEmpty) {
        emit(PostLocalLoadedState(posts: _cachedPosts));
        // Show error as a snackbar instead of blocking the UI
        emit(PostErrorState(message: _getUserFriendlyErrorMessage(e)));
      } else {
        emit(PostErrorState(message: _getUserFriendlyErrorMessage(e)));
      }
    }
  }

  Future<void> _onPostFetch(
      PostFetchEvent event, Emitter<PostState> emit) async {
    try {
      emit(PostLoadingState());

      final posts = await postRepository.getUserPosts(event.userId);
      _cachedPosts = List.from(posts);

      emit(PostLoadedState(
        posts: posts,
        userId: event.userId,
      ));
    } catch (e) {
      // If we have cached posts, show them even if there's an error
      if (_cachedPosts.isNotEmpty) {
        emit(PostLoadedState(
          posts: _cachedPosts,
          userId: event.userId,
        ));
        // Show error as a snackbar instead of blocking the UI
        emit(PostErrorState(message: _getUserFriendlyErrorMessage(e)));
      } else {
        emit(PostErrorState(message: _getUserFriendlyErrorMessage(e)));
      }
    }
  }

  Future<void> _onPostCreate(
      PostCreateEvent event, Emitter<PostState> emit) async {
    try {
      emit(PostLoadingState());

      // Ensure repository is ready
      await postRepository.ready;

      final post = await postRepository.createPost(
        title: event.title,
        body: event.body,
        userId: event.userId,
      );

      // Get all local posts to show updated list
      final allLocalPosts = await postRepository.getAllLocalPosts();
      _cachedPosts = List.from(allLocalPosts);

      emit(PostLocalLoadedState(posts: allLocalPosts));
    } catch (e) {
      emit(PostErrorState(message: _getUserFriendlyErrorMessage(e)));
    }
  }

  Future<void> _onPostFetchAllLocal(
      PostFetchAllLocalEvent event, Emitter<PostState> emit) async {
    try {
      emit(PostLoadingState());

      // Ensure repository is ready
      await postRepository.ready;

      final posts = await postRepository.getAllLocalPosts();
      _cachedPosts = List.from(posts);

      emit(PostLocalLoadedState(posts: posts));
    } catch (e) {
      // If we have cached posts, show them even if there's an error
      if (_cachedPosts.isNotEmpty) {
        emit(PostLocalLoadedState(posts: _cachedPosts));
        // Show error as a snackbar instead of blocking the UI
        emit(PostErrorState(message: _getUserFriendlyErrorMessage(e)));
      } else {
        emit(PostErrorState(message: _getUserFriendlyErrorMessage(e)));
      }
    }
  }
}
