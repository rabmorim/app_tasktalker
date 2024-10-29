import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app_mensagem/pages/chat_page.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class BuildUserList extends StatefulWidget {
  const BuildUserList({super.key});

  @override
  State<BuildUserList> createState() => _BuildUserListState();
}

class _BuildUserListState extends State<BuildUserList> {
  String? _userCompanyCode;

  @override
  void initState() {
    super.initState();
    _fetchUserCompanyCode();
  }

  // Método para buscar o código da empresa do usuário logado
  Future<void> _fetchUserCompanyCode() async {
    try {
      // Obtenha o UID do usuário atual
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      // Consultar a coleção `enterprise` para encontrar o documento que contém o usuário logado na subcoleção `users`
      QuerySnapshot enterpriseSnapshot =
          await FirebaseFirestore.instance.collection('enterprise').get();

      for (var doc in enterpriseSnapshot.docs) {
        var usersCollection = await doc.reference.collection('users').get();

        if (usersCollection.docs
            .any((userDoc) => userDoc.id == currentUserId)) {
          setState(() {
            _userCompanyCode = doc.id; // Armazenar o código da empresa
          });
          break;
        }
      }
    } catch (e) {
      print("Erro ao buscar código da empresa: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userCompanyCode == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('enterprise')
          .doc(_userCompanyCode)
          .collection('users')
          .snapshots(),
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
      return const SizedBox();
    }
  }
}
