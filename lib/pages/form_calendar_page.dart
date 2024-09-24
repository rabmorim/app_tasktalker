import 'dart:convert';
import 'package:app_mensagem/pages/recursos/barra_superior.dart';
import 'package:app_mensagem/pages/recursos/button.dart';
import 'package:app_mensagem/pages/recursos/data_time_field.dart';
import 'package:app_mensagem/pages/recursos/drawer.dart';
import 'package:app_mensagem/pages/recursos/list_users_dropdown.dart';
import 'package:app_mensagem/pages/recursos/text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class FormCalendarWidget extends StatefulWidget {
  const FormCalendarWidget({super.key});

  @override
  State<FormCalendarWidget> createState() => _FormCalendarWidgetState();
}

class _FormCalendarWidgetState extends State<FormCalendarWidget> {
  //Variaveis de controle
  final eventTextField = TextEditingController();
  final descriptionTextField = TextEditingController();
  final dataInitialField = TextEditingController();
  final dataEndField = TextEditingController();

  // Variável para armazenar o tempo do lembrete
  int reminderMinutes = 10; // Valor padrão de 10 minutos
  //Variável para o tipo de notificação padrão
  String notification = 'popup';

  // Lista de opções para o tempo de lembrete
  final List<int> reminderOptions = [5, 10, 18, 30, 60, 120]; // Minutos
  // Lista de opções para a notificação
  final List<String> notificationOptions = ['popup', 'email'];
  // Variável para armazenar o usuário selecionado (a quem a tarefa será delegada)
  String? selectedUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BarraSuperior(
        titulo: 'Adicionar Evento',
        isCalendarPage: false,
      ),
      drawer: MenuDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 30),
        child: Center(
          child: SizedBox(
            width: 280,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //DropDown dos usuarios
                UserListDropdown(
                  onUserSelected: (userId) {
                    setState(
                      () {
                        selectedUser = userId;
                      },
                    );
                  },
                ),
                //Espaçamento entre os campos
                const SizedBox(height: 18),
                MyTextField(
                    controller: eventTextField,
                    labelText: 'Informe o Evento ou Tarefa',
                    obscureText: false),

                //Espaçamento entre os campos
                const SizedBox(height: 18),
                MyTextField(
                    controller: descriptionTextField,
                    labelText: 'Descrição',
                    obscureText: false),
                //Espaçamento entre os campos
                const SizedBox(height: 18),
                MyDateTimeField(
                    controller: dataInitialField,
                    labelText: 'Data e Hora do Início'),
                //Espaçamento entre os campos
                const SizedBox(height: 18),
                MyDateTimeField(
                    controller: dataEndField, labelText: 'Data e Hora do Fim'),
                //Espaçamento entre os campos
                const SizedBox(height: 18),

                // Dropdown para selecionar o tempo de lembrete
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                      labelText: 'Lembrete antes do evento'),
                  value: reminderMinutes,
                  items: reminderOptions.map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value minutos'),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      reminderMinutes = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 18),

                // Dropdown para selecionar o tipo de notificação
                DropdownButtonFormField<dynamic>(
                  decoration:
                      const InputDecoration(labelText: 'Tipo de lembrete'),
                  value: notification,
                  items: notificationOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      notification = newValue!;
                    });
                  },
                ),
                //Espaçamento
                const SizedBox(height: 15),

                MyButton(
                  onTap: () async {
                    DateTime dateTimeInitial = DateFormat('dd/MM/yyyy HH:mm')
                        .parse(dataInitialField.text);
                    DateTime dateTimeEnd =
                        DateFormat('dd/MM/yyyy HH:mm').parse(dataEndField.text);

                    //Verificação se um usuário foi selecionado
                    if (selectedUser != null) {
                      //Criar o registro da tarefa no Firestore para o usuário selecionada
                      await delegateTaskToUser(
                          selectedUser!,
                          eventTextField.text,
                          descriptionTextField.text,
                          dateTimeInitial,
                          dateTimeEnd);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Selecione um usuário para a tarefa.'),
                        ),
                      );
                    }

                    // Criação do evento em formato JSON, incluindo o lembrete
                    var jsonEvent = await eventToJson(
                        eventTextField.text,
                        descriptionTextField.text,
                        dateTimeInitial,
                        dateTimeEnd,
                        reminderMinutes, // Passando o tempo de lembrete
                        notification //passando o tipo de notificação
                        );

                    // Obter token de acesso
                    String? accessToken = await signInWithGoogle();

                    if (accessToken != null) {
                      // Adicionar evento ao calendário
                      await addEventToCalendar(accessToken, jsonEvent);
                    }
                  },
                  text: 'Delegar Tarefa ao Calendário',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Transforma o evento preenchido em JSON para o Google interpretar
  Future<dynamic> eventToJson(
      String title,
      String description,
      DateTime dateTimeInitial,
      DateTime dateTimeEnd,
      int reminderMinutes,
      String notification) async {
    final json = {
      'summary': title,
      'description': description,
      'start': {
        'dateTime': dateTimeInitial.toIso8601String(),
        'timeZone': 'America/Sao_Paulo'
      },
      'end': {
        'dateTime': dateTimeEnd.toIso8601String(),
        'timeZone': 'America/Sao_Paulo'
      },
      'reminders': {
        'useDefault': false,
        'overrides': [
          {
            'method': notification,
            'minutes': reminderMinutes
          }, // Lembrete personalizado
        ],
      }
    };
    return json;
  }

  // Autenticação com o Google para obter o token de acesso
  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: <String>[
          'https://www.googleapis.com/auth/calendar',
          'https://www.googleapis.com/auth/calendar.events'
        ],
      );

      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount!.authentication;
      return googleSignInAuthentication.accessToken;
    } catch (error) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString(),
          ),
        ),
      );
      return null;
    }
  }

  // Adicionar evento ao Google Calendar
  Future addEventToCalendar(String accessToken, dynamic jsonEvent) async {
    final headers = {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json'
    };

    final response = await http.post(
      Uri.parse(
          'https://www.googleapis.com/calendar/v3/calendars/primary/events'),
      headers: headers,
      body: jsonEncode(jsonEvent),
    );
    if (response.statusCode == 200) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evento adicionado com sucesso!'),
        ),
      );
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao inserir o evento ${response.statusCode}'),
        ),
      );
    }
  }

  // Função para delegar a tarefa para o Firestore
  Future<void> delegateTaskToUser(
    String userId,
    String title,
    String description,
    DateTime startTime,
    DateTime endTime,
  ) async {
    await FirebaseFirestore.instance.collection('tasks').add(
      {
        'assigned_to': userId,
        'title': title,
        'description': description,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }
}
