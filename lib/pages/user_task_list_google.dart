import 'dart:convert';
import 'package:app_mensagem/services/auth/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart';

class UserTaskListGoogle extends StatefulWidget {
  const UserTaskListGoogle({super.key});

  @override
  State<UserTaskListGoogle> createState() => _UserTaskListGoogleState();
}

class _UserTaskListGoogleState extends State<UserTaskListGoogle> {
  final AuthService authService = AuthService();
  List<Map<String, dynamic>> googleCalendarEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCalendarAndEvents();
  }

  /////////////////////////
  /// Método para obter o cliente do Google Calendar
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

    final credentials =
        ServiceAccountCredentials.fromJson(json.decode(jsonCredentials));
    final scopes = [calendar.CalendarApi.calendarScope];
    var client = await clientViaServiceAccount(credentials, scopes);
    return calendar.CalendarApi(client);
  }

  //////////////////////////
  /// Método para obter o ID do calendário da empresa
  Future<String> getCalendarId() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return authService.getCalendarIdFromCompanyCode(userDoc['code']);
  }

  //////////////////////
  /// Método para buscar os eventos do calendário Google
  Future<void> fetchCalendarAndEvents() async {
    try {
      String enterpriseCalendarId = await getCalendarId();
      var calendarApi = await getCalendarApiClient();
      var events = await calendarApi.events.list(enterpriseCalendarId);

      googleCalendarEvents = events.items?.map((event) {
            return {
              'title': event.summary ?? 'Tarefa sem título',
              'start_time': event.start?.dateTime?.toString() ?? '',
              'end_time': event.end?.dateTime?.toString() ?? '',
              'description': event.description ?? '',
              'source': 'google'
            };
          }).toList() ??
          [];
    } catch (e) {
      //
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }

    if (googleCalendarEvents.isEmpty) {
      return const Center(
          child: Text('Nenhuma tarefa encontrada no Google Calendar'));
    }

    return ListView.builder(
      itemCount: googleCalendarEvents.length,
      itemBuilder: (context, index) {
        final event = googleCalendarEvents[index];
        return _buildEventTile(event);
      },
    );
  }

  Widget _buildEventTile(Map<String, dynamic> event) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color.fromARGB(255, 116, 111, 111),
        ),
        child: ListTile(
          title: Center(
            child: Text(
              event['title'],
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          subtitle: Center(
            child: Text(
              '${_formatDateTime(event['start_time'])} - ${_formatDateTime(event['end_time'])}',
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return 'Sem data';
    DateTime dateTime = DateTime.parse(dateTimeStr);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
