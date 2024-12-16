/*
  Página de Detalhes das Tarefas do Kanban com Edição
  Feito por: Rodrigo Abreu Amorim
  Última modificação: 16/12/2024
*/
import 'package:app_mensagem/pages/recursos/barra_superior.dart';
import 'package:app_mensagem/pages/recursos/button.dart';
import 'package:app_mensagem/pages/recursos/get_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DetalhesTarefaPage extends StatefulWidget {
  final String taskId;
  final String title;
  final String message;
  final String color;
  final String receiverUid;
  final String priority;
  final String enterpriseId;
  final List<String> labels;
  final String columnId;
  final String boardId;

  const DetalhesTarefaPage(
      {super.key,
      required this.taskId,
      required this.title,
      required this.message,
      required this.color,
      required this.receiverUid,
      required this.priority,
      required this.labels,
      required this.enterpriseId,
      required this.boardId,
      required this.columnId});

  @override
  State<DetalhesTarefaPage> createState() => _DetalhesTarefaPageState();
}

class _DetalhesTarefaPageState extends State<DetalhesTarefaPage> {
  final GetUser getUser = GetUser();

  bool isEditing = false;

  late TextEditingController titleController;
  late TextEditingController messageController;
  String selectedPriority = '';
  List<String> editableLabels = [];

  @override
  void initState() {
    super.initState();
    _doProcess();
  }

  void _doProcess() {
    titleController = TextEditingController(text: widget.title);
    messageController = TextEditingController(text: widget.message);
    selectedPriority = widget.priority;
    editableLabels = List.from(widget.labels);
  }

  @override
  void dispose() {
    titleController.dispose();
    messageController.dispose();
    super.dispose();
  }

  void toggleEditingMode() {
    setState(() {
      isEditing = !isEditing;
    });
  }

  void saveTaskDetails() async {
    try {
      // Referência ao documento da tarefa no Firestore
      final DocumentReference taskRef = FirebaseFirestore.instance
          .collection('enterprise')
          .doc(widget.enterpriseId)
          .collection('kanban')
          .doc(widget.boardId)
          .collection('columns')
          .doc(widget.columnId)
          .collection('tasks')
          .doc(widget.taskId);

      // Atualização dos campos no Firestore
      await taskRef.update({
        'title': titleController.text,
        'message': messageController.text,
        'priority': selectedPriority,
        'labels': editableLabels,
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alterações salvas com sucesso!')),
      );
      // Após salvar, desabilitar o modo de edição
      toggleEditingMode();
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar alterações: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BarraSuperior(titulo: 'Detalhes', isCalendarPage: false),
      body: FutureBuilder<String?>(
        future: getUser.getUserName(widget.receiverUid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.white54,
              ),
            );
          } else if (snapshot.hasError) {
            return const Center(
              child: Text('Erro ao carregar nome do usuário'),
            );
          }

          final String userName = snapshot.data ?? 'Usuário desconhecido';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Campo Título
                    isEditing
                        ? TextField(
                            controller: titleController,
                            decoration: const InputDecoration(
                              labelText: 'Título',
                              border: OutlineInputBorder(),
                            ),
                          )
                        : Text(
                            "Título: ${titleController.text}",
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),

                    const SizedBox(height: 8),

                    // Campo Descrição
                    isEditing
                        ? TextField(
                            controller: messageController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Descrição',
                              border: OutlineInputBorder(),
                            ),
                          )
                        : Text(
                            "Descrição: ${messageController.text}",
                            style: const TextStyle(fontSize: 16),
                          ),

                    const SizedBox(height: 16),

                    // Campo Delegado para
                    Text(
                      "Delegado para: $userName",
                      style: const TextStyle(fontSize: 16),
                    ),

                    const SizedBox(height: 16),

                    // Campo Prioridade
                    if (isEditing)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Prioridade:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          RadioListTile<String>(
                            title: const Text('Alta'),
                            activeColor: Colors.white,
                            value: 'Alta',
                            groupValue: selectedPriority,
                            onChanged: (value) {
                              setState(() {
                                selectedPriority = value!;
                              });
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('Média'),
                            activeColor: Colors.white,
                            value: 'Média',
                            groupValue: selectedPriority,
                            onChanged: (value) {
                              setState(() {
                                selectedPriority = value!;
                              });
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('Baixa'),
                            activeColor: Colors.white,
                            value: 'Baixa',
                            groupValue: selectedPriority,
                            onChanged: (value) {
                              setState(() {
                                selectedPriority = value!;
                              });
                            },
                          ),
                        ],
                      )
                    else
                      Text(
                        "Prioridade: ${selectedPriority.toUpperCase()}",
                        style: const TextStyle(fontSize: 16),
                      ),

                    const SizedBox(height: 16),

                    // Labels
                    if (isEditing)
                      Wrap(
                        spacing: 8.0,
                        children: editableLabels
                            .map((label) => Chip(
                                  label: Text(label),
                                  deleteIcon: const Icon(Icons.close),
                                  onDeleted: () {
                                    setState(() {
                                      editableLabels.remove(label);
                                    });
                                  },
                                ))
                            .toList(),
                      )
                    else
                      Wrap(
                        spacing: 10.0,
                        children: editableLabels
                            .map((label) => Chip(
                                  label: Text(label),
                                  backgroundColor: Colors.grey[400],
                                ))
                            .toList(),
                      ),

                    const SizedBox(height: 32),

                    // Botão para salvar ou editar
                    SizedBox(
                      width: 150,
                      child: MyButton(
                        onTap: isEditing ? saveTaskDetails : toggleEditingMode,
                        text: isEditing ? 'Salvar' : 'Editar tarefa',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
