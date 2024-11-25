/*
  Classe do modal do método editar
  Feito por: Rodrigo abreu Amorim
  Ultima modificação: 25/11/2024
 */

import 'package:app_mensagem/pages/recursos/data_time_field.dart';
import 'package:app_mensagem/pages/recursos/list_users_dropdown.dart';
import 'package:app_mensagem/pages/recursos/text_field.dart';
import 'package:flutter/material.dart';

Future<void> showEditEventModal({
  required BuildContext context,
  required Map<String, dynamic> event,
  required Function(Map<String, dynamic>) onEventEdited,
}) async {
  final TextEditingController eventTextField = TextEditingController();
  final TextEditingController descriptionTextField = TextEditingController();
  final TextEditingController dataInitialField = TextEditingController();
  final TextEditingController dataEndField = TextEditingController();
  String? selectedUser = event['assigned_to'];

  // Preenchendo os campos com os valores existentes do evento
  eventTextField.text = event['title'] ?? '';
  descriptionTextField.text = event['description'] ?? '';
  dataInitialField.text = event['start_time'] ?? '';
  dataEndField.text = event['end_time'] ?? '';

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      final Size screenSize = MediaQuery.of(context).size;

      return Padding(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Editar Evento',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              UserListDropdown(
                onUserSelected: (userId) {
                  selectedUser = userId;
                },
                selectedUser: selectedUser,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: screenSize.width - 50,
                child: MyTextField(
                  controller: eventTextField,
                  labelText: 'Informe o Evento ou Tarefa',
                  obscureText: false,
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: screenSize.width - 50,
                child: MyTextField(
                  controller: descriptionTextField,
                  labelText: 'Descrição',
                  obscureText: false,
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: screenSize.width - 50,
                child: MyDateTimeField(
                  controller: dataInitialField,
                  labelText: 'Data e Hora do Início',
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: screenSize.width - 50,
                child: MyDateTimeField(
                  controller: dataEndField,
                  labelText: 'Data e Hora do Fim',
                ),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () {
                  if (eventTextField.text.isEmpty ||
                      dataInitialField.text.isEmpty ||
                      dataEndField.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Preencha todos os campos obrigatórios."),
                      ),
                    );
                    return;
                  }

                  // Criar o mapa atualizado do evento
                  Map<String, dynamic> updatedEvent = {
                    'title': eventTextField.text,
                    'description': descriptionTextField.text,
                    'start_time': dataInitialField.text,
                    'end_time': dataEndField.text,
                    'assigned_to': selectedUser
                  };

                  Navigator.of(context).pop();
                  onEventEdited({
                    'updatedEvent': updatedEvent,
                    'googleEventId': event[
                        'google_event_id'], // Adicione o ID do evento do Google Calendar
                    'calendarId': event[
                        'calendar_id'], // Adicione o ID do calendário do Google
                  });
                },
                child: const Text(
                  'Salvar Alterações',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    },
  );
}
