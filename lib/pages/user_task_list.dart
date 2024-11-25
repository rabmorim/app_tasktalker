/*
  Página das tarefas do firestore
  Feito por: Rodrigo abreu Amorim
  Ultima modificação: 25/11/2024
 */

import 'package:app_mensagem/pages/calendar_page.dart';
import 'package:app_mensagem/pages/home_page.dart';
import 'package:app_mensagem/pages/user_task_list_google.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class UserTaskList extends StatefulWidget {
  const UserTaskList({super.key});

  @override
  State<UserTaskList> createState() => _UserTaskListState();
}

class _UserTaskListState extends State<UserTaskList> {
  //Instãncia do usuario cadastrado (uid)
  final userId = FirebaseAuth.instance.currentUser?.uid;

  late List<Widget>
      _pages; // lista de páginas a serem renderizadas no TabBarView
  @override
  void initState() {
    super.initState();
    _pages = [
      const UserTaskList(),
      const UserTaskListGoogle(),
    ];
  }

  //////////////////////
  ///Método para buscar o código da empresa do usuário autenticado.
  Future<String?> getCompanyCode() async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      return userDoc['code'];
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _pages.length,
      child: Scaffold(
        appBar: AppBar(
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(-5),
            child: TabBar(
              tabAlignment: TabAlignment.fill,
              indicatorColor: Colors.white,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              indicatorSize: TabBarIndicatorSize
                  .label, // Deixa o indicador com o tamanho do label
              labelPadding: EdgeInsets.symmetric(horizontal: 16.0),
              tabs: [
                Tab(text: "Tarefas"),
                Tab(text: "Tarefas Google Calendar"),
              ],
              labelStyle: TextStyle(
                fontFamily: 'Nougat',
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            FutureBuilder<String?>(
              future: getCompanyCode(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white54,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(
                    child: Text('Erro ao carregar a empresa do usuário'),
                  );
                }

                final enterpriseCode = snapshot.data;

                return StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('enterprise')
                      .doc(enterpriseCode)
                      .collection('tasks')
                      .where('assigned_to', isEqualTo: userId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Erro ao carregar as tarefas'),
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
                          final String? startTime = data['start_time'];
                          final String? endTime = data['end_time'];

                          String startFormatted =
                              startTime != null ? formatTime(startTime) : '';
                          String endFormatted =
                              endTime != null ? formatTime(endTime) : '';
                          String dateFormatInitial =
                              startTime != null ? formatDate(startTime) : '';
                          String dateFormatFinal =
                              endTime != null ? formatDate(endTime) : '';

                          return Column(
                            children: [
                              const SizedBox(height: 5),
                              Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: const Color.fromARGB(
                                        255, 116, 111, 111)),
                                child: ListTile(
                                  title: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        data['title'] ?? 'Tarefa sem Título',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        data['description'] ?? 'Sem Descrição',
                                        style: const TextStyle(
                                            color: Colors.white54),
                                      ),
                                      Text(
                                        "$startFormatted - $endFormatted",
                                        style: const TextStyle(
                                            color: Colors.white54),
                                      ),
                                      Text(
                                        "Inicio: $dateFormatInitial - Fim: $dateFormatFinal",
                                        style: const TextStyle(
                                            color: Colors.white54),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ).toList(),
                    );
                  },
                );
              },
            ),
            _pages[1],
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 0,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white,
          iconSize: 24,
          onTap: (value) {
            if (value == 0) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomePage(),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CalendarPage(),
                ),
              );
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.house),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.calendar),
              label: 'Calendário',
            )
          ],
        ),
      ),
    );
  }
  /////////////////////
  ///Métodos de formatação de data e tempo
  String formatTime(String dateTimeString) {
    DateTime dateTime = DateTime.parse(dateTimeString).toLocal();
    return DateFormat('HH:mm').format(dateTime);
  }

  String formatDate(String dateString) {
    DateTime dateFormat = DateTime.parse(dateString).toLocal();
    return DateFormat('dd/MM/yyyy').format(dateFormat);
  }
}
