/*
  Página de Detalhes das Tarefas do Kanban com Edição
  Feito por: Rodrigo Abreu Amorim
  Última modificação: 23/12/2024
*/
import 'package:app_mensagem/pages/kanban_board_page.dart';
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
  bool showTextField = false;
  final microTasksController = TextEditingController();
  List<String> microTasks = [];

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
    _fetchMicroTasks();
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

//////////////////////////////////////
  /// Método para procurar as micro tarefas
  Future<void> _fetchMicroTasks() async {
    try {
      final CollectionReference microTasksRef = FirebaseFirestore.instance
          .collection('enterprise')
          .doc(widget.enterpriseId)
          .collection('kanban')
          .doc(widget.boardId)
          .collection('columns')
          .doc(widget.columnId)
          .collection('tasks')
          .doc(widget.taskId)
          .collection('microTasks');

      final QuerySnapshot snapshot = await microTasksRef.get();
      setState(() {
        microTasks =
            snapshot.docs.map((doc) => doc['title'] as String).toList();
      });
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao buscar micro tarefas: $e'),
        ),
      );
    }
  }

  //////////////////////////////
  /// Método para salvar os detalhes editados
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

  //////////////////////////////
  /// Método para adicionar uma nova microTarefa
  Future<void> addMicroTask(String taskTitle) async {
    try {
      final CollectionReference microTasksRef = FirebaseFirestore.instance
          .collection('enterprise')
          .doc(widget.enterpriseId)
          .collection('kanban')
          .doc(widget.boardId)
          .collection('columns')
          .doc(widget.columnId)
          .collection('tasks')
          .doc(widget.taskId)
          .collection('microTasks');

      await microTasksRef.add({'title': taskTitle});
      setState(() {
        microTasks.add(taskTitle);
      });
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao adicionar micro tarefa: $e'),
        ),
      );
    }
  }

  //////////////////////////////
  /// Métedo para deletar uma micro tarefa existente
  Future<void> deleteMicroTask(int index) async {
    try {
      final CollectionReference microTasksRef = FirebaseFirestore.instance
          .collection('enterprise')
          .doc(widget.enterpriseId)
          .collection('kanban')
          .doc(widget.boardId)
          .collection('columns')
          .doc(widget.columnId)
          .collection('tasks')
          .doc(widget.taskId)
          .collection('microTasks');

      final QuerySnapshot snapshot = await microTasksRef.get();
      await snapshot.docs[index].reference.delete();
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao deletar micro tarefa: $e')),
      );
    }
  }

/////////////////////////////////
  /// Método para abrir o modal de criação de novas micro tarefas
  void _showAddTaskModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Adicionar Micro Tarefa'),
          content: TextField(
            controller: microTasksController,
            decoration: const InputDecoration(
              hintText: 'Digite sua micro tarefa',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            TextButton(
              onPressed: () {
                final newTask = microTasksController.text.trim();
                if (newTask.isNotEmpty) {
                  addMicroTask(newTask);
                  microTasksController.clear();
                  Navigator.of(context).pop();
                }
              },
              child: const Text(
                'Adicionar',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        );
      },
    );
  }

  ////////////////////////////////
  /// Método para abrir o modal para deletar as tarefas existentes
  void _showDeleteTask(String taskId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Remover tarefa'),
          actions: [
            const Text('Deseja realmente remover essa tarefa?'),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    deleteTask(taskId);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            KanbanBoardPage(enterpriseId: widget.enterpriseId),
                      ),
                    );
                  },
                  child: const Text(
                    'Remover',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  //////////////////////////////
  /// Método para deletar uma tarefa
  Future<void> deleteTask(String taskId) async {
    try {
      FirebaseFirestore.instance
          .collection('enterprise')
          .doc(widget.enterpriseId)
          .collection('kanban')
          .doc(widget.boardId)
          .collection('columns')
          .doc(widget.columnId)
          .collection('tasks')
          .doc(widget.taskId)
          .delete();
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao Excluir a Tarefa: $e'),
        ),
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
                    const SizedBox(height: 20),
                    //Botão para excluir
                    SizedBox(
                      width: 250,
                      child: MyButton(
                          onTap: () {
                            _showDeleteTask(widget.taskId);
                          },
                          text: 'Excluir Tarefa'),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 200,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Divider(height: 3),
                          const SizedBox(height: 5),
                           const Text(
                            'Micro Tarefas',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                              wordSpacing: 6
                            ),
                          ),
                          //Exibição das micro tarefas
                          Expanded(
                            child: ListView.builder(
                              itemCount: microTasks.length,
                              itemBuilder: (context, index) {
                                final task = microTasks[index];
                                return Container(
                                  height: 60,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 5),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        task,
                                        style: const TextStyle(
                                            fontSize: 16, color: Colors.black),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            deleteMicroTask(index);
                                            microTasks.removeAt(index);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
          child: const Icon(
            Icons.add,
            color: Colors.black,
          ),
          onPressed: () => _showAddTaskModal()),
    );
  }
}
