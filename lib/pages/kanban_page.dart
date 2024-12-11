import 'package:app_mensagem/pages/recursos/board_list.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class KanbanBoard extends StatelessWidget {
  final String enterpriseId;
  final String boardId;

  const KanbanBoard({
    super.key,
    required this.enterpriseId,
    required this.boardId,
  });

  @override
  Widget build(BuildContext context) {
    final columnsCollection = FirebaseFirestore.instance
        .collection('enterprise')
        .doc(enterpriseId)
        .collection('kanban')
        .doc(boardId)
        .collection('columns');

    return StreamBuilder<QuerySnapshot>(
      stream: columnsCollection.orderBy('position').snapshots(),
      builder: (context, snapshot) {
        
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return BoardList(
                title: data['title'] ?? 'Sem título',
                columnId: doc.id,
                boardId: boardId,
                enterpriseId: enterpriseId,
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
