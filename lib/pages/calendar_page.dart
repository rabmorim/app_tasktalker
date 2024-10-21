import 'package:app_mensagem/pages/recursos/barra_superior.dart';
import 'package:app_mensagem/pages/recursos/drawer.dart';
import 'package:app_mensagem/pages/recursos/get_user.dart';
import 'package:app_mensagem/pages/recursos/modal_form.dart';
import 'package:app_mensagem/pages/recursos/task_color_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

DateTime? _selectedDay;
DateTime _focusedDay = DateTime.now();

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  TaskColorManager colorManager = TaskColorManager();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  Map<DateTime, List<dynamic>> eventsMap = {}; // Armazena eventos por data
  List<dynamic> _selectedEvents = []; // Eventos da data selecionada
  GetUser getUserName = GetUser();

  @override
  void initState() {
    super.initState();
    loadFirestoreTasks();
  }

  Future<void> loadFirestoreTasks() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('tasks').get();
    List<Map<String, dynamic>> tasks =
        snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

    // Carregar cores dos usuários
    for (var task in tasks) {
      String userId = task['assigned_to'];
      // Pega o documento do usuário para obter a cor
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        // Certifique-se que a cor existe no documento do usuário
        String? userColorHex = userDoc['color'];

        if (userColorHex != null) {
          // Converte a string hexadecimal em uma cor
          Color userColor = Color(
              int.parse(userColorHex.substring(1, 7), radix: 16) + 0xFF000000);

          // Adiciona essa cor no próprio `task` temporariamente para uso na UI
          task['userColor'] = userColor;
        }
      }
    }

    setState(
      () {
        eventsMap = groupEventsByDate(tasks);
        if (_selectedDay != null) {
          _selectedEvents = eventsMap[_selectedDay!] ?? [];
        }
      },
    );
  }

//Normalizar as datas
  DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  //Formatar a hora para impressão no listview
  String formatTime(String dateTimeString) {
    DateTime dateTime = DateTime.parse(dateTimeString).toLocal();
    return DateFormat('HH:mm')
        .format(dateTime); // Formato de 24 horas (ex: 14:30)
  }

