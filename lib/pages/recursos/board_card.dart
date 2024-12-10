import 'package:app_mensagem/pages/recursos/get_user.dart';
import 'package:flutter/material.dart';

class BoardCard extends StatelessWidget {
  final String title; // Título da tarefa
  final String message; // Descrição ou detalhes da tarefa
  final String color; // Cor associada ao usuário
  final String receiverUid; //uid do usuário delegado
  final GetUser _getUser = GetUser(); // Instancia do getUser

  BoardCard({
    super.key,
    required this.title,
    required this.message,
    required this.color,
    required this.receiverUid
    
  });

  @override
  Widget build(BuildContext context) {

    return FutureBuilder<String?>(
      future: _getUser.getUserName(receiverUid),
      builder: (context, snapshot) {
        // Verifica o estado da Future
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            color: Color(int.parse(color.replaceFirst('#', '0xff'))),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.white54,
                ),
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            color: Color(int.parse(color.replaceFirst('#', '0xff'))),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Erro ao carregar nome do usuário',
                style: TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        // Exibe o nome do usuário se o Future foi resolvido
        final String userName = snapshot.data ?? 'Usuário desconhecido';

        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          color: Color(int.parse(color.replaceFirst('#', '0xff'))),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      userName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
