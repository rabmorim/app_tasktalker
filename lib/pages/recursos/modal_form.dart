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
                    // Obter as datas a partir dos campos MyDateTimeField
                    DateTime dateTimeInitial = DateFormat('dd/MM/yyyy HH:mm')
                        .parse(dataInitialField.text);
                    DateTime dateTimeEnd =
                        DateFormat('dd/MM/yyyy HH:mm').parse(dataEndField.text);

                    //Verificação se um usuário foi selecionado
                    if (selectedUser != null) {
                      String? uid = FirebaseAuth.instance.currentUser!.uid;
                      DocumentSnapshot userDoc = await FirebaseFirestore
                          .instance
                          .collection('users')
                          .doc(uid)
                          .get();

                      String enterpriseCode = userDoc['code'];
                      var calendarId = await authService
                          .getCalendarIdFromCompanyCode(enterpriseCode);

                      //Criar o registro da tarefa no Firestore para o usuário selecionada
                      await delegateTaskToUser(
                          selectedUser!,
                          eventTextField.text,
                          descriptionTextField.text,
                          dateTimeInitial,
                          dateTimeEnd);
                      //Cria a tarefa no google calendar
                      await addEventToCalendar(
                          calendarId: calendarId,
                          title: eventTextField.text,
                          description: descriptionTextField.text,
                          startTimeText: dataInitialField.text,
                          endTimeText: dataEndField.text,
                          reminderMinutes: reminderMinutes,
                          notification: notification);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Selecione um usuário para a tarefa.'),
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

//Transformando o evento preenchido em json para o google interpretar
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

// Função para gerar e obter o access token
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

  Future<void> addEventToCalendar({
    required String calendarId,
    required String title,
    required String description,
    required String startTimeText,
    required String endTimeText,
    required int reminderMinutes,
    required String notification,
  }) async {
    // Obtendo o access token usando o método com o JWT assinado
    final accessToken = await getAccessToken();

    // Configurando as datas de início e fim no formato correto
    DateTime startTime = DateFormat('dd/MM/yyyy HH:mm').parse(startTimeText);
    DateTime endTime = DateFormat('dd/MM/yyyy HH:mm').parse(endTimeText);

    // Formatando o evento para o formato JSON exigido pela API do Google Calendar
    final eventJson = await eventToJson(
      title,
      description,
      startTime,
      endTime,
      reminderMinutes,
      notification,
    );

    // Cabeçalhos da requisição com o token de autenticação
    final headers = {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };

    try {
      // Enviando a requisição para criar o evento no Google Calendar
      final response = await http.post(
        Uri.parse(
            'https://www.googleapis.com/calendar/v3/calendars/$calendarId/events'),
        headers: headers,
        body: jsonEncode(eventJson),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evento Adicionado com Sucesso!'),
          ),
        );
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Erro ao adicionar evento: ${response.statusCode} - ${response.body}"),
          ),
        );
      }
    } catch (e) {
      //
    }
  }

  ///////////////////////
  /// Método para delegar a tarefa para o Firestore
  ///////////////////////
  /// Método para delegar a tarefa para o Firestore e armazenar o UID
  Future<void> delegateTaskToUser(
    String userId,
    String title,
    String description,
    DateTime startTime,
    DateTime endTime,
  ) async {
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
          'title': title,
          'description': description,
          'start_time': startTime.toIso8601String(),
          'end_time': endTime.toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
          'source': 'app',
          'code': enterpriseCode,
        },
      );

      // Atualiza o documento recém-criado para incluir o UID
      await taskRef.update({'uid': taskRef.id});
    } else {
      throw Exception("Empresa do usuário não encontrada.");
    }
  }
}
