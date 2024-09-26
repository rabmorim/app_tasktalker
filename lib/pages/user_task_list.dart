import 'package:app_mensagem/pages/calendar_page.dart';
import 'package:app_mensagem/pages/home_page.dart';
import 'package:app_mensagem/pages/recursos/list_users.dart';
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
            StreamBuilder(
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
                      //Tratando como String a data, por estar armazenado desta forma no Firestore
                      final String? startTime = data['start_time'];
                      final String? endTime = data['end_time'];

                      // Formatação das horas
                      String startFormatted =
                          startTime != null ? formatTime(startTime) : '';
                      String endFormatted =
                          endTime != null ? formatTime(endTime) : '';

                      //Formação de Datas
                      String dateFormatInitial = startTime != null ? formatDate(startTime): '';

                      String dateFormatFinal = startTime != null ? formatDate(startTime): '';

                      return Column(
                        children: [
                          const SizedBox(
                            height: 5,
                          ),
                          Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color:
                                    const Color.fromARGB(255, 116, 111, 111)),
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
                                    style:
                                        const TextStyle(color: Colors.white54),
                                  ),
                                  Text(
                                    "$startFormatted - $endFormatted",
                                    style:
                                        const TextStyle(color: Colors.white54),
                                  ),
                                  Text(
                                    "Inicio: $dateFormatInitial - Fim: $dateFormatFinal",
                                    style: const TextStyle(
                                      color: Colors.white54
                                    ),
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
            ),
            //segunda aba com a lista de páginas
            _pages[1],
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 0,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white,
          iconSize: 24,
          onTap: (value) {
          if(value == 0){
              Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HomePage(),
              ),
            );
          }else{
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
                icon: FaIcon(FontAwesomeIcons.calendar), label: 'Calendário')
          ],
        ),
      ),
    );
  }

  //Formatar a hora para impressão no listview
  String formatTime(String dateTimeString) {
    DateTime dateTime = DateTime.parse(dateTimeString).toLocal();
    return DateFormat('HH:mm')
        .format(dateTime); // Formato de 24 horas (ex: 14:30)
  }
  String formatDate(String dateString){
    DateTime dateFormat = DateTime.parse(dateString).toLocal();
    return DateFormat('dd/MM/yyyy').format(dateFormat);
  }
}
