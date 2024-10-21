import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class UserTaskListGoogle extends StatefulWidget {
  const UserTaskListGoogle({super.key});

  @override
  State<UserTaskListGoogle> createState() => _UserTaskListGoogleState();
}

class _UserTaskListGoogleState extends State<UserTaskListGoogle> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/calendar.readonly'],
  );

  List<calendar.Event> _tasks = []; // Lista de eventos
  bool _isLoading = true; // Indicador de carregamento

  @override
  void initState() {
    super.initState();
    _fetchGoogleCalendarTasks();
  }

  Future<void> _fetchGoogleCalendarTasks() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        throw 'Login cancelado pelo usuário';
      }

      final authHeaders = await account.authHeaders;
      final httpClient = _GoogleHttpClient(authHeaders);

      // Chamada para a API do Google Calendar
      final calendarApi = calendar.CalendarApi(httpClient);
      final now = DateTime.now().toUtc();
      final events = await calendarApi.events.list(
        'primary',
        timeMin: now
            .subtract(const Duration(days: 30)), // Buscar desde 30 dias atrás
        timeMax:
            now.add(const Duration(days: 365)), // Buscar até 1 ano no futuro
        singleEvents: true,
        orderBy: 'startTime',
      );

      setState(() {
        _tasks = events.items ?? [];
        _isLoading = false;
      });
    } catch (e) {
      // print('Erro ao buscar tarefas: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(
        color: Colors.white,
      ));
    }

    if (_tasks.isEmpty) {
      return const Center(
          child: Text('Nenhuma tarefa encontrada no Google Calendar'));
    }

    return ListView.builder(
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final event = _tasks[index];
        final startTime = event.start?.dateTime ?? event.start?.date;
        final endTime = event.end?.dateTime ?? event.end?.date;

        return Column(
          children: [
            const SizedBox(height: 5),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color.fromARGB(255, 116, 111, 111),
              ),
              child: ListTile(
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      event.summary ?? 'Tarefa sem título',
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
                      '${_formatDateTime(startTime)} - ${_formatDateTime(endTime)}',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Sem data';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }
}

class _GoogleHttpClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleHttpClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}
