/*
  Classe do formulário modal
  Feito por: Rodrigo abreu Amorim
  Ultima modificação: 04/12/2024
 */


import 'dart:convert';
import 'package:app_mensagem/services/auth/auth_service.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;
import 'package:app_mensagem/pages/recursos/list_users_dropdown.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_mensagem/pages/recursos/button.dart';
import 'package:app_mensagem/pages/recursos/data_time_field.dart';
import 'package:app_mensagem/pages/recursos/text_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ModalForm extends StatefulWidget {
  const ModalForm({super.key});

  @override
  State<ModalForm> createState() => _ModalFormState();
}

class _ModalFormState extends State<ModalForm> {
  //Variaveis de Controle
  final eventTextField = TextEditingController();
  final descriptionTextField = TextEditingController();
  final dataInitialField = TextEditingController();
  final dataEndField = TextEditingController();
  // Variável para armazenar o tempo do lembrete
  int reminderMinutes = 10; // Valor padrão de 10 minutos
  //Variável para o tipo de notificação padrão
  String notification = 'popup';
  //Obtendo o serviço de autenticação
  final authService = AuthService();

  // Lista de opções para o tempo de lembrete
  final List<int> reminderOptions = [5, 10, 15, 30, 60, 120]; // Minutos
  // Lista de opções para a notificação
  final List<String> notificationOptions = ['popup', 'email'];

  // Variável para armazenar o usuário selecionado (a quem a tarefa será delegada)
  String? selectedUser;

  @override
  void dispose() {
    // Lembre-se de limpar os controladores para evitar vazamento de memória
    eventTextField.dispose();
    descriptionTextField.dispose();
    dataInitialField.dispose();
    dataEndField.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size tela = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                height: 30,
              ),
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
              const SizedBox(
                height: 10,
              ),
              SizedBox(
                width: tela.width - 150,
                child: MyTextField(
                    controller: eventTextField,
                    labelText: 'Informe o Evento ou Tarefa',
                    obscureText: false),
              ),
              //Espaçamento entre os campos
              const SizedBox(
                height: 25,
              ),
              SizedBox(
                width: tela.width - 150,
                child: MyTextField(
                    controller: descriptionTextField,
                    labelText: 'Descrição',
                    obscureText: false),
              ),
              //Espaçamento entre os campos
              const SizedBox(
                height: 25,
              ),
              SizedBox(
                width: tela.width - 150,
                child: MyDateTimeField(
                    controller: dataInitialField,
                    labelText: 'Data e Hora do Início'),
              ),
              //Espaçamento entre os campos
              const SizedBox(
                height: 25,
              ),
              SizedBox(
                width: tela.width - 150,
                child: MyDateTimeField(
                    controller: dataEndField, labelText: 'Data e Hora do Fim'),
              ),
              //Espaçamento entre os campos
              const SizedBox(
                height: 25,
              ),
              // Dropdown para selecionar o tempo de lembrete
              SizedBox(
                width: tela.width - 150,
                child: DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                      labelText: 'Lembrete antes do evento (minutos)'),
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
              ),
              //Espaçamento entre os campos
              const SizedBox(
                height: 25,
              ),
              // Dropdown para selecionar o tipo de notificação
              SizedBox(
                width: tela.width - 150,
                child: DropdownButtonFormField<dynamic>(
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
              ),
              const SizedBox(
                height: 25,
              ),
              SizedBox(
                width: tela.width - 150,
                child: MyButton(
                  onTap: () async {
                    try {
                      // Obter as datas a partir dos campos MyDateTimeField
                      DateTime dateTimeInitial = DateFormat('dd/MM/yyyy HH:mm')
                          .parse(dataInitialField.text);
                      DateTime dateTimeEnd = DateFormat('dd/MM/yyyy HH:mm')
                          .parse(dataEndField.text);

                      if (selectedUser != null) {
                        String uid = FirebaseAuth.instance.currentUser!.uid;

                        // Obter o código da empresa do usuário autenticado
                        DocumentSnapshot userDoc = await FirebaseFirestore
                            .instance
                            .collection('users')
                            .doc(uid)
                            .get();
                        String enterpriseCode = userDoc['code'];

                        // Obter o ID do calendário vinculado à empresa
                        var calendarId = await authService
                            .getCalendarIdFromCompanyCode(enterpriseCode);

                        // Criar o evento no Google Calendar e obter o ID do evento criado
                        String? eventId = await addEventToCalendar(
                          calendarId: calendarId,
                          title: eventTextField.text,
                          description: descriptionTextField.text,
                          startTimeText: dataInitialField.text,
                          endTimeText: dataEndField.text,
                          reminderMinutes: reminderMinutes,
                          notification: notification,
                        );

                        if (eventId != null) {
                          // Criar a tarefa no Firestore, incluindo o ID do evento do Google Calendar
                          await delegateTaskToUser(
                            selectedUser!,
                            eventTextField.text,
                            descriptionTextField.text,
                            dateTimeInitial,
                            dateTimeEnd,
                            eventId: eventId, // Passar o ID do evento
                          );

                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Evento adicionado com sucesso!'),
                            ),
                          );
                        } else {
                          throw Exception(
                              'Erro ao obter o ID do evento do Google Calendar.');
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Selecione um usuário para a tarefa.'),
                          ),
                        );
                      }
                    } catch (e) {
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erro: $e'),
                        ),
                      );
                    }
                  },
                  text: 'Adicionar ao Calendário',
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

