import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  Widget build(BuildContext context) {
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
        // Mover a tarefa para esta coluna
        await tasksCollection.doc(draggedTask['taskId']).set({
          'title': draggedTask['title'],
          'message': draggedTask['message'],
          'color': draggedTask['color'],
          'receiverUid': draggedTask['receiverUid'],
        });

        if (columnId == draggedTask['sourceColumnId']) {
          return;
        } else {
            // Remover a tarefa da coluna original
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
        return Container(
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
                  style: GoogleFonts.getFont('Fascinate Inline',
                      fontSize: 18, fontWeight: FontWeight.bold),
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

                        return Draggable<Map<String, dynamic>>(
                          data: {
                            'taskId': task.id,
                            'title': data['title'],
                            'message': data['message'],
                            'color': data['color'],
                            'receiverUid': data['receiverUid'],
                            'sourceColumnId': columnId,
                          },
                          feedback: Material(
                            child: BoardCard(
                              title: data['title'] ?? 'Sem título',
                              message: data['message'] ?? 'Sem descrição',
                              color: data['color'] ?? '#FFFFFF',
                              receiverUid:
                                  data['receiverUid'] ?? 'Sem delegação',
                            ),
                          ),
                          child: BoardCard(
                            title: data['title'] ?? 'Sem título',
                            message: data['message'] ?? 'Sem descrição',
                            color: data['color'] ?? '#FFFFFF',
                            receiverUid: data['receiverUid'] ?? 'Sem delegação',
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
