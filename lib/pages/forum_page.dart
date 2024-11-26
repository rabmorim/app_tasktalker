/*
  Página do Fórum
  Feito por: Rodrigo abreu Amorim
  Última modificação: 26/11/2024
 */

import 'package:app_mensagem/model/forum.dart';
import 'package:app_mensagem/pages/recursos/barra_superior.dart';
import 'package:app_mensagem/pages/recursos/drawer.dart';
import 'package:app_mensagem/pages/recursos/modal_forum.dart';
import 'package:app_mensagem/services/auth/forum_service.dart';
import 'package:flutter/material.dart';

class ForumPage extends StatefulWidget {
  const ForumPage({super.key});

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  final ForumService _forumService = ForumService();

  // Método para limitar a mensagem do fórum
  String getPreview(String message) {
    const int maxLength = 50;
    return message.length > maxLength
        ? '${message.substring(0, maxLength)}...'
        : message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BarraSuperior(
        titulo: "Fórum",
        isCalendarPage: false,
      ),
      drawer: const MenuDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: FutureBuilder<List<Post>>(
          future: _forumService.fetchForums(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.white54,
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text("Erro ao carregar fóruns: ${snapshot.error}"),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text("Nenhum fórum encontrado."),
              );
            }

            final forums = snapshot.data!;

            return ListView.builder(
              itemCount: forums.length,
              itemBuilder: (context, index) {
                final forum = forums[index];
                return Container(
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
                                letterSpacing: 2
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
                      ],
                    ),
                    onTap: () {
                      // Redirecionar para a página de detalhes do fórum
                    },
                  ),
                );
              },
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
                // Passar os dados individualmente para o método
                await ForumService().createForum(
                  forumData['name'],
                  forumData['message'],
                );

                // Exibir sucesso
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Fórum criado com sucesso!")),
                  );
                  setState(() {
                    // Atualizar a interface se necessário
                  });
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
}
