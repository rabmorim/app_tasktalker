import 'package:app_mensagem/model/kanban.dart';
import 'package:app_mensagem/pages/kanban_page.dart';
import 'package:app_mensagem/pages/recursos/barra_superior.dart';
import 'package:app_mensagem/pages/recursos/list_users_dropdown.dart';
import 'package:app_mensagem/pages/recursos/task_color_manager.dart';
import 'package:app_mensagem/pages/recursos/text_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class KanbanBoardPage extends StatefulWidget {
  final String enterpriseId;

  const KanbanBoardPage({super.key, required this.enterpriseId});

  @override
  State<KanbanBoardPage> createState() => _KanbanBoardPageState();
}

class _KanbanBoardPageState extends State<KanbanBoardPage> {
  String? selectedBoardId;
  String? selectedBoardName;
  // Variável para armazenar o usuário selecionado (a quem a tarefa será delegada)
  String? selectedUser;

  @override
  Widget build(BuildContext context) {
    final kanbanCollection = FirebaseFirestore.instance
        .collection('enterprise')
        .doc(widget.enterpriseId)
        .collection('kanban');

    return Scaffold(
      appBar: const BarraSuperior(
          titulo: 'Quadros Kanban', isCalendarPage: false, isChatPage: true),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dropdown para selecionar o quadro Kanban
          Center(
            heightFactor: 1,
            child: StreamBuilder<QuerySnapshot>(
              stream: kanbanCollection.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                final boards = docs
                    .map((doc) => KanbanBoardModel.fromDocument(doc))
                    .toList();

                return DropdownButton<String>(
                  hint: const Text('Selecione um quadro Kanban'),
                  value: selectedBoardId,
                  onChanged: (value) {
                    setState(() {
                      selectedBoardId = value;
                      selectedBoardName =
                          boards.firstWhere((board) => board.id == value).name;
                    });
                  },
                  items: boards
                      .map((board) => DropdownMenuItem<String>(
                            value: board.id,
                            child: Text(board.name),
                          ))
                      .toList(),
                );
              },
            ),
          ),
          // Botão para criar novo quadro Kanban
          Center(
            child: Padding(
              padding: const EdgeInsets.all(0),
              child: ElevatedButton.icon(
                onPressed: () =>
                    _showCreateBoardDialog(context, kanbanCollection),
                icon: const Icon(
                  Icons.add,
                  color: Colors.white54,
                ),
                label: const Text(
                  'Novo Quadro Kanban',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          // Exibe o quadro Kanban selecionado
          Expanded(
            child: selectedBoardId == null
                ? const Center(child: Text('Nenhum quadro Kanban selecionado.'))
                : KanbanBoard(
                    enterpriseId: widget.enterpriseId,
                    boardId: selectedBoardId!,
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () {
          if (selectedBoardId != null) {
            _showCreateTaskDialog(
                context, widget.enterpriseId, selectedBoardId!);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Selecione um quadro Kanban primeiro.')),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

/////////////////////////////////////
  /// Método para abrir o modal de criação de tarefas
  Future<void> _showCreateTaskDialog(
    BuildContext context,
    String enterpriseId,
    String boardId,
  ) async {
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    // Busca as colunas do quadro atual para o dropdown
    final columnsCollection = FirebaseFirestore.instance
        .collection('enterprise')
        .doc(enterpriseId)
        .collection('kanban')
        .doc(boardId)
        .collection('columns');

    showDialog(
      context: context,
      builder: (context) {
        String? localSelectedColumnId;
        String? selectedPriority = 'Média'; // Valor padrão

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              padding: const EdgeInsets.only(top: 150),
              child: AlertDialog(
                title: const Text('Nova Tarefa'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    UserListDropdown(
                      onUserSelected: (userId) {
                        setState(() {
                          selectedUser = userId;
                        });
                      },
                    ),
                    const SizedBox(height: 5),
                    MyTextField(
                      controller: titleController,
                      labelText: 'Título',
                      obscureText: false,
                    ),
                    const SizedBox(height: 10),
                    MyTextField(
                      controller: messageController,
                      labelText: 'Mensagem',
                      obscureText: false,
                    ),
                    const SizedBox(height: 10),
                    StreamBuilder<QuerySnapshot>(
                      stream: columnsCollection.orderBy('position').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }

                        final docs = snapshot.data!.docs;
                        return DropdownButton<String>(
                          hint: const Text('Selecione a Coluna'),
                          value: localSelectedColumnId,
                          onChanged: (value) {
                            setModalState(() {
                              localSelectedColumnId = value;
                            });
                          },
                          items: docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return DropdownMenuItem<String>(
                              value: doc.id,
                              child: Text(data['title'] ?? 'Sem título'),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    // Prioridade com Radio Buttons
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
                            setModalState(() {
                              selectedPriority = value;
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Média'),
                          activeColor: Colors.white,
                          value: 'Média',
                          groupValue: selectedPriority,
                          onChanged: (value) {
                            setModalState(() {
                              selectedPriority = value;
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Baixa'),
                          activeColor: Colors.white,
                          value: 'Baixa',
                          groupValue: selectedPriority,
                          onChanged: (value) {
                            setModalState(() {
                              selectedPriority = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final title = titleController.text.trim();
                      final message = messageController.text.trim();

                      if (title.isNotEmpty &&
                          localSelectedColumnId != null &&
                          selectedPriority != null) {
                        await _createTask(
                          enterpriseId: enterpriseId,
                          boardId: boardId,
                          columnId: localSelectedColumnId!,
                          title: title,
                          message: message,
                          priority: selectedPriority!,
                        );
                        // ignore: use_build_context_synchronously
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text(
                      'Adicionar',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /////////////////////////////////
  /// Método para Criar uma tarefa
  Future<void> _createTask(
      {required String enterpriseId,
      required String boardId,
      required String columnId,
      required String title,
      required String message,
      required String priority}) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    String uid = auth.currentUser!.uid;
    TaskColorManager colorManager = TaskColorManager();

    // Aguardando o valor da cor do usuário
    Color? userColor = await colorManager.getUserColor(selectedUser!);

    // Converter a cor para uma string hexadecimal
    String colorHex =
        '#${userColor!.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';

    final tasksCollection = FirebaseFirestore.instance
        .collection('enterprise')
        .doc(enterpriseId)
        .collection('kanban')
        .doc(boardId)
        .collection('columns')
        .doc(columnId)
        .collection('tasks');

    await tasksCollection.add({
      'title': title,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'uid': uid,
      'receiverUid': selectedUser,
      'color': colorHex,
      'priority': priority
    });
  }

//////////////////////////////////
  /// Método para criar o Novo Quadro Kanban
  Future<void> createKanbanBoard({
    required String enterpriseId,
    required String boardName,
  }) async {
    final kanbanCollection = FirebaseFirestore.instance
        .collection('enterprise')
        .doc(enterpriseId)
        .collection('kanban');

    // Adiciona o novo quadro
    final newBoardRef = await kanbanCollection.add({'name': boardName});

    // Referência para a subcoleção de colunas do novo quadro
    final columnsCollection = newBoardRef.collection('columns');

    // Adiciona as colunas padrão
    await Future.wait([
      columnsCollection.add({'title': 'To Do', 'position': 1}),
      columnsCollection.add({'title': 'In Progress', 'position': 2}),
      columnsCollection.add({'title': 'Done', 'position': 3}),
    ]);
  }

//////////////////////////////////////
  /// Método para abrir o Modal de criação de Quadros Kanban
  Future<void> _showCreateBoardDialog(
      BuildContext context, CollectionReference kanbanCollection) async {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo Quadro Kanban'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nome do Quadro'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                createKanbanBoard(
                    enterpriseId: widget.enterpriseId, boardName: name);
              }
              // ignore: use_build_context_synchronously
              Navigator.of(context).pop();
            },
            child: const Text(
              'Criar',
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }
}
