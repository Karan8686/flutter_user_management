import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_user_management/features/posts/models/post_model.dart';
import 'package:flutter_user_management/features/posts/repositories/post_repository.dart';

// Post events that can be triggered in the app
abstract class PostEvent extends Equatable {
  const PostEvent();

  @override
  List<Object?> get props => [];
}

// Event to initialize the post repository
class PostInitializeEvent extends PostEvent {
  const PostInitializeEvent();
}

// Event to fetch posts for a specific user
class PostFetchEvent extends PostEvent {
  final int userId;

  const PostFetchEvent({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// Event to create a new post
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

// Event to fetch all locally saved posts
class PostFetchAllLocalEvent extends PostEvent {
  const PostFetchAllLocalEvent();
}

// Base state for post-related operations
abstract class PostState extends Equatable {
  const PostState();

  @override
  List<Object?> get props => [];
}

// Initial state when the app starts
class PostInitialState extends PostState {}

// State when posts are being loaded
class PostLoadingState extends PostState {}

// State when posts have been successfully loaded
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

// State when locally saved posts have been loaded
class PostLocalLoadedState extends PostState {
  final List<Post> posts;

  const PostLocalLoadedState({
    required this.posts,
  });

  @override
  List<Object?> get props => [posts];
}

// State when an error occurs during post operations
class PostErrorState extends PostState {
  final String message;

  const PostErrorState({required this.message});

  @override
  List<Object?> get props => [message];
}

// State when a new post has been created
class PostCreatedState extends PostState {
  final Post post;

  const PostCreatedState({required this.post});

  @override
  List<Object?> get props => [post];
}

// Main BLoC class that handles post-related operations
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

  // Converts technical error messages into user-friendly ones
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
    } else if (errorMessage.contains('Unable to find posts for this user')) {
      return 'This user\'s posts are not available at the moment.';
    } else if (errorMessage.contains('Unable to load your saved posts')) {
      return 'There was a problem loading your saved posts. Please try restarting the app.';
    } else if (errorMessage.contains('Unable to save your post')) {
      return 'There was a problem saving your post. Please try again.';
    } else if (errorMessage
        .contains('The post you\'re trying to update no longer exists')) {
      return 'This post has been deleted or is no longer available.';
    } else {
      return 'Something went wrong. Please try again.';
    }
  }

  // Handles initializing the post repository
  Future<void> _onInitialize(
      PostInitializeEvent event, Emitter<PostState> emit) async {
    try {
      emit(PostLoadingState());

      // Wait for repository to be ready
      await postRepository.ready;

      // Load saved posts after initialization
      final posts = await postRepository.getAllLocalPosts();
      _cachedPosts = List.from(posts);
      emit(PostLocalLoadedState(posts: posts));
    } catch (e) {
      // Show cached posts if available, even if there's an error
      if (_cachedPosts.isNotEmpty) {
        emit(PostLocalLoadedState(posts: _cachedPosts));
        // Show error as a snackbar instead of blocking the UI
        emit(PostErrorState(message: _getUserFriendlyErrorMessage(e)));
      } else {
        emit(PostErrorState(message: _getUserFriendlyErrorMessage(e)));
      }
    }
  }

  // Handles fetching posts for a specific user
  Future<void> _onPostFetch(
      PostFetchEvent event, Emitter<PostState> emit) async {
    try {
      emit(PostLoadingState());

      // Ensure repository is ready
      await postRepository.ready;

      final posts = await postRepository.getUserPosts(event.userId);
      _cachedPosts = List.from(posts);

      emit(PostLoadedState(
        posts: posts,
        userId: event.userId,
      ));
    } catch (e) {
      // Show cached posts if available, even if there's an error
      if (_cachedPosts.isNotEmpty) {
        emit(PostLoadedState(
          posts: _cachedPosts,
          userId: event.userId,
        ));
        // Show error as a snackbar instead of blocking the UI
        emit(PostErrorState(message: _getUserFriendlyErrorMessage(e)));
      } else {
        // If no cached posts, show error state
        emit(PostErrorState(message: _getUserFriendlyErrorMessage(e)));
      }
    }
  }

  // Handles creating a new post
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

  // Handles fetching all locally saved posts
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
      // Show cached posts if available, even if there's an error
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
