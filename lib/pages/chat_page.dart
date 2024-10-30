import 'package:app_mensagem/pages/recursos/barra_superior.dart';
import 'package:app_mensagem/pages/recursos/chat_bubble.dart';
import 'package:app_mensagem/pages/recursos/text_field.dart';
import 'package:app_mensagem/services/auth/chat/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  final String receiverUserEmail;
  final String receiverUserID;
  final String receiverUserName;
  const ChatPage({
    super.key,
    required this.receiverUserEmail,
    required this.receiverUserID,
    required this.receiverUserName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  /////////////////////////////
  ///Método para enviar mensagem
  void sendMessage() async {
    //Verificando se a mensagem nao está vazia, permitindo apenas campos nao vazios.
    if (_messageController.text.isNotEmpty) {
      await _chatService.sendMessage(
        widget.receiverUserID,
        _messageController.text,
      );
      //limpar o campo de texto depois de enivar o texto para o remetente
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BarraSuperior(titulo: widget.receiverUserName, isCalendarPage: false,),
      body: Column(
        children: [
          //mensagens
          Expanded(
            child: _buildMessageList(),
          ),

          //Entrada de valores

          _buildMessageInput()
        ],
      ),
    );
  }

  ////////////////////
  ///Método para Construir lista de mensagens
  Widget _buildMessageList() {
    return StreamBuilder(
      stream: _chatService.getMessage(
          widget.receiverUserID, _firebaseAuth.currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error${snapshot.hasError}');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          );
        }
        return ListView(
          children: snapshot.data!.docs
              .map(
                (document) => _buildMessageItem(document),
              )
              .toList(),
        );
      },
    );
  }

  /////////////////////////
  /// Método para Construir o item da mensagem
  Widget _buildMessageItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    //Alinhar a mensagem do destinatario a esquerda e do remetente na direita
    var alignment = (data['senderId'] == _firebaseAuth.currentUser!.uid)
        ? Alignment.centerRight
        : Alignment.centerLeft;
    String user = data['senderUserName'] ?? "user null";
    String message = data['message'] ?? "message null";
    return Container(
      alignment: alignment,
      child: Column(
        crossAxisAlignment: (data['senderId'] == _firebaseAuth.currentUser!.uid)
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisAlignment: (data['senderId'] == _firebaseAuth.currentUser!.uid)
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [Text(user), 
        const SizedBox(height: 5,),
        ChatBubble(message: message)],
      ),
    );
  }

  ///////////////////
  /// Método para Construir a area de input da mensagem
  Widget _buildMessageInput() {
    return Row(
      children: [
        //Textfield
        Expanded(
            child: MyTextField(
                controller: _messageController,
                labelText: 'Insira a mensagem',
                obscureText: false)),

        //botão de enviar
        IconButton(
            onPressed: sendMessage,
            icon: const Icon(
              Icons.arrow_upward,
              size: 40,
            ))
      ],
    );
  }
}
