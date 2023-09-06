class Post {
  final String userId;
  final String imageUrl;
  final String caption;
  final int likes;

  Post({
    required this.userId,
    required this.imageUrl,
    required this.caption,
    required this.likes,
  });
}

class Comment {
  final String userId;
  final String text;

  Comment({
    required this.userId,
    required this.text,
  });
}
