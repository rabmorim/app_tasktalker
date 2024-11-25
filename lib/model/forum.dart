/*
  Modelo Do Forum
  Feito por: Rodrigo abreu Amorim
  Ultima modificação: 25/11/2024
 */

import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id; // Id do Forum
  final String uid; // uid de quem fez o Forum
  final String name; //Nome do Forum
  final String username; // Username de quem criou o Forum
  final String message; // Mensagem do post
  final Timestamp timestamp; // Timestamp do forum
  final int likeCount; // Número de pessoas que gostaram deste forum
  final List<String> likedBy; // Lista de pessoas que gostaram desse forum

  Post({
    required this.id,
    required this.uid,
    required this.name,
    required this.username,
    required this.message,
    required this.timestamp,
    required this.likeCount,
    required this.likedBy,
  });

  ///////////////////////
  /// Método para converter o documento do firestore em um Post no forum
  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      id: doc.id,
      uid: doc['uid'],
      name: doc['name'],
      username: doc['username'],
      message: doc['message'],
      timestamp: doc['timestamp'],
      likeCount: doc['likeCount'],
      likedBy: List<String>.from(doc['likedBy'] ?? []),
    );
  }

  ///////////////////////////////
  ///Método para converter em Map
  Map<String,dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'username': username,
      'message': message,
      'timestamp': timestamp,
      'likes': likeCount,
      'likedBy': likedBy
    };
  }
}
