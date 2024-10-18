// import 'dart:convert';
import 'package:app_mensagem/pages/recursos/list_users_dropdown.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:http/http.dart' as http;
import 'package:app_mensagem/pages/recursos/button.dart';
import 'package:app_mensagem/pages/recursos/data_time_field.dart';
import 'package:app_mensagem/pages/recursos/text_field.dart';
import 'package:flutter/material.dart';
// import 'package:google_sign_in/google_sign_in.dart';
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
                height: 5,
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
                height: 2,
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

                    // // Primeiro, crie o evento em formato JSON
                    // var jsonEvent = await eventToJson(
                    //     eventTextField.text,
                    //     descriptionTextField.text,
                    //     dateTimeInitial,
                    //     dateTimeEnd,
                    //     reminderMinutes,
                    //     notification);

                    // // Em seguida, faça a autenticação com o Google para obter o token
                    // String? accessToken = await signInWithGoogle();

                    // if (accessToken != null) {
                    //   // Finalmente, adicione o evento ao Google Calendar usando o token e o JSON do evento
                    //   await addEventToCalendar(accessToken, jsonEvent);
                    // }
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

// //Transformando o evento preenchido em json para o google interpretar
//   Future<dynamic> eventToJson(
//       String title,
//       String description,
//       DateTime dateTimeIntial,
//       DateTime dateTimeEnd,
//       int reminderMinutes,
//       String notification) async {
//     final json = {
//       'summary': title,
//       'description': description,
//       'start': {
//         'dateTime': dateTimeIntial.toIso8601String(),
//         'timeZone': 'America/Sao_Paulo'
//       },
//       'end': {
//         'dateTime': dateTimeEnd.toIso8601String(),
//         'timeZone': 'America/Sao_Paulo'
//       },
//       'reminders': {
//         'useDefault': false,
//         'overrides': [
//           {
//             'method': notification,
//             'minutes': reminderMinutes
//           }, // Lembrete personalizado
//         ],
//       }
//     };
//     return json;
//   }

  // //Usando a autenticação do google para conseguir o token e se ligar ao google calendar
  // Future<String?> signInWithGoogle() async {
  //   try {
  //     final GoogleSignIn googleSignIn = GoogleSignIn(
  //       scopes: <String>[
  //         'https://www.googleapis.com/auth/calendar',
  //         'https://www.googleapis.com/auth/calendar.events'
  //       ],
  //     );

  //     final GoogleSignInAccount? googleSignInAccount =
  //         await googleSignIn.signIn();
  //     final GoogleSignInAuthentication googleSignInAuthentication =
  //         await googleSignInAccount!.authentication;
  //     //Pegando o Id do usuário
  //     String? userId = selectedUser!;
  //     await FirebaseFirestore.instance.collection('users').doc(userId).set(
  //       {'googleAccessToken': googleSignInAuthentication.accessToken},
  //       SetOptions(merge: true),
  //     );
  //     return googleSignInAuthentication.accessToken;
  //   } catch (error) {
  //     // ignore: use_build_context_synchronously
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(
  //           error.toString(),
  //         ),
  //       ),
  //     );
  //     return null;
  //   }
  // }

  // //Adiciona o evento ao calendário
  // Future addEventToCalendar(String accessToken, dynamic jsonEvent) async {
  //   final headers = {
  //     'Authorization': 'Bearer $accessToken',
  //     'Content-Type': 'application/json'
  //   };

  //   final response = await http.post(
  //     Uri.parse(
  //         'https://www.googleapis.com/calendar/v3/calendars/primary/events'),
  //     headers: headers,
  //     body: jsonEncode(jsonEvent),
  //   );
  //   if (response.statusCode == 200) {
  //     // ignore: use_build_context_synchronously
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Evento adicionado com sucesso!'),
  //       ),
  //     );
  //   } else {
  //     // ignore: use_build_context_synchronously
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Error ao inserir o evento ${response.statusCode}'),
  //       ),
  //     );
  //   }
  // }

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
