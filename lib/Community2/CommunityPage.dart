import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class CommunityPage extends StatefulWidget {
  const CommunityPage({Key? key}) : super(key: key);

  @override
  _CommunityPageState createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  late User? user; // Define the user property here

  void initState() {
    super.initState();
    user = _auth.currentUser; // Initialize the user property in initState
  }

  Future<String?> uploadImageToFirebaseStorage(String imagePath) async {
    try {
      final Reference storageReference = FirebaseStorage.instance.ref().child('images').child('image_filename.jpg');
      final UploadTask uploadTask = storageReference.putFile(File(imagePath));
      await uploadTask.whenComplete(() {});
      final String downloadURL = await storageReference.getDownloadURL();
      return downloadURL;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  void _toggleLike(Post post) {
    if (post.isLiked) {
      // User is unliking the post
      _unlikePost(post);
    } else {
      // User is liking the post
      _likePost(post);
    }
  }

  void _likePost(Post post) {
    try {
      // Update the likes count in Firebase Firestore here
      _firestore.collection('posts').doc(post.documentId).update({
        'likes': FieldValue.increment(1),
      });

      // Set isLiked to true
      setState(() {
        post.isLiked = true;
      });
    } catch (e) {
      print('Error liking post: $e');
    }
  }

  void _unlikePost(Post post) {
    try {
      // Update the likes count in Firebase Firestore here
      _firestore.collection('posts').doc(post.documentId).update({
        'likes': FieldValue.increment(-1),
      });

      // Set isLiked to false
      setState(() {
        post.isLiked = false;
      });
    } catch (e) {
      print('Error unliking post: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Community Page'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _firestore.collection('posts').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return Center(
                    child: Text('No posts available'),
                  );
                }
                final posts = (snapshot.data! as QuerySnapshot).docs;
                List<Widget> postWidgets = [];

                for (var post in posts) {
                  final postDocument = post.data() as Map<String, dynamic>;

                  final postModel = Post(
                    userId: user!.uid,
                    imageUrl: postDocument['imageUrl'] as String?, // Use null-aware operator
                    caption: _postController.text,
                    likes: 0,
                    comments: [], // Pass an empty list here
                  );

                  // Create a custom widget to display a post using the Post model.
                  final postWidget = _buildPostWidget(postModel);
                  postWidgets.add(postWidget);
                }

                return ListView(
                  children: postWidgets,
                );
              },
            ),
          ),
          _buildPostInput(),
        ],
      ),
    );
  }


  Widget _buildPostWidget(Post post) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(post.caption),
            subtitle: Text('Likes: ${post.likes}'),
            leading: post.imageUrl != null
                ? Image.network(post.imageUrl!)
                : SizedBox.shrink(),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  post.isLiked ? Icons.favorite : Icons.favorite_border,
                  color: post.isLiked ? Colors.red : null,
                ),
                onPressed: () {
                  // Implement like/unlike logic here
                  _toggleLike(post);
                },
              ),
              _buildComments(post.documentId),
            ],
          ),
          _buildCommentInput(post),
        ],
      ),
    );
  }



  Widget _buildComments(String? postId) {
    if (postId == null) {
      return SizedBox.shrink();
    }

    return StreamBuilder(
      stream: _firestore.collection('comments').where('postId', isEqualTo: postId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return SizedBox.shrink();
        }
        final comments = (snapshot.data! as QuerySnapshot).docs;
        List<Widget> commentWidgets = [];

        for (var comment in comments) {
          final commentDocument = comment.data() as Map<String, dynamic>;

          final commentModel = Comment(
            userId: commentDocument['userId'],
            text: commentDocument['text'],
          );

          // Create a custom widget to display a comment using the Comment model.
          final commentWidget = _buildCommentWidget(commentModel);
          commentWidgets.add(commentWidget);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: commentWidgets,
        );
      },
    );
  }


  Widget _buildCommentWidget(Comment comment) {
    return ListTile(
      title: Text(comment.text),
    );
  }

  Widget _buildCommentInput(Post post) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Add a comment',
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              _postComment(post);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPostInput() {
    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _postController,
              decoration: InputDecoration(
                hintText: 'Share your post...',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _uploadPost();
              },
              child: Text('Post'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadPost() async {
    final postText = _postController.text;

    if (user != null && postText.isNotEmpty) {
      final ImagePicker _picker = ImagePicker();
      final XFile? pickedImage = await _picker.pickImage(source: ImageSource.gallery);

      if (pickedImage != null) {
        final String? imageUrl = await uploadImageToFirebaseStorage(pickedImage.path);

        if (imageUrl != null) {
          final postModel = Post(
            userId: user!.uid,
            imageUrl: imageUrl, // Use the actual image URL
            caption: postText,
            likes: 0,
            comments: [],
          );

          // Store the post in Firestore, including the imageUrl
          final postReference = _firestore.collection('posts').doc();
          postModel.documentId = postReference.id;
          await postReference.set({
            'userId': postModel.userId,
            'imageUrl': postModel.imageUrl,
            'caption': postModel.caption,
            'likes': postModel.likes,
            'documentId': postModel.documentId,
          });

          _postController.clear();
        } else {
          // Handle image upload failure
        }
      }
    }
  }



  void _postComment(Post post) {
    final user = _auth.currentUser;
    final commentText = _commentController.text;

    if (user != null && commentText.isNotEmpty) {
      final commentModel = Comment(
        userId: user.uid,
        text: commentText,
      );

      _firestore.collection('comments').add({
        'postId': post.documentId, // Associate the comment with the post
        'userId': commentModel.userId,
        'text': commentModel.text,
      });

      _commentController.clear();
    }
  }

}

class Post {
  final String userId;
  final String? imageUrl; // Change this line to allow nullable values
  final String caption;
  final int likes;
  String? documentId;
  final List<Comment> comments;
  bool isLiked;

  Post({
    required this.userId,
    this.imageUrl, // Update this line to allow nullable values
    required this.caption,
    required this.likes,
    required this.comments,
    this.documentId,
    this.isLiked = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'imageUrl': imageUrl, // Use nullable imageUrl property
      'caption': caption,
      'likes': likes,
      'isLiked': isLiked,
    };
  }
}

class Comment {
  final String userId;
  final String text;

  Comment({
    required this.userId,
    required this.text,
  });
}
