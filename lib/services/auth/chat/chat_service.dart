import 'package:app_mensagem/model/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatService extends ChangeNotifier {
  //Pegando a instância de autenticação e do firestore
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  /////////////////////////////////////
  ///Método de enviar mensagem
  Future<void> sendMessage(String receiverId, String message) async {
    //Pegando informação do usuario que está enviando a mensagem e o horario e data do envio
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    final String currentUseremail = _firebaseAuth.currentUser!.email.toString();
    final String currentUSerName = await _getUserName(currentUserId);
    final Timestamp timestamp = Timestamp.now();

    // Criar nova mensagem
    Message newMessage = Message(
        senderId: currentUserId,
        senderEmail: currentUseremail,
        receiverId: receiverId,
        senderUserName: currentUSerName,
        timestamp: timestamp,
        message: message);

    // construir o ID da sala de bate-papo a partir do ID do usuário atual e do ID do receptor(Ordenado para fazer sentido)
    List<String> ids = [currentUserId, receiverId];
    ids.sort(); //isso garante que o ID da sala de bate-papo seja sempre o mesmo para qualquer par de pessoas.
    String chatRoomId =
        ids.join("_"); // combinando os ids com um simples _ entre eles.

    // Adicionando a nova mensagem no banco de dados
    await _firebaseFirestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(newMessage.toMap());
  }

  /////////////////////////////////////
  ///Método para buscar o userName do usuario
  Future<String> _getUserName(String userId) async {
    DocumentSnapshot userDoc =
        await _firebaseFirestore.collection('users').doc(userId).get();
    return userDoc.get('userName') ?? 'Unknown User';
  }

  ////////////////////////////////////////
  ///Método de receber mensagem (get message)
  Stream<QuerySnapshot> getMessage(String userId, String otherUserId) {
    //Obter o Id da sala de bate papo deles
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join("_");

    return _firebaseFirestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  ////////////////////////////////////////
  /// Método para atualizar a mensagem
  Future<void> updateMessage(
      String receiverId, String messageId, String newMessageContent) async {
    final String currentUserId = _firebaseAuth.currentUser!.uid;

    // Obter o ID da sala de bate-papo com base no ID do usuário atual e do receptor
    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join("_");

    try {
      await _firebaseFirestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .update({'message': newMessageContent, 'timestamp': Timestamp.now()});
      notifyListeners(); // Notifica sobre a atualização
    } catch (e) {
      print("Erro ao atualizar a mensagem: $e");
    }
  }

  ////////////////////////////////////////
  /// Método para excluir a mensagem
  Future<void> deleteMessage(String receiverId, String messageId) async {
    final String currentUserId = _firebaseAuth.currentUser!.uid;

    // Obter o ID da sala de bate-papo com base no ID do usuário atual e do receptor
    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join("_");

    try {
      await _firebaseFirestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .delete();
      notifyListeners(); // Notifica sobre a exclusão
    } catch (e) {
      print("Erro ao excluir a mensagem: $e");
    }
  }
}
