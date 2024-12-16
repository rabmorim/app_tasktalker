/*
  Página de Construção do Card das tarefas no Kanban
  Feito por: Rodrigo abreu Amorim
  Ultima modificação: 16/12/2024
 */
import 'package:app_mensagem/pages/details_task_page.dart';
import 'package:app_mensagem/pages/recursos/get_user.dart';
import 'package:flutter/material.dart';

class BoardCard extends StatelessWidget {
  final String title; // Título da tarefa
  final String message; // Descrição ou detalhes da tarefa
  final String color; // Cor associada ao usuário
  final String receiverUid; // uid do usuário delegado
  final String priority; // Prioridade da tarefa delegada
  final List<String> labels; // Lista de labels
  final String taskId; // Id da tarefa
  final String enterpriseId; // Id da empresa do usuário autenticado
  final GetUser _getUser = GetUser(); // Instância do getUser
  final String columnId; // Id da coluna da tarefa
  final String boardId; // Id do quadro kanban

  BoardCard({
    super.key,
    required this.title,
    required this.message,
    required this.color,
    required this.receiverUid,
    required this.priority,
    required this.labels,
    required this.taskId,
    required this.enterpriseId,
    required this.boardId,
    required this.columnId
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getUser.getUserName(receiverUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            color: Color(int.parse(color.replaceFirst('#', '0xff'))),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.white54,
                ),
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            color: Color(int.parse(color.replaceFirst('#', '0xff'))),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Erro ao carregar nome do usuário',
                style: TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        final String userName = snapshot.data ?? 'Usuário desconhecido';
        final cardColor = Color(int.parse(color.replaceFirst('#', '0xff')));
        Color textColor = Colors.white;

        // Badge de prioridade com texto diferente baseado no valor
        String priorityText;
        Color badgeColor;

        switch (priority.toLowerCase()) {
          case 'alta':
            priorityText = 'ALTA';
            badgeColor = Colors.red;
            break;
          case 'média':
            priorityText = 'MÉDIA';
            badgeColor = Colors.black;
            break;
          case 'baixa':
          default:
            priorityText = 'BAIXA';
            badgeColor = Colors.black;
        }

        return GestureDetector(
          onTap: () {
            //Navega para a página de detalhes da tarefa
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetalhesTarefaPage(
                  taskId: taskId,
                  title: title,
                  message: message,
                  color: color,
                  receiverUid: receiverUid,
                  priority: priority,
                  labels: labels,
                  enterpriseId: enterpriseId,
                  boardId: boardId,
                  columnId: columnId
                ),
              ),
            );
          },
          child: Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            userName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          priorityText,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Labels usando Chips
                  Wrap(
                    spacing: 8.0, // Espaçamento horizontal entre os chips
                    runSpacing:
                        4.0, // Espaçamento vertical entre as linhas de chips
                    children: labels
                        .map(
                          (label) => Chip(
                            label: Text(
                              label,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            padding: const EdgeInsets.all(-1),
                            backgroundColor: Colors.white.withOpacity(0.7),
                          ),
                        )
                        .toList(),
                  ),

                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
