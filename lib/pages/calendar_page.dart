import 'dart:convert';
import 'package:app_mensagem/pages/recursos/barra_superior.dart';
import 'package:app_mensagem/pages/recursos/drawer.dart';
import 'package:app_mensagem/pages/recursos/get_user.dart';
import 'package:app_mensagem/pages/recursos/modal_edit.dart';
import 'package:app_mensagem/pages/recursos/modal_form.dart';
import 'package:app_mensagem/pages/recursos/task_color_manager.dart';
import 'package:app_mensagem/services/auth/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart';
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
  AuthService authService = AuthService();
  // Listas separadas para eventos de Firestore e Google Calendar
  List<Map<String, dynamic>> firestoreEvents = [];
  List<Map<String, dynamic>> googleCalendarEvents = [];
  //Pegando a instância do usuário autenticado
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    loadFirestoreTasks();
    fetchCalendarAndEvents();
  }

  ////////////////////////
  /// Método que obtém o ID do calendário e, em seguida, chama fetchGoogleCalendar
  Future<void> fetchCalendarAndEvents() async {
    try {
      // Obtenha o ID do calendário da empresa do Firestore
      String enterpriseCalendarId = await getCalendarId();

      // Chame o fetchGoogleCalendar com o ID do calendário da empresa
      await fetchGoogleCalendar(enterpriseCalendarId);
    } catch (e) {
      //
    }
  }

  //////////////////////////
  /// Método para Pegar o Id do calendário usando a instância do authservice
  Future<String> getCalendarId() async {
    String? uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    String enterpriseCode = userDoc['code'];
    var calendarId =
        await authService.getCalendarIdFromCompanyCode(enterpriseCode);

    return calendarId;
  }

  //////////////////////////////
  /// Método para obter o client autenticado
  Future<calendar.CalendarApi> getCalendarApiClient() async {
    //Pegando as chaves de acesso de forma segura e privada
    QuerySnapshot<Map<String, dynamic>> keySnapshot =
        await FirebaseFirestore.instance.collection('key').get();
    var keyDoc = keySnapshot.docs;
    // Pegando as chaves do Firestore
    String privateKey = keyDoc[0]['private_key'];
    privateKey = privateKey.replaceAll("\\\\n", "\n");
    String privateKeyId = keyDoc[1]['private_key_id'];

// Inserindo corretamente os delimitadores no JSON
    // Constrói o JSON de credenciais com a chave formatada corretamente
    var jsonCredentials = '''
  {
    "type": "service_account",
    "project_id": "chatapp-f6349",
    "private_key_id": "$privateKeyId",
    "private_key": "${privateKey.replaceAll('\n', '\\n')}",
    "client_email": "firebase-adminsdk-uqeoc@chatapp-f6349.iam.gserviceaccount.com",
    "client_id": "109927196779049391016",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-uqeoc%40chatapp-f6349.iam.gserviceaccount.com",
    "universe_domain": "googleapis.com"
  }
  ''';

    var credentials =
        ServiceAccountCredentials.fromJson(json.decode(jsonCredentials));

    final scopes = [calendar.CalendarApi.calendarScope];

    var client = await clientViaServiceAccount(credentials, scopes);
    return calendar.CalendarApi(client);
  }

