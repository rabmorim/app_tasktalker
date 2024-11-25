/*
  Modelo Da mensagem
  Feito por: Rodrigo abreu Amorim
  Ultima modificação: 25/11/2024
 */

import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderId;
  final String senderEmail;
  final String receiverId;
  final String message;
  final Timestamp timestamp;
  final String senderUserName;

  Message(
      {
      required this.senderUserName,
      required this.senderId,
      required this.senderEmail,
      required this.receiverId,
      required this.timestamp,
      required this.message});

  ///////////////////////////////
  ///Método para converter em Map

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderEmail': senderEmail,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
      'senderUserName': senderUserName
    };
  }
}
