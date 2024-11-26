/*
  Página do chat
  Feito por: Rodrigo abreu Amorim
  Ultima modificação: 25/11/2024
 */

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
}////////////

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
      appBar: BarraSuperior(
        titulo: widget.receiverUserName,
        isCalendarPage: false,
      ),
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
        children: [
          Text(user),
          const SizedBox(height: 5),

          // Envolvendo o ChatBubble com GestureDetector para long press
          if (data['senderId'] == _firebaseAuth.currentUser!.uid)
            GestureDetector(
              onLongPressStart: (LongPressStartDetails details) {
                // Mostrar PopupMenuButton ao segurar a mensagem
                showMenu(
                  context: context,
                  position: RelativeRect.fromLTRB(
                    details.globalPosition.dx, // Posição horizontal
                    details.globalPosition.dy, // Posição vertical
                    details.globalPosition.dx,
                    details.globalPosition.dy,
                  ),
                  items: [
                    PopupMenuItem<String>(
                      value: 'Editar',
                      child: const ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Editar'),
                      ),
                      onTap: () => _editMessage(document.id, message),
                    ),
                    PopupMenuItem<String>(
                      value: 'Excluir',
                      child: const ListTile(
                        leading: Icon(Icons.delete),
                        title: Text('Excluir'),
                      ),
                      onTap: () => _deleteMessage(document.id),
                    ),
                  ],
                );
              },
              child: ChatBubble(message: message),
            ),
          if (data['senderId'] != _firebaseAuth.currentUser!.uid)
            ChatBubble(message: message)
        ],
      ),
    );
  }

  ////////////////////////////////
  /// Método para editar a mensagem
  void _editMessage(String messageId, String currentMessage) {
    // Exemplo de implementação básica:
    _messageController.text =
        currentMessage; // Preenche com o conteúdo atual para editar
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Editar Mensagem"),
          content: TextField(
            controller: _messageController,
            decoration: const InputDecoration(labelText: "Nova mensagem"),
          ),
          actions: [
            TextButton(
              child: const Text(
                "Cancelar",
                style: TextStyle(color: Colors.white54),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text(
                "Salvar",
                style: TextStyle(color: Colors.white54),
              ),
              onPressed: () {
                _chatService.updateMessage(
                    widget.receiverUserID, messageId, _messageController.text);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  ////////////////////////////////
  /// Método para excluir a mensagem
  void _deleteMessage(String messageId) {
    _chatService.deleteMessage(widget.receiverUserID, messageId);
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
