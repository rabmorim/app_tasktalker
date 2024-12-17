/*
  Página de Construção das Colunas do kanban
  Feito por: Rodrigo Abreu Amorim
  Ultima modificação: 12/12/2024
 */
import 'package:app_mensagem/services/kanban_provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'board_card.dart';

class BoardList extends StatelessWidget {
  final String title; // Nome da coluna
  final String columnId; // Id da coluna
  final String boardId; // Id do quadro Kanban
  final String enterpriseId; // Id da empresa

  const BoardList({
    super.key,
    required this.title,
    required this.columnId,
    required this.boardId,
    required this.enterpriseId,
  });
  //////////////////////////////////
  /// Método para deletar a coluna
  Future<void> _deleteColumn(BuildContext context) async {
    final bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar exclusão"),
        content: const Text("Tem certeza que deseja excluir esta coluna?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              "Cancelar",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              "Excluir",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      await FirebaseFirestore.instance
          .collection('enterprise')
          .doc(enterpriseId)
          .collection('kanban')
          .doc(boardId)
          .collection('columns')
          .doc(columnId)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = Provider.of<KanbanProvider>(context).isEditingColumns;
    final tasksCollection = FirebaseFirestore.instance
        .collection('enterprise')
        .doc(enterpriseId)
        .collection('kanban')
        .doc(boardId)
        .collection('columns')
        .doc(columnId)
        .collection('tasks');

    return DragTarget<Map<String, dynamic>>(
      // ignore: deprecated_member_use
      onAccept: (draggedTask) async {
        await tasksCollection.doc(draggedTask['taskId']).set({
          'title': draggedTask['title'],
          'message': draggedTask['message'],
          'color': draggedTask['color'],
          'receiverUid': draggedTask['receiverUid'],
          'priority': draggedTask['priority'],
          'timestamp': draggedTask['timestamp'],
          'uid': draggedTask['uid'],
          'labels': draggedTask['labels'],
          'enterpriseId': draggedTask['enterpriseId'],
        });

        if (columnId != draggedTask['sourceColumnId']) {
          await FirebaseFirestore.instance
              .collection('enterprise')
              .doc(enterpriseId)
              .collection('kanban')
              .doc(boardId)
              .collection('columns')
              .doc(draggedTask['sourceColumnId'])
              .collection('tasks')
              .doc(draggedTask['taskId'])
              .delete();
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Stack(
          children: [
            Container(
              width: 250,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      title,
                      style: GoogleFonts.getFont(
                        'Fascinate Inline',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(
                    color: Colors.black,
                    height: 15,
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: tasksCollection.snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white54,
                            ),
                          );
                        }

                        final docs = snapshot.data!.docs;

                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final task = docs[index];
                            final data = task.data() as Map<String, dynamic>;
                            final List<dynamic> rawLabels = data['labels'];
                            final List<String> labels =
                                rawLabels.cast<String>();

                            return Draggable<Map<String, dynamic>>(
                              data: {
                                'taskId': task.id,
                                'title': data['title'],
                                'message': data['message'],
                                'color': data['color'],
                                'receiverUid': data['receiverUid'],
                                'sourceColumnId': columnId,
                                'priority': data['priority'],
                                'timestamp': data['timestamp'],
                                'uid': data['uid'],
                                'labels': labels,
                                'enterpriseId': enterpriseId,
                              },
                              feedback: Material(
                                child: BoardCard(
                                  title: data['title'] ?? 'Sem título',
                                  message: data['message'] ?? 'Sem descrição',
                                  color: data['color'] ?? '#FFFFFF',
                                  receiverUid:
                                      data['receiverUid'] ?? 'Sem delegação',
                                  priority:
                                      data['priority'] ?? 'Sem prioridade',
                                  labels: labels,
                                  taskId: task.id,
                                  enterpriseId: enterpriseId,
                                  boardId: boardId,
                                  columnId: columnId,
                                ),
                              ),
                              child: BoardCard(
                                title: data['title'] ?? 'Sem título',
                                message: data['message'] ?? 'Sem descrição',
                                color: data['color'] ?? '#FFFFFF',
                                receiverUid:
                                    data['receiverUid'] ?? 'Sem delegação',
                                priority: data['priority'] ?? 'Sem prioridade',
                                labels: labels,
                                taskId: task.id,
                                enterpriseId: enterpriseId,
                                boardId: boardId,
                                columnId: columnId,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (isEditing)
              Positioned(
                right: 0,
                top: 0,
                child: IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () {
                    _deleteColumn(context);
                  }   
                ),
              ),
          ],
        );
      },
    );
  }
}
