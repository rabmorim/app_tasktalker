import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app_mensagem/pages/chat_page.dart';

//Pegando a instância do firebase auth
final FirebaseAuth _auth = FirebaseAuth.instance;

class BuildUserList extends StatefulWidget {
  const BuildUserList({super.key});

  @override
  State<BuildUserList> createState() => _BuildUserListState();
}

class _BuildUserListState extends State<BuildUserList> {
  //Fazendo a busca da instância na coleção 'users' na Firestore, tratando possiveis erros , loading e
  //retornando o resultado e transformando em Map no formato de widget
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('error');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          );
        }
        return ListView(
          children: snapshot.data!.docs
              .map<Widget>((doc) => _buildUserListItem(doc))
              .toList(),
        );
      },
    );
  }

  Widget _buildUserListItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data()! as Map<String, dynamic>;

    //Mostrar todos os usuarios exceto o que está presente
    if (_auth.currentUser!.uid != data['uid']) {
      return Column(
        children: [
          const SizedBox(
            height: 5,
          ),
          Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8), color: Colors.grey),
            child: ListTile(
              trailing: const Icon(
                Icons.keyboard_arrow_right,
                size: 20,
              ),
              titleAlignment: ListTileTitleAlignment.center,
              title: Text(data['userName']),
              onTap: () {
                //Vai para a pagina de chat
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      receiverUserEmail: data['email'],
                      receiverUserID: data['uid'],
                      receiverUserName: data['userName'],
                    ),
                  ),
                );
              },
              leading: const Icon(Icons.person),
            ),
          ),
        ],
      );
    } else {
      //Retornar um container em branco
      return const SizedBox();
    }
  }
}