//////////////////////////
  /// Método para buscar os eventos no Google Calendar
  Future<void> fetchGoogleCalendar(String enterpriseCalendarId) async {
    try {
      var calendarApi = await getCalendarApiClient();
      var events = await calendarApi.events.list(enterpriseCalendarId);

      googleCalendarEvents = events.items?.map((event) {
            return {
              'title': event.summary,
              'start_time': event.start?.dateTime?.toString(),
              'end_time': event.end?.dateTime?.toString(),
              'description': event.description,
              'source': 'google'
            };
          }).toList() ??
          [];
      // Chama a função para processar todos os eventos após carregar o Google Calendar
      processAllEvents();
    } catch (e) {
      //
    }
  }

  ///////////////////////////
  /// Método para carregar as tarefas do Firestore
  Future<void> loadFirestoreTasks() async {
    String? uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (userDoc.exists) {
      String enterpriseCode = userDoc['code'];
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('enterprise')
          .doc(enterpriseCode)
          .collection('tasks')
          .get();

      firestoreEvents = await Future.wait(snapshot.docs.map((doc) async {
        var task = doc.data() as Map<String, dynamic>;
        String userId = task['assigned_to'];

        // Pega o documento do usuário para obter a cor
        DocumentSnapshot<Map<String, dynamic>> assignedUserDoc =
            await FirebaseFirestore.instance
                .collection('enterprise')
                .doc(enterpriseCode)
                .collection('users')
                .doc(userId)
                .get();

        String? userColorHex = assignedUserDoc['color'];
        if (userColorHex != null) {
          task['userColor'] = Color(
              int.parse(userColorHex.substring(1, 7), radix: 16) + 0xFF000000);
        }
        return task;
      }).toList());

      // Chama a função para processar todos os eventos após carregar as tarefas do Firestore
      processAllEvents();
    } else {
      throw Exception("Empresa do usuário não encontrada.");
    }
  }

  /////////////////////////
  /// Método para normalizar datas
  String normalizeDateString(dynamic date) {
    // Verifica se é Timestamp e converte para DateTime
    DateTime dateTime;
    if (date is Timestamp) {
      dateTime = date.toDate();
    } else if (date is String) {
      dateTime = DateTime.parse(date);
    } else {
      throw ArgumentError('Data em formato inválido');
    }

    // Converte para o formato local e retorna a string normalizada
    dateTime = dateTime.toLocal();
    return "${dateTime.year.toString().padLeft(4, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  ///////////////////////
  /// Método para processar e combinar eventos sem duplicação
  void processAllEvents() {
    List<Map<String, dynamic>> combinedEvents = [];
    Set<String> uniqueEventKeys = {};

    // Adiciona eventos do Firestore ao combinedEvents e armazena as chaves únicas
    for (var event in firestoreEvents) {
      String normalizedStartTime = normalizeDateString(event['start_time']);
      String eventKey =
          "${event['title']?.trim()?.toLowerCase()}_$normalizedStartTime";

      if (!uniqueEventKeys.contains(eventKey)) {
        combinedEvents.add(event);
        uniqueEventKeys.add(eventKey);
      }
    }

    // Adiciona eventos do Google Calendar ao combinedEvents se a chave for única
    for (var event in googleCalendarEvents) {
      String normalizedStartTime = normalizeDateString(event['start_time']);
      String eventKey =
          "${event['title']?.trim()?.toLowerCase()}_$normalizedStartTime";

      if (!uniqueEventKeys.contains(eventKey)) {
        combinedEvents.add(event);
        uniqueEventKeys.add(eventKey);
      }
    }
    // Atualiza o estado com a lista combinada e organizada por data
    setState(() {
      eventsMap = groupEventsByDate(combinedEvents);
      if (_selectedDay != null) {
        _selectedEvents = eventsMap[_selectedDay!] ?? [];
      }
    });
  }

  /////////////////////
  /// Método para Normalizar as datas
  DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  ///////////////////////
  /// Método para Formatar a hora para impressão no listview
  String formatTime(String dateTimeString) {
    DateTime dateTime = DateTime.parse(dateTimeString).toLocal();
    return DateFormat('HH:mm')
        .format(dateTime); // Formato de 24 horas (ex: 14:30)
  }

  ///////////////////////
  /// Agrupador de eventos por data
  Map<DateTime, List<dynamic>> groupEventsByDate(
      List<Map<String, dynamic>> tasks) {
    Map<DateTime, List<dynamic>> groupedEvents = {};

    for (var task in tasks) {
      String? startTimeString = task['start_time'];
      String? endTimeString = task['end_time'];

      if (startTimeString != null && endTimeString != null) {
        DateTime startDate = DateTime.parse(startTimeString).toLocal();
        DateTime endDate = DateTime.parse(endTimeString).toLocal();
        DateTime initialNormalizedDate = normalizeDate(startDate);
        DateTime finalNormalizedDate = normalizeDate(endDate);

        // Adiciona evento ao mapa, garantindo que não haja duplicação
        groupedEvents.putIfAbsent(initialNormalizedDate, () => []).add(task);
        if (initialNormalizedDate != finalNormalizedDate) {
          groupedEvents.putIfAbsent(finalNormalizedDate, () => []).add(task);
        }
      }
    }
    return groupedEvents;
  }

///////////////////////////////
  /// Método para deletar um evento
  Future<void> _deleteEvent(String eventId, String companyId) async {
    final confirm = await showDeleteConfirmationDialog();

    if (confirm == true) {
      try {
        await authService.deleteEvent(eventId: eventId, companyId: companyId);
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Evento excluído com sucesso!")),
        );
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao excluir evento: $e")),
        );
      }
    }
  }

