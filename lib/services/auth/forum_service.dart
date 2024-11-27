/*
  Forum Service
  Feito por: Rodrigo abreu Amorim
  Ultima modificação: 27/11/2024
 */

import 'package:app_mensagem/model/forum.dart';
import 'package:app_mensagem/pages/recursos/get_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForumService {
  // Atributos das instâncias do firebase
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  // Instância para usar a classe GetUser
  GetUser getUserName = GetUser();

  ///////////////////////////
  /// Método para criar um novo forum
  Future<void> createForum(String name, String message) async {
    try {
      String uid = _auth.currentUser!.uid;
      var username = await getUserName.getUserName(uid);

      String enterpriseCode = await getEnterpriseCode(uid);

      await _db
          .collection('enterprise')
          .doc(enterpriseCode)
          .collection('forums')
          .add({
        'uid': uid,
        'name': name,
        'username': username,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'likeCount': 0,
        'likedBy': [],
      });
    } catch (e) {
      throw Exception('Erro ao criar fórum: $e');
    }
  }

  /////////////////
  /// Método para deletar um forum
  Future<void> deleteForum(String forumId) async {
    try {
      await _db.collection('forums').doc(forumId).delete();
    } catch (e) {
      throw Exception('Erro ao deletar fórum: $e');
    }
  }

  /////////////////
  /// Método para buscar todos os forums do firebase
  Future<List<Post>> fetchForums() async {
    String uid = _auth.currentUser!.uid;
    String enterpriseCode = await getEnterpriseCode(uid);

    try {
      QuerySnapshot snapshot = await _db
          .collection('enterprise')
          .doc(enterpriseCode)
          .collection('forums')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar fóruns: $e');
    }
  }

  //////////////////
  /// Método para curtir um Forum
  Future<void> likeForum(String forumId) async {
    try {
      String uid = _auth.currentUser!.uid;
      String enterpriseCode = await getEnterpriseCode(uid);

      DocumentReference forumRef = _db
          .collection('enterprise')
          .doc(enterpriseCode)
          .collection('forums')
          .doc(forumId);

      DocumentSnapshot doc = await forumRef.get();
      List likedBy = doc['likedBy'];

      if (!likedBy.contains(uid)) {
        await forumRef.update({
          'likeCount': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([uid]),
        });
      }
    } catch (e) {
      throw Exception('Erro ao curtir fórum: $e');
    }
  }

  /////////////////////
  /// Método para buscar as respostas
  Future<List<Object?>> fetchReplies(String forumId) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('forums')
          .doc(forumId)
          .collection('replies')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Erro ao buscar respostas: $e');
    }
  }

  /////////////////////
  /// Método para adicionar uma resposta
  Future<void> addReply(String forumId, String message) async {
    try {
      String uid = _auth.currentUser!.uid;
      var username = await getUserName.getUserName(uid);

      await _db.collection('forums').doc(forumId).collection('replies').add({
        'uid': uid,
        'username': username,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erro ao responder: $e');
    }
  }

  ///////////////////////
  /// Método para buscar a empresa do usuário cadastrado
  Future<String> getEnterpriseCode(String uid) async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    String enterpriseCode = userDoc['code'];

    return enterpriseCode;
  }
}