//Agrupando eventos por data
  Map<DateTime, List<dynamic>> groupEventsByDate(
      List<Map<String, dynamic>> tasks) {
    Map<DateTime, List<dynamic>> groupedEvents = {};

    for (var task in tasks) {
      // Verificar se as datas existem antes de tentar parseá-las
      String? startTimeString = task['start_time'];
      String? endTimeString = task['end_time'];

      if (startTimeString != null && endTimeString != null) {
        DateTime startDate = DateTime.parse(startTimeString).toLocal();
        DateTime endDate = DateTime.parse(endTimeString).toLocal();
        DateTime initialNormalizedDate = normalizeDate(startDate);
        DateTime finalNormalizedDate = normalizeDate(endDate);

        // Adicionar evento ao mapa sem duplicação
        groupedEvents.putIfAbsent(initialNormalizedDate, () => []).add(task);
        if (initialNormalizedDate != finalNormalizedDate) {
          groupedEvents.putIfAbsent(finalNormalizedDate, () => []).add(task);
        }
      } else {}
    }

    return groupedEvents;
  }

  void _handleFormatChange(CalendarFormat format) {
    setState(() {
      _calendarFormat = format;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BarraSuperior(
        titulo: 'Calendário',
        isCalendarPage: true,
        onFormatChanged: _handleFormatChange,
      ),
      drawer: const MenuDrawer(),
      body: Column(
        children: [
          TableCalendar(
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = normalizeDate(selectedDay);
                _focusedDay = focusedDay;
                _selectedEvents = eventsMap[selectedDay] ?? [];
                loadFirestoreTasks();
              });
            },
            focusedDay: _focusedDay,
            firstDay: DateTime.utc(2010, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            calendarFormat: _calendarFormat,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            eventLoader: (day) {
              DateTime dateKey =
                  DateTime(day.year, day.month, day.day); // Normaliza o dia
              return eventsMap[dateKey] ?? [];
            },
            calendarStyle: const CalendarStyle(
              selectedDecoration:
                  BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
              todayDecoration:
                  BoxDecoration(color: Colors.white54, shape: BoxShape.circle),
            ),
            calendarBuilders: CalendarBuilders(dowBuilder: (context, day) {
              String text;
              switch (day.weekday) {
                case DateTime.sunday:
                  text = 'dom';
                  break;
                case DateTime.monday:
                  text = 'seg';
                  break;
                case DateTime.tuesday:
                  text = 'ter';
                  break;
                case DateTime.wednesday:
                  text = 'qua';
                  break;
                case DateTime.thursday:
                  text = 'qui';
                  break;
                case DateTime.friday:
                  text = 'sex';
                  break;
                case DateTime.saturday:
                  text = 'sab';
                  break;
                default:
                  text = 'Error';
              }
              _selectedEvents.sort((a, b) {
                // Converta as strings armazenadas no Firestore em objetos DateTime
                DateTime startA = DateTime.parse(a['start_time']);
                DateTime startB = DateTime.parse(b['start_time']);

                return startA.compareTo(startB);
              });

              // Listas para separar tarefas passadas e futuras
              List<Map<String, dynamic>> passedTasks = [];
              List<Map<String, dynamic>> upcomingTasks = [];
              DateTime now = DateTime.now().toLocal();

              for (var event in _selectedEvents) {
                // Converta as strings para DateTime antes de comparar
                // DateTime startTime = DateTime.parse(event['start_time']);
                DateTime endTime = DateTime.parse(event['end_time']);

                // Verifica se a tarefa já terminou
                if (endTime.isBefore(now)) {
                  passedTasks.add(event);
                } else {
                  upcomingTasks.add(event);
                }
              }

              // Combina as listas: tarefas futuras primeiro, seguidas das passadas
              _selectedEvents = [...upcomingTasks, ...passedTasks];
              return Center(child: Text(text));
            },
                // Local onde exibe a bolinha de cor no calendário
                markerBuilder: (context, day, events) {
              if (events.isNotEmpty) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: events.map<Widget>((event) {
                    var userId = (event as Map<String, dynamic>)['assigned_to'];
                    if (userId != null) {
                      return FutureBuilder<Color?>(
                        future: colorManager.getUserColor(userId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.done &&
                              snapshot.hasData) {
                            Color? userColor = snapshot.data;
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal:
                                      0.5), // Espaçamento entre as bolinhas
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: userColor ?? Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            );
                          } else {
                            return Container(); // Placeholder enquanto carrega
                          }
                        },
                      );
                    } else {
                      return Container(); // Placeholder se o userId for nulo
                    }
                  }).toList(),
                );
              }

              // Retorna um valor padrão se não houver eventos
              return Container();
            }),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: _selectedEvents.isEmpty
                ? const Center(
                    child: Text('Nenhum evento'),
                  )
                : ListView.builder(
                    itemCount: _selectedEvents.length,
                    itemBuilder: (context, index) {
                      final event = _selectedEvents[index];
                      var userId = event['assigned_to'];
                      final startTime = event['start_time'];
                      final endTime = event['end_time'];

                      // Formatação das horas (apenas se houver 'dateTime' nos eventos)
                      String startFormatted =
                          startTime != null ? formatTime(startTime) : '';
                      String endFormatted =
                          endTime != null ? formatTime(endTime) : '';

                      // FutureBuilder para carregar a cor e o nome do usuário
                      return FutureBuilder<Color?>(
                        future: colorManager.getUserColor(userId),
                        builder: (context, snapshotColor) {
                          if (snapshotColor.hasError) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: Colors
                                    .red, // Exibe uma cor diferente em caso de erro
                              ),
                              child: const ListTile(
                                title: Text('Erro ao carregar cor',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            );
                          }

                          Color? userColor = snapshotColor.data ?? Colors.grey;
                          // Verificar se o evento já terminou
                          DateTime now = DateTime.now();
                          DateTime endTime = DateTime.parse(event['end_time']);
                          bool isExpired = endTime.isBefore(now);

                          // Definir cor de fundo com base na expiração
                          Color backgroundColor =
                              isExpired ? Colors.white.withOpacity(0.8) : userColor;

                          // FutureBuilder para carregar o nome do usuário
                          return FutureBuilder<String?>(
                            future: getUserName.getUserName(
                                userId), // Aqui usamos FutureBuilder para o nome
                            builder: (context, snapshotName) {
                              if (snapshotName.connectionState ==
                                  ConnectionState.waiting) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    color: backgroundColor,
                                  ),
                                  child: const ListTile(
                                    title: Text('Carregando...',
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                );
                              }

                              if (snapshotName.hasError ||
                                  !snapshotName.hasData) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    color: userColor,
                                  ),
                                  child: const ListTile(
                                    title: Text('Erro ao carregar nome',
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                );
                              }
                              //Pegando o nome do usuário
                              String? userName =
                                  snapshotName.data ?? 'Usuário Desconhecido';

                              // Definir estilo do nome com riscado se expirado
                              TextStyle userNameStyle = isExpired
                                  ? const TextStyle(
                                      color: Colors.black,
                                      decoration: TextDecoration
                                          .lineThrough, // Nome riscado
                                      decorationThickness:
                                          2, // Espessura da linha
                                      fontSize: 14,
                                      decorationColor: Colors.black
                                    )
                                  : const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2.5,
                                      fontSize: 14,
                                    );

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: backgroundColor,
                                ),
                                child: ExpansionTile(
                                  leading: const SizedBox(width: 30),
                                  dense: true,
                                  title: Align(
                                    alignment: Alignment.center,
                                    child: Text(userName.toUpperCase(), style: userNameStyle),
                                  ),
                                  children: [
                                    Align(
                                      alignment: Alignment.center,
                                      child: Padding(
                                        padding: const EdgeInsets.all(0.0),
                                        child: Column(
                                          children: [
                                            if (event['description'] != null &&
                                                event['description']!
                                                    .isNotEmpty)
                                              Text(
                                                event['title'],
                                                style: userNameStyle,
                                              ),
                                            Text(event['description'],
                                                style: userNameStyle),
                                            Text(
                                              '$startFormatted - $endFormatted', // Mostra a hora de início e fim
                                              style: userNameStyle,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            backgroundColor: const Color(0xff303030),
            context: context,
            builder: (context) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: ModalForm(),
              );
            },
          );
        },
        backgroundColor: Colors.grey,
        shape: const CircleBorder(
          eccentricity: 1,
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