///////////////////////////////////
  /// Método para criação do balão para confirmação de exclusão
  Future<bool?> showDeleteConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Excluir Evento'),
          content: const Text('Tem certeza de que deseja excluir este evento?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Excluir',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  ////////////////////////
  /// Método para Editar eventos
  void _editEvent(
      Map<String, dynamic> event, String eventId, String companyId) {
    showEditEventModal(
      context: context,
      event: event,
      onEventEdited: (updatedEvent) async {
        try {
          await AuthService().editEvent(
            eventId: eventId,
            companyId: companyId,
            updatedData: updatedEvent,
          );
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Evento atualizado com sucesso!")),
          );
          setState(() {
            // Atualizar a exibição dos eventos
          });
        } catch (e) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erro ao atualizar evento: $e")),
          );
        }
      },
    );
  }

  /////////////////////////////
  ///Método que controla o formato do calendário escolhido pelo usuário
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
                fetchCalendarAndEvents();
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
            }, markerBuilder: (context, day, events) {
              if (events.isNotEmpty) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: events.map<Widget>((event) {
                    var eventSource = (event as Map<String, dynamic>)['source'];

                    if (eventSource == 'app') {
                      var userId = event['assigned_to'];
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
                                        0.8), // Espaçamento entre as bolinhas
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
                      }
                    } else if (eventSource == 'google') {
                      // Exibe uma bolinha branca para eventos do Google Calendar
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 0.8),
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      );
                    }

                    return Container(); // Placeholder para eventos que não possuem source
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

                        if (event['source'] == 'app') {
                          var userId = event['assigned_to'];
                          final startTime = event['start_time'];
                          final endTime = event['end_time'];

                          String startFormatted =
                              startTime != null ? formatTime(startTime) : '';
                          String endFormatted =
                              endTime != null ? formatTime(endTime) : '';

                          return FutureBuilder<Color?>(
                            future: colorManager.getUserColor(userId ?? ""),
                            builder: (context, snapshotColor) {
                              Color userColor =
                                  snapshotColor.data ?? Colors.grey;
                              DateTime now = DateTime.now();
                              DateTime endTimeParsed =
                                  DateTime.parse(event['end_time']);
                              bool isExpired = endTimeParsed.isBefore(now);

                              Color backgroundColor = isExpired
                                  ? Colors.white.withOpacity(0.8)
                                  : userColor;

                              return FutureBuilder<String?>(
                                future: getUserName.getUserName(userId ?? ""),
                                builder: (context, snapshotName) {
                                  String userName = snapshotName.data ?? '';
                                  TextStyle userNameStyle = isExpired
                                      ? const TextStyle(
                                          color: Colors.black,
                                          decoration:
                                              TextDecoration.lineThrough,
                                          decorationThickness: 2,
                                          fontSize: 14,
                                          decorationColor: Colors.black)
                                      : const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 2.5,
                                          fontSize: 14,
                                        );

                                  return GestureDetector(
                                    onLongPressStart:
                                        (LongPressStartDetails details) {
                                      if (userId ==
                                          firebaseAuth.currentUser!.uid) {
                                        // Verificar permissão
                                        showMenu(
                                          context: context,
                                          position: RelativeRect.fromLTRB(
                                            details.globalPosition.dx,
                                            details.globalPosition.dy,
                                            details.globalPosition.dx,
                                            details.globalPosition.dy,
                                          ),
                                          items: [
                                            PopupMenuItem<String>(
                                              value: 'Editar',
                                              child: const ListTile(
                                                leading: Icon(Icons.edit),
                                                title: Text('Editar'),
                                              ),
                                              onTap: () => _editEvent(event,
                                                  event['uid'], event['code']),
                                            ),
                                            PopupMenuItem<String>(
                                              value: 'Excluir',
                                              child: const ListTile(
                                                leading: Icon(Icons.delete),
                                                title: Text('Excluir'),
                                              ),
                                              onTap: () => _deleteEvent(
                                                  event['uid'], event['code']),
                                            ),
                                          ],
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Você não tem permissão para editar este evento.'),
                                          ),
                                        );
                                      }
                                    },
                                    child: Container(
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
                                          child: Text(userName.toUpperCase(),
                                              style: userNameStyle),
                                        ),
                                        children: [
                                          Align(
                                            alignment: Alignment.center,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(0.0),
                                              child: Column(
                                                children: [
                                                  if (event['title'] != null &&
                                                      event['title']!
                                                          .isNotEmpty)
                                                    Text(
                                                      event['title'],
                                                      style: userNameStyle,
                                                    ),
                                                  if (event['description'] !=
                                                          null &&
                                                      event['description']!
                                                          .isNotEmpty)
                                                    Text(
                                                      event['description'],
                                                      style: userNameStyle,
                                                    ),
                                                  Text(
                                                    '$startFormatted - $endFormatted',
                                                    style: userNameStyle,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        } else if (event['source'] == 'google') {
                          final title = event['title'] ?? 'Evento';
                          final startTime = event['start_time'];
                          final endTime = event['end_time'];

                          String startFormatted =
                              startTime != null ? formatTime(startTime) : '';
                          String endFormatted =
                              endTime != null ? formatTime(endTime) : '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.blueGrey[
                                  100], // Cor padrão para eventos do Google Calendar
                            ),
                            child: ExpansionTile(
                              leading: const SizedBox(width: 30),
                              dense: true,
                              title: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  title.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2.5,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              children: [
                                Align(
                                  alignment: Alignment.center,
                                  child: Padding(
                                    padding: const EdgeInsets.all(0.0),
                                    child: Column(
                                      children: [
                                        if (event['description'] != null &&
                                            event['description']!.isNotEmpty)
                                          Text(
                                            event['description'],
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 2.5,
                                              fontSize: 14,
                                            ),
                                          ),
                                        Text(
                                          '$startFormatted - $endFormatted',
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 2.5,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return null;
                      },
                    ))
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (context) => Scaffold(
                appBar: AppBar(
                  title: const Text('Adicione uma Tarefa '),
                ),
                body: const ModalForm(),
              ),
            ),
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
