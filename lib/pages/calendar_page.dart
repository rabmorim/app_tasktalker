import 'package:app_mensagem/pages/recursos/barra_superior.dart';
import 'package:app_mensagem/pages/recursos/drawer.dart';
import 'package:app_mensagem/pages/recursos/modal_form.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

final now = DateTime.now();
DateTime? _selectedDay;
DateTime _focusedDay = DateTime.now();

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  Map<DateTime, List<dynamic>> eventsMap = {}; // Armazena eventos por data
  List<dynamic> _selectedEvents = []; // Eventos da data selecionada

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
      DateTime startDate = DateTime.parse(task['start_time']).toLocal();
      DateTime endDate = DateTime.parse(task['end_time']).toLocal();
      DateTime initialNormalizedDate = normalizeDate(startDate);
      DateTime finalNormalizeDate = normalizeDate(endDate);

      // Adicionar evento ao mapa sem duplicação
      groupedEvents.putIfAbsent(initialNormalizedDate, () => []).add(task);
      if (initialNormalizedDate != finalNormalizeDate) {
        groupedEvents.putIfAbsent(finalNormalizeDate, () => []).add(task);
      }
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
            calendarBuilders: CalendarBuilders(
              dowBuilder: (context, day) {
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
                return Center(child: Text(text));
              },
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    bottom: 1,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: _selectedEvents.isEmpty
                ? const Center(child: Text('Nenhum evento'))
                : ListView.builder(
                    itemCount: _selectedEvents.length,
                    itemBuilder: (context, index) {
                      final event = _selectedEvents[index];
                      final startTime = event['start_time'];
                      final endTime = event['end_time'];
                      // Formatação das horas (apenas se houver 'dateTime' nos eventos)
                      String startFormatted =
                          startTime != null ? formatTime(startTime) : '';
                      String endFormatted =
                          endTime != null ? formatTime(endTime) : '';
                      return Container(
                        //Espaçamento entre as tarefas no list view
                        margin: const EdgeInsets.only(bottom: 8),

                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Colors.grey.shade700),
                        child: ListTile(
                          dense: true,
                          title: Text(
                            event['title'] ?? 'Sem título',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.5,
                                fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (event['description'] != null &&
                                  event['description']!.isNotEmpty)
                                Text(
                                  event[
                                      'description'], // Mostra a descrição se houver
                                  style: const TextStyle(color: Colors.white54),
                                ),
                              Text(
                                '$startFormatted - $endFormatted', // Mostra a hora de início e fim
                                style: const TextStyle(color: Colors.white54),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
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
