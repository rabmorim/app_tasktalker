/*
  Página de Construção do Kanban inteiro
  Feito por: Rodrigo abreu Amorim
  Ultima modificação: 17/12/2024
 */
import 'package:app_mensagem/model/kanban.dart';
import 'package:app_mensagem/pages/kanban_page.dart';
import 'package:app_mensagem/pages/recursos/barra_superior.dart';
import 'package:app_mensagem/pages/recursos/list_users_dropdown.dart';
import 'package:app_mensagem/pages/recursos/task_color_manager.dart';
import 'package:app_mensagem/pages/recursos/text_field.dart';
import 'package:app_mensagem/services/kanban_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:provider/provider.dart';

class KanbanBoardPage extends StatefulWidget {
  final String enterpriseId;

  const KanbanBoardPage({super.key, required this.enterpriseId});

  @override
  State<KanbanBoardPage> createState() => _KanbanBoardPageState();
}

class _KanbanBoardPageState extends State<KanbanBoardPage> {
  String? selectedBoardId;
  String? selectedBoardName;
  String? selectedUser;
  bool isEditingColumns = false;

  @override
  Widget build(BuildContext context) {
    final kanbanProvider = Provider.of<KanbanProvider>(context);
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
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        distance: 80,
        children: [
          //Botão para adicionar nova tarefa
          FloatingActionButton.small(
            backgroundColor: Colors.black,
            heroTag: null,
            child: const Icon(
              Icons.add,
              color: Colors.white,
            ),
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
          ),

          //Botão de adicionar nova coluna
          FloatingActionButton.small(
            backgroundColor: Colors.black,
            heroTag: null,
            child: const Icon(
              Icons.collections_bookmark_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              if (selectedBoardId != null) {
                _showCreateColumns(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Selecione um Quadro Kanban primeiro'),
                  ),
                );
              }
            },
          ),

          //Botão de edição de colunas
          FloatingActionButton.small(
            backgroundColor: Colors.black,
            heroTag: null,
            child: const Icon(
              Icons.edit,
              color: Colors.white,
            ),
            onPressed: () {
              if (selectedBoardId != null) {
                kanbanProvider.toggleEditingColumns();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Selecione um Quadro Kanban primeiro'),
                  ),
                );
              }
            },
          ),
        ],
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
    final labelController = TextEditingController(); // Controller para labels
    bool showTextField = false;
    List<String> labels = []; // Lista de labels

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
                    const SizedBox(height: 10),
                    // Botão e Campo de Adicionar Labels
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.white),
                          onPressed: () {
                            setModalState(() {
                              showTextField =
                                  !showTextField; // Alterna a visibilidade
                            });
                          },
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: showTextField ? 200 : 0,
                          height: 40,
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: showTextField
                              ? Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: TextField(
                                        controller: labelController,
                                        style: const TextStyle(
                                            color: Colors.white),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 2),
                                          hintText: 'Nova label',
                                          hintStyle:
                                              TextStyle(color: Colors.white54),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: IconButton(
                                        icon: const Icon(Icons.send,
                                            size: 15, color: Colors.white),
                                        onPressed: () {
                                          final newLabel =
                                              labelController.text.trim();
                                          if (newLabel.isNotEmpty) {
                                            setModalState(() {
                                              labels.add(newLabel);
                                              labelController.clear();
                                              showTextField = false;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    // Exibição das Labels Adicionadas
                    Wrap(
                      spacing: 8.0,
                      children: labels
                          .map(
                            (label) => Chip(
                              label: Text(label),
                              deleteIcon: const Icon(Icons.close),
                              onDeleted: () {
                                setModalState(() {
                                  labels.remove(label);
                                });
                              },
                            ),
                          )
                          .toList(),
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
                          labels: labels,
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
      required String priority,
      required List<String> labels}) async {
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
      'priority': priority,
      'labels': labels
    });
  }

//////////////////////////////
  /// Método para criar uma nova coluna
  Future<void> createColumn(
      {required String enterpriseId,
      required String boardId,
      required String columnName,
      required num position}) async {
    // Referencia da coluna no banco de dados
    final columnsCollection = FirebaseFirestore.instance
        .collection('enterprise')
        .doc(enterpriseId)
        .collection('kanban')
        .doc(boardId)
        .collection('columns');

    //Adiciona a nova coluna na coleção columns do quadro kanban
    await Future.wait([
      columnsCollection.add({'title': columnName, 'position': position})
    ]);
  }

/////////////////////////
  /// Método para criar o modal para criar a nova coluna
  Future<void> _showCreateColumns(BuildContext context) async {
    final controller = TextEditingController();
    final columnsCollection = FirebaseFirestore.instance
        .collection('enterprise')
        .doc(widget.enterpriseId)
        .collection('kanban')
        .doc(selectedBoardId)
        .collection('columns');

    // 1. Buscar as posições já existentes
    final existingPositions = await _fetchExistingPositions(columnsCollection);

    // 2. Criar uma lista de posições disponíveis (1 a 5)
    final availablePositions = List.generate(5, (index) => index + 1)
        .where((pos) => !existingPositions.contains(pos))
        .toList();

    num? selectedPosition; // Variável para armazenar a posição selecionada

    // 3. Exibir o modal
    showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Coluna'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Nome da Coluna'),
            ),
            const SizedBox(height: 10),
            const Text('Escolha a posição:'),
            Wrap(
              spacing: 8,
              children: availablePositions.map((pos) {
                return ChoiceChip(
                  label: Text('Posição $pos'),
                  selected: selectedPosition == pos,
                  onSelected: (selected) {
                    selectedPosition = pos; // Define a posição escolhida
                    (context as Element).markNeedsBuild(); // Força rebuild
                  },
                );
              }).toList(),
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
              final name = controller.text.trim();
              if (name.isNotEmpty && selectedPosition != null) {
                await createColumn(
                  enterpriseId: widget.enterpriseId,
                  boardId: selectedBoardId!,
                  columnName: name,
                  position: selectedPosition!,
                );
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop(); // Fecha o modal
              }
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

  ///////////////////////
  /// Método para buscar as posições existentes no Firestore
  Future<List<num>> _fetchExistingPositions(
      CollectionReference columnsCollection) async {
    final querySnapshot = await columnsCollection.get();
    final positions = querySnapshot.docs
        .map((doc) => doc['position'] as num) // Pega o campo 'position'
        .toList();
    return positions;
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
