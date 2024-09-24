import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';


class UserListDropdown extends StatefulWidget {
  const UserListDropdown({super.key});

  @override
  State<UserListDropdown> createState() => _UserListDropdownState();
}

class _UserListDropdownState extends State<UserListDropdown> {
  String? selectedUser; // Variável para armazenar o usuário selecionado

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Erro ao carregar os usuários');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          );
        }

        // Se os dados estiverem prontos, criar a lista de itens
        List<DropdownMenuItem<String>> userItems = snapshot.data!.docs.map<DropdownMenuItem<String>>((DocumentSnapshot document) {
          Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
          return DropdownMenuItem<String>(
            value: data['uid'], // Use o ID do usuário como valor
            child: Text(data['userName'] ?? 'Usuário sem nome'), // Mostre o nome do usuário
          );
        }).toList();

        return DropdownButton<String>(
          borderRadius: BorderRadius.circular(15),
          icon: const Icon(Icons.person),
          hint: const Text('Selecione um usuário'),
          value: selectedUser, // Valor atual selecionado
          items: userItems, // Itens do Dropdown
          onChanged: (String? newValue) {
            setState(() {
              selectedUser = newValue; // Atualiza o usuário selecionado
            });
          },
        );
      },
    );
  }
}
