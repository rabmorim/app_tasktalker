/*
  Página do Fórum
  Feito por: Rodrigo Abreu Amorim
  Última modificação: 04/12/2024
 */

import 'package:app_mensagem/model/forum.dart';
import 'package:app_mensagem/pages/forum_reply_page.dart';
import 'package:app_mensagem/pages/recursos/barra_superior.dart';
import 'package:app_mensagem/pages/recursos/drawer.dart';
import 'package:app_mensagem/pages/recursos/modal_forum.dart';
import 'package:app_mensagem/services/forum_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

class ForumPage extends StatelessWidget {
  const ForumPage({super.key});

  @override
  Widget build(BuildContext context) {
    final forumProvider = Provider.of<ForumProvider>(context, listen: true);
    forumProvider.fetchForums();
    List<Post> foruns = forumProvider.getForums;
    final auth = FirebaseAuth.instance;
    String uid = auth.currentUser!.uid;

    return Scaffold(
      appBar: const BarraSuperior(
        titulo: "Fórum",
        isCalendarPage: false,
      ),
      drawer: const MenuDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: ListView.builder(
          itemCount: foruns.length,
          itemBuilder: (context, index) {
            final forum = foruns[index];
            final isLiked = forum.likedBy.contains(forumProvider.currentUserId);
            final isCurrentUser = forum.uid == uid;

            return GestureDetector(
              onLongPressStart: isCurrentUser
                  ? (details) {
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
                            onTap: () => _editForum(
                              context,
                              forum.id,
                              forum.name,
                              forum.message,
                              forumProvider,
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'Excluir',
                            child: const ListTile(
                              leading: Icon(Icons.delete),
                              title: Text('Excluir'),
                            ),
                            onTap: () => _deleteForum(
                              context,
                              forum.id,
                              forumProvider,
                            ),
                          ),
                        ],
                      );
                    }
                  : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.6),
                      blurRadius: 6.0,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  title: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4.0),
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 18,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            forum.username,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 4.0),
                      Text(
                        forum.name,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        getPreview(forum.message),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const SizedBox(width: 4),
                          IconButton(
                            icon: Badge.count(
                              backgroundColor: Colors.grey,
                              count: forum.likeCount,
                              child: Icon(
                                isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isLiked ? Colors.red : Colors.grey,
                              ),
                            ),
                            onPressed: () async {
                              if (isLiked) {
                                await forumProvider.unlikeForum(forum.id);
                              } else {
                                await forumProvider.likeForum(forum.id);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ForumReplyPage(
                          forumTitle: forum.name,
                          forumMessage: forum.message,
                          username: forum.username,
                          forumId: forum.id,
                          currentUserId: uid,
                        ),
                      ),
                    );
                  },
                ),
              )
                  // Adiciona a animação de entrada
                  .animate()
                  .fadeIn(duration: 900.ms, delay: (index * 400).ms)
                  .move(
                      begin: const Offset(-100, 0), curve: Curves.easeOutQuad),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showCreateForumModal(
            context: context,
            onForumCreated: (forumData) async {
              try {
                await forumProvider.createForum(
                  forumData['name'],
                  forumData['message'],
                );

                // Exibir sucesso
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Fórum criado com sucesso!")),
                  );
                }
              } catch (e) {
                // Mostrar erro
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Erro ao criar fórum: $e")),
                  );
                }
              }
            },
          );
        },
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  /////////////////////////////
  /// Método para Editar um fórum
  void _editForum(BuildContext context, String forumId, String currentName,
      String currentMessage, ForumProvider forumProvider) {
    TextEditingController nameController =
        TextEditingController(text: currentName);
    TextEditingController messageController =
        TextEditingController(text: currentMessage);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Editar Fórum"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Nome"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(labelText: "Mensagem"),
                  maxLines: null, // Permite linhas ilimitadas
                  minLines: 5, // Define o mínimo de linhas visíveis
                  keyboardType: TextInputType.multiline,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await forumProvider.updateForum(
                  forumId,
                  nameController.text,
                  messageController.text,
                );
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
              },
              child: const Text(
                "Salvar",
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        );
      },
    );
  }

  /////////////////////////////
  /// Método para limitar a mensagem do fórum
  String getPreview(String message) {
    const int maxLength = 50;
    return message.length > maxLength
        ? '${message.substring(0, maxLength)}...'
        : message;
  }

  /////////////////////////////
  /// Método para Deletar um forum
  void _deleteForum(
      BuildContext context, String forumId, ForumProvider forumProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Excluir Fórum"),
          content: const Text("Tem certeza que deseja excluir este fórum?"),
          actions: [
            TextButton(
              onPressed: () async {
                await forumProvider.deleteForum(forumId);
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
              },
              child: const Text(
                "Excluir",
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        );
      },
    );
  }
}