//////////////////////////////////
///Transformando o evento preenchido em json para o google interpretar
  Future<dynamic> eventToJson(
      String title,
      String description,
      DateTime dateTimeIntial,
      DateTime dateTimeEnd,
      int reminderMinutes,
      String notification) async {
    final json = {
      'summary': title,
      'description': description,
      'start': {
        'dateTime': dateTimeIntial.toIso8601String(),
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
      },
      'source': 'google'
    };
    return json;
  }

//////////////////
/// Função para gerar e obter o access token
  Future<String> getAccessToken() async {
    const serviceAccountEmail =
        'firebase-adminsdk-uqeoc@chatapp-f6349.iam.gserviceaccount.com';
    // Pegando as chaves de acesso de forma segura e privada do Firestore
    QuerySnapshot<Map<String, dynamic>> keySnapshot =
        await FirebaseFirestore.instance.collection('key').get();
    var keyDoc = keySnapshot.docs;
    // Pegando as chaves do Firestore
    String privateKey = keyDoc[0]['private_key'];
    privateKey =
        privateKey.replaceAll("\\\\n", "\n"); // Corrige quebras de linha

    // Configuração do JWT Header e Claims
    final jwt = JWT(
      {
        "iss": serviceAccountEmail,
        "scope": "https://www.googleapis.com/auth/calendar",
        "aud": "https://oauth2.googleapis.com/token",
        "exp": (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600,
        "iat": DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
    );

    // Removendo as linhas PEM e criando uma chave privada RSA
    final privateKeyObject = RSAPrivateKey(privateKey);

    // Assinando o JWT com o algoritmo RS256
    final token = jwt.sign(
      privateKeyObject,
      algorithm: JWTAlgorithm.RS256,
    );

    // Enviar o token JWT para obter o access token do Google OAuth
    final response = await http.post(
      Uri.parse("https://oauth2.googleapis.com/token"),
      body: {
        "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
        "assertion": token,
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return responseData["access_token"];
    } else {
      throw Exception("Failed to obtain access token: ${response.body}");
    }
  }

  ////////////////////////////////
  /// Método para adicionar o evento ao google calendar e retorna armazenar o ID do evento
  Future<String?> addEventToCalendar({
    required String calendarId,
    required String title,
    required String description,
    required String startTimeText,
    required String endTimeText,
    required int reminderMinutes,
    required String notification,
  }) async {
    final accessToken = await getAccessToken();
    DateTime startTime = DateFormat('dd/MM/yyyy HH:mm').parse(startTimeText);
    DateTime endTime = DateFormat('dd/MM/yyyy HH:mm').parse(endTimeText);

    final eventJson = await eventToJson(
      title,
      description,
      startTime,
      endTime,
      reminderMinutes,
      notification,
    );

    final headers = {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.post(
        Uri.parse(
            'https://www.googleapis.com/calendar/v3/calendars/$calendarId/events'),
        headers: headers,
        body: jsonEncode(eventJson),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return responseData['id']; // Retorna o ID do evento
      } else {
        throw Exception("Erro ao criar evento no Google: ${response.body}");
      }
    } catch (e) {
      throw Exception("Falha ao adicionar evento ao Google Calendar: $e");
    }
  }

  ///////////////////////
  /// Método para delegar a tarefa para o Firestore e armazenar o UID
  Future<void> delegateTaskToUser(
    String userId,
    String title,
    String description,
    DateTime startTime,
    DateTime endTime, {
    required String eventId,
  }) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    // Busca o código da empresa do usuário autenticado na coleção global de usuários
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (userDoc.exists) {
      String enterpriseCode = userDoc['code'];

      // Cria a tarefa na subcoleção 'tasks' dentro da empresa do usuário autenticado
      DocumentReference taskRef = await FirebaseFirestore.instance
          .collection('enterprise')
          .doc(enterpriseCode)
          .collection('tasks')
          .add(
        {
          'assigned_to': userId,
          'delegate_by': uid,
          'title': title,
          'description': description,
          'start_time': startTime.toIso8601String(),
          'end_time': endTime.toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
          'source': 'app',
          'code': enterpriseCode,
          'google_event_id':
              eventId, // Adiciona o ID do evento do Google Calendar
        },
      );

      // Atualiza o documento recém-criado para incluir o UID
      await taskRef.update({'uid': taskRef.id});
    } else {
      throw Exception("Empresa do usuário não encontrada.");
    }
  }
}
