import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_user_management/core/api/api_client.dart';
import 'package:flutter_user_management/features/posts/models/post_model.dart';
import 'dart:async';

class PostRepository {
  final ApiClient apiClient;
  static const String _localPostsKey = 'local_posts';
  static const String _nextLocalIdKey = 'next_local_id';
  late SharedPreferences _prefs;
  List<Post> _localPosts = [];
  int _nextLocalId = -1;
  bool _isInitialized = false;
  Completer<void>? _initCompleter;

  PostRepository({required this.apiClient}) {
    _initPrefs();
  }

  // Ensures the repository is fully initialized before use
  Future<void> get ready async {
    if (_isInitialized) return;
    if (_initCompleter != null) return _initCompleter!.future;

    _initCompleter = Completer<void>();
    try {
      await _initPrefs();
      _isInitialized = true;
      _initCompleter!.complete();
    } catch (e) {
      _initCompleter!.completeError(e);
      rethrow;
    }
    return _initCompleter!.future;
  }

  // Initializes local storage and loads saved posts
  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _loadLocalPosts();
    _loadNextLocalId();
  }

  // Loads saved posts from local storage
  void _loadLocalPosts() {
    final postsJson = _prefs.getStringList(_localPostsKey) ?? [];
    _localPosts =
        postsJson.map((json) => Post.fromJson(jsonDecode(json))).toList();
  }

  // Loads the next available local post ID
  void _loadNextLocalId() {
    _nextLocalId = _prefs.getInt(_nextLocalIdKey) ?? -1;
  }

  // Saves posts to local storage
  Future<void> _saveLocalPosts() async {
    final postsJson =
        _localPosts.map((post) => jsonEncode(post.toJson())).toList();
    await _prefs.setStringList(_localPostsKey, postsJson);
  }

  // Saves the next available local post ID
  Future<void> _saveNextLocalId() async {
    await _prefs.setInt(_nextLocalIdKey, _nextLocalId);
  }

  // Fetches posts for a specific user from the API
  Future<List<Post>> getUserPosts(int userId) async {
    try {
      // Verify internet connectivity
      try {
        final result = await InternetAddress.lookup('google.com');
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          throw Exception('No internet connection available');
        }
      } on SocketException catch (_) {
        throw Exception('No internet connection available');
      }

      final response = await apiClient.get('/posts/user/$userId');
      final postsData = response['posts'] as List<dynamic>;

      // Convert API response to Post objects
      final List<Post> posts = postsData
          .map((postData) => Post.fromJson(postData as Map<String, dynamic>))
          .toList();

      return posts;
    } catch (e) {
      if (e is SocketException || e.toString().contains('SocketException')) {
        throw Exception(
            'No internet connection available. Please check your connection and try again.');
      } else if (e.toString().contains('Failed to load data: 404')) {
        throw Exception(
            'Unable to find posts for this user. The user may not exist or have been removed.');
      } else if (e.toString().contains('No internet connection available')) {
        throw Exception(
            'No internet connection available. Please check your connection and try again.');
      } else if (e.toString().contains('Connection refused') ||
          e.toString().contains('Connection reset') ||
          e.toString().contains('Network is unreachable')) {
        throw Exception(
            'Unable to connect to the server. Please check your internet connection and try again.');
      } else {
        throw Exception('Unable to load posts. Please try again later.');
      }
    }
  }

  // Retrieves all locally saved posts
  Future<List<Post>> getAllLocalPosts() async {
    try {
      return List.from(_localPosts);
    } catch (e) {
      throw Exception(
          'Unable to load your saved posts. Please try restarting the app.');
    }
  }

  // Creates a new post and saves it locally
  Future<Post> createPost({
    required String title,
    required String body,
    required int userId,
  }) async {
    try {
      // Create a new local post with a negative ID to distinguish it from API posts
      final newPost = Post.local(
        id: _nextLocalId--,
        title: title,
        body: body,
        userId: userId,
      );

      _localPosts.insert(0, newPost); // Add to beginning of list
      await _saveLocalPosts();
      await _saveNextLocalId();

      return newPost;
    } catch (e) {
      throw Exception('Unable to save your post. Please try again.');
    }
  }

  // Returns the count of locally saved posts
  int getLocalPostsCount() {
    return _localPosts.length;
  }

  // Removes a post from local storage
  Future<void> deleteLocalPost(int postId) async {
    try {
      _localPosts.removeWhere((post) => post.id == postId);
      await _saveLocalPosts();
    } catch (e) {
      throw Exception('Unable to delete the post. Please try again.');
    }
  }

  // Updates an existing local post
  Future<void> updateLocalPost(Post updatedPost) async {
    try {
      final index = _localPosts.indexWhere((post) => post.id == updatedPost.id);
      if (index != -1) {
        _localPosts[index] = updatedPost;
        await _saveLocalPosts();
      } else {
        throw Exception('Post not found');
      }
    } catch (e) {
      if (e.toString().contains('Post not found')) {
        throw Exception('The post you\'re trying to update no longer exists.');
      } else {
        throw Exception('Unable to update the post. Please try again.');
      }
    }
  }
}
