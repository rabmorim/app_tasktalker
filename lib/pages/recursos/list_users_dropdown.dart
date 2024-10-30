import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserListDropdown extends StatefulWidget {
  final Function(String)?
      onUserSelected; // Callback para quando o usuário for selecionado

  const UserListDropdown(
      {super.key,
      this.onUserSelected}); // Adicionando o parâmetro ao construtor

  @override
  State<UserListDropdown> createState() => _UserListDropdownState();
}

class _UserListDropdownState extends State<UserListDropdown> {
  String? selectedUser; // Variável para armazenar o usuário selecionado
  String?
      enterpriseCode; //Variavel para armazenar o código da empresa do usuário autenticado

  @override
  void initState() {
    super.initState();
    _fetchUserEnterpriseCode();
  }

  Future<void> _fetchUserEnterpriseCode() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    // Busca o código da empresa do usuário autenticado na coleção global de usuários
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (userDoc.exists) {
      setState(() {
        enterpriseCode = userDoc['code'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    //Verificação se existe o código
    if (enterpriseCode == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white54,
        ),
      );
    }
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('enterprise').doc(enterpriseCode).collection('users').snapshots(),
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
        List<DropdownMenuItem<String>> userItems = snapshot.data!.docs
            .map<DropdownMenuItem<String>>((DocumentSnapshot document) {
          Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
          return DropdownMenuItem<String>(
            value: data['uid'], // Use o ID do usuário como valor
            child: Text(data['userName'] ??
                'Usuário sem nome'), // Mostre o nome do usuário
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

              // Chama o callback quando o usuário é selecionado
              if (widget.onUserSelected != null) {
                widget.onUserSelected!(newValue!);
              }
            });
          },
        );
      },
    );
  }
}
