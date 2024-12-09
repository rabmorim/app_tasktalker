import 'package:cloud_firestore/cloud_firestore.dart';

class BoardItemModel {
  final String id; // Id da tarefa
  final String uid; // Uid de quem criou a tarefa
  final String receiverUid; // Uid de quem foi delegado a tarefa no Kanban
  final String title; // Título da tarefa
  final String message; // Mensagem/descrição da tarefa
  final Timestamp? timestamp; // Horário em que foi criada a tarefa
  final String boardId; // Id do quadro Kanban
  final String color; // Cor associada ao usuário

  BoardItemModel({
    required this.id,
    required this.uid,
    required this.receiverUid,
    required this.title,
    required this.message,
    this.timestamp,
    required this.boardId,
    required this.color,
  });

  /////////////////////////////
  /// Método para converter o documento do Firestore em um BoardItemModel
  factory BoardItemModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BoardItemModel(
      id: doc.id,
      uid: data['uid'] ?? '',
      receiverUid: data['receiverUid'] ?? '',
      title: data['title'] ?? 'Sem título',
      message: data['message'] ?? '',
      timestamp: data['timestamp'] as Timestamp?,
      boardId: data['boardId'] ?? '',
      color: data['color'] ?? '#FFFFFF',
    );
  }

  //////////////////////////////
  /// Método para converter um BoardItemModel em um Map (para Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'receiverUid': receiverUid,
      'title': title,
      'message': message,
      'timestamp': timestamp,
      'boardId': boardId,
      'color': color,
    };
  }
}

class KanbanBoardModel {
  final String id;
  final String name;

  KanbanBoardModel({
    required this.id,
    required this.name,
  });

  factory KanbanBoardModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return KanbanBoardModel(
      id: doc.id,
      name: data['name'] ?? 'Sem nome',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
    };
  }
}
