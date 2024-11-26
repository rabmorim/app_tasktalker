/*
  Modal para Criar Fóruns
  Feito por: Rodrigo abreu Amorim
  Última modificação: 26/11/2024
*/

import 'package:flutter/material.dart';

Future<void> showCreateForumModal({
  required BuildContext context,
  required Function(Map<String, dynamic>) onForumCreated,
}) async {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController messageController = TextEditingController();


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
                'Criar Novo Fórum',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: screenSize.width - 50,
                child: TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título do Fórum',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: screenSize.width - 50,
                child: TextField(
                  controller: messageController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Conteudo do Fórum',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.isEmpty ||
                      messageController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Preencha todos os campos obrigatórios."),
                      ),
                    );
                    return;
                  }

                  // Capturar os valores do formulário
                  String title = titleController.text;
                  String message = messageController.text;

                  Navigator.of(context).pop();

                  // Retornar os dados como argumentos separados
                  onForumCreated({'name': title, 'message': message});
                },
                child: const Text(
                  'Criar Fórum',
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
