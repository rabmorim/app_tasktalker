/*
  Página de comentários dos Fóruns
  Feito por: Rodrigo Abreu Amorim
  Última modificação: 28/11/2024
 */

import 'package:app_mensagem/pages/recursos/barra_superior.dart';
import 'package:app_mensagem/pages/recursos/drawer.dart';
import 'package:app_mensagem/services/auth/chat/chat_forum_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final ForumCommentService _forumCommentService = ForumCommentService();
  Stream<QuerySnapshot<Object?>>? _commentsStream;

  @override
  void initState() {
    super.initState();
    _commentsStream = _forumCommentService.getComments(widget.forumId);
  }

  //////////////////
  /// Método para adicionar um comentário
  void _addComment() {
    final text = _commentController.text.trim();
    if (text.isNotEmpty) {
      _forumCommentService.addComment(widget.forumId, text).then((_) {
        _commentController.clear();
      }).catchError((error) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao adicionar comentário: $error")),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BarraSuperior(
          titulo: 'Comentários do Forum', isCalendarPage: false),
      drawer: const MenuDrawer(),
      body: SingleChildScrollView(
        child: SizedBox(
          height: 730,
          child: Column(
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
        ),
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
    return SizedBox(
        child: StreamBuilder<QuerySnapshot>(
      stream: _commentsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Erro: ${snapshot.error}"));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Nenhum comentário ainda."));
        }

        final comments = snapshot.data!.docs;

        return ListView.builder(
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index];
            final isCurrentUser = comment['userId'] == widget.currentUserId;

            return Align(
              alignment:
                  isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
              child: GestureDetector(
                onLongPressStart: isCurrentUser
                    ? (LongPressStartDetails details) {
                        showMenu(
                          context: context,
                          position: RelativeRect.fromLTRB(
                            details.globalPosition.dx,
                            details.globalPosition.dy,
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
                              onTap: () =>
                                  _editComment(comment.id, comment['message']),
                            ),
                            PopupMenuItem<String>(
                              value: 'Excluir',
                              child: const ListTile(
                                leading: Icon(Icons.delete),
                                title: Text('Excluir'),
                              ),
                              onTap: () => _deleteComment(comment.id),
                            ),
                          ],
                        );
                      }
                    : null,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: isCurrentUser ? Colors.white54 : Colors.grey[200],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12),
                      topRight: const Radius.circular(12),
                      bottomLeft: Radius.circular(isCurrentUser ? 12 : 0),
                      bottomRight: Radius.circular(isCurrentUser ? 0 : 12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      isCurrentUser
                          ? Text(
                              comment['userName'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.black,
                              ),
                            )
                          : Text(
                              comment['userName'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.black,
                              ),
                            ),
                      const SizedBox(height: 4),
                      isCurrentUser
                          ? Text(
                              comment['message'],
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.white),
                            )
                          : Text(
                              comment['message'],
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black),
                            )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ));
  }

  ////////////////////////////////
  /// Método para editar o comentário
  void _editComment(String commentId, String currentMessage) {
    _commentController.text = currentMessage;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Editar Comentário"),
          content: TextField(
            controller: _commentController,
            decoration: const InputDecoration(labelText: "Novo comentário"),
          ),
          actions: [
            TextButton(
                child: const Text(
                  "Cancelar",
                  style: TextStyle(color: Colors.white54),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _commentController.clear();
                }),
            TextButton(
              child: const Text(
                "Salvar",
                style: TextStyle(color: Colors.white54),
              ),
              onPressed: () {
                _forumCommentService.updateComment(
                    widget.forumId, commentId, _commentController.text);
                Navigator.pop(context);
                _commentController.clear();
              },
            ),
          ],
        );
      },
    );
  }

  ////////////////////////////////
  /// Método para excluir o comentário
  void _deleteComment(String commentId) {
    _forumCommentService.deleteComment(widget.forumId, commentId);
  }

  //////////////////////
  /// Widget: Campo de texto para comentários
  Widget _buildCommentInput() {
    return Container(
      clipBehavior: Clip.none,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
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
            color: Colors.grey,
            onPressed: _addComment,
          ),
        ],
      ),
    );
  }
}
