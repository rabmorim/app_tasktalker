import 'package:app_mensagem/pages/recursos/barra_superior.dart';
import 'package:app_mensagem/pages/recursos/drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserTaskList extends StatefulWidget {
  const UserTaskList({super.key});

  @override
  State<UserTaskList> createState() => _UserTaskListState();
}

class _UserTaskListState extends State<UserTaskList> {
  //Instãncia do usuario cadastrado (uid)
  final userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          const BarraSuperior(titulo: 'Minhas Tarefas', isCalendarPage: false),
      drawer: MenuDrawer(),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .where('assigned_to', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          //Verificação de erros
          if (snapshot.hasError) {
            return const Center(
              child: Text('Error ao carregar as tarefas'),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.white54,
              ),
            );
          }
          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Nenhuma Tarefa Existente'),
            );
          }
          return ListView(
              children: snapshot.data!.docs.map(
            (task) {
              Map<String, dynamic> data = task.data();
              return ListTile(
                title: Text(
                  data['title'] ?? 'Tarefa sem Titulo',
                  style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  data['description'] ?? 'Sem Descrição',
                  style: const TextStyle(
                      color: Colors.white54,
                  ),
                ),
              );
            },
          ).toList());
        },
      ),
    );
  }
}
