/*
  Página de comentários dos Fóruns
  Feito por: Rodrigo Abreu Amorim
  Última modificação: 28/11/2024
 */

import 'package:app_mensagem/pages/recursos/barra_superior.dart';
import 'package:app_mensagem/pages/recursos/drawer.dart';
import 'package:flutter/material.dart';

class ForumReplyPage extends StatefulWidget {
  final String forumTitle;
  final String forumMessage;
  final String username;
  final String forumId;
  final String currentUserId;

  const ForumReplyPage({
    super.key,
    required this.forumTitle,
    required this.forumMessage,
    required this.username,
    required this.forumId,
    required this.currentUserId,
  });

  @override
  State<ForumReplyPage> createState() => _ForumReplyPageState();
}

class _ForumReplyPageState extends State<ForumReplyPage> {
  final TextEditingController _commentController = TextEditingController();
  final List<Map<String, String>> _comments = []; // Mock para comentários

  //////////////////
  /// Método para adicionar um comentário
  void _addComment() {
    final text = _commentController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _comments.add({
          "userId": widget.currentUserId,
          "message": text,
        });
      });
      _commentController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BarraSuperior(
          titulo: 'Comentários do Forum', isCalendarPage: false),
      drawer: const MenuDrawer(),
      body: Column(
        children: [
          // Card com informações do fórum
          _buildForumCard(),
          const Divider(height: 2, color: Colors.grey),
          // ListView para os comentários
          Expanded(child: _buildCommentsList()),
          // Campo de texto para adicionar novos comentários
          _buildCommentInput(),
        ],
      ),
    );
  }

  /////////////////////////
  /// Widget: Card com informações do fórum
  Widget _buildForumCard() {
    return SizedBox(
      width: double.infinity, // Largura total
      height: MediaQuery.of(context).size.height * 0.5, // 50% da altura da tela
      child: Card(
        margin: const EdgeInsets.all(16.0),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch, // Alinha ao início por padrão
            children: [
              // Título centralizado
              Text(
                widget.forumTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center, // Centraliza horizontalmente
              ),
              const SizedBox(height: 8.0),

              // Nome do autor alinhado ao início
              Align(
                alignment: Alignment.centerLeft, // Alinha ao início
                child: Text(
                  "Por: ${widget.username}",
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 16.0),

              // Mensagem do fórum alinhada ao início
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    widget.forumMessage,
                    style: const TextStyle(fontSize: 16),
                    textAlign:
                        TextAlign.start, // Garante o alinhamento ao início
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //////////////////
  /// Widget: ListView com os comentários
  Widget _buildCommentsList() {
    return ListView.builder(
      itemCount: _comments.length,
      itemBuilder: (context, index) {
        final comment = _comments[index];
        final isCurrentUser = comment["userId"] == widget.currentUserId;

        return Align(
          alignment:
              isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: isCurrentUser ? Colors.blue[100] : Colors.grey[200],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: Radius.circular(isCurrentUser ? 12 : 0),
                bottomRight: Radius.circular(isCurrentUser ? 0 : 12),
              ),
            ),
            child: Text(
              comment["message"] ?? "",
              style: const TextStyle(fontSize: 14),
            ),
          ),
        );
      },
    );
  }

  //////////////////////
  /// Widget: Campo de texto para comentários
  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            blurRadius: 4.0,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: "Escreva um comentário",
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            color: Colors.blue,
            onPressed: _addComment,
          ),
        ],
      ),
    );
  }
}
