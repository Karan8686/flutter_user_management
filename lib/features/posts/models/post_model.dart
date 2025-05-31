class Post {
  final int id;
  final String title;
  final String body;
  final int userId;
  final List<String> tags;
  final int reactions;
  final bool isLocal;

  Post({
    required this.id,
    required this.title,
    required this.body,
    required this.userId,
    this.tags = const [],
    this.reactions = 0,
    this.isLocal = false,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      userId: json['userId'] is int ? json['userId'] : int.tryParse(json['userId'].toString()) ?? 0,
      tags: json['tags'] != null 
          ? List<String>.from(json['tags']) 
          : [],
      reactions: json['reactions'] is int ? json['reactions'] : int.tryParse(json['reactions'].toString()) ?? 0,
    );
  }

  factory Post.local({
    required int id,
    required String title,
    required String body,
    required int userId,
  }) {
    return Post(
      id: id,
      title: title,
      body: body,
      userId: userId,
      isLocal: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'userId': userId,
      'tags': tags,
      'reactions': reactions,
      'isLocal': isLocal,
    };
  }
}
