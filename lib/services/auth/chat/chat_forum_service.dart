/*
  Chat forum service
  Feito por: Rodrigo abreu Amorim
  Ultima modificação: 02/12/2024
 */
import 'package:app_mensagem/pages/recursos/get_user.dart';
import 'package:app_mensagem/services/auth/forum_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForumCommentService {
  //Atributos
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final ForumService _forumService = ForumService();
  final GetUser _getUser = GetUser();

  ////////////////////////////////
  /// Método para adicionar um comentário
  Future<void> addComment(String forumId, String message) async {
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    final String currentUserEmail = _firebaseAuth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();
    final enterpriseCode = await _forumService.getEnterpriseCode(currentUserId);
    final String? userName = await _getUser.getUserName(currentUserId);

    // Criar o comentário como um documento
    final commentData = {
      'userId': currentUserId,
      'userEmail': currentUserEmail,
      'message': message,
      'timestamp': timestamp,
      'userName': userName
    };

    // Adicionar comentário na subcoleção "comments" dentro do fórum
    await _firebaseFirestore
        .collection('enterprise')
        .doc(enterpriseCode)
        .collection('forums')
        .doc(forumId)
        .collection('comments')
        .add(commentData);
  }

  ////////////////////////
  /// Método para obter comentários do fórum
  Stream<QuerySnapshot<Object?>> getComments(String forumId) {
    final String currentUserId = _firebaseAuth.currentUser!.uid;

    // Recuperar o código da empresa de forma assíncrona e retornar o Stream
    return _forumService
        .getEnterpriseCode(currentUserId)
        .asStream()
        .asyncExpand(
      (enterpriseCode) {
        return _firebaseFirestore
            .collection('enterprise')
            .doc(enterpriseCode)
            .collection('forums')
            .doc(forumId)
            .collection('comments')
            .orderBy('timestamp', descending: false)
            .snapshots();
      },
    );
  }

////////////////////////////////
  /// Método para atualizar um comentário
  Future<void> updateComment(
      String forumId, String commentId, String newMessage) async {
    try {
      final String currentUserId = _firebaseAuth.currentUser!.uid;
      final enterpriseCode =
          await _forumService.getEnterpriseCode(currentUserId);
      await _firebaseFirestore
          .collection('enterprise')
          .doc(enterpriseCode)
          .collection('forums')
          .doc(forumId)
          .collection('comments')
          .doc(commentId)
          .update({
        'message': newMessage,
        'updatedAt': FieldValue.serverTimestamp(), // Marca o horário da edição
      });
    } catch (e) {
      throw Exception("Erro ao atualizar comentário: $e");
    }
  }

  ////////////////////////////////
  /// Método para excluir um comentário
  Future<void> deleteComment(String forumId, String commentId) async {
    try {
      final String currentUserId = _firebaseAuth.currentUser!.uid;
      final enterpriseCode =
          await _forumService.getEnterpriseCode(currentUserId);
      await _firebaseFirestore
          .collection('enterprise')
          .doc(enterpriseCode)
          .collection('forums')
          .doc(forumId)
          .collection('comments')
          .doc(commentId)
          .delete();
    } catch (e) {
      throw Exception("Erro ao excluir comentário: $e");
    }
  }
}
