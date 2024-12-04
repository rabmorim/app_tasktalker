/*
  Página De listagem de Usuários
  Feito por: Rodrigo Abreu Amorim
  Última modificação: 04/12/2024
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app_mensagem/pages/chat_page.dart';
import 'package:flutter_animate/flutter_animate.dart';

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

  //////////////////////////////////
  /// Método para buscar o código da empresa do usuário logado
  Future<void> _fetchUserCompanyCode() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      QuerySnapshot enterpriseSnapshot =
          await FirebaseFirestore.instance.collection('enterprise').get();

      for (var doc in enterpriseSnapshot.docs) {
        var usersCollection = await doc.reference.collection('users').get();

        if (usersCollection.docs
            .any((userDoc) => userDoc.id == currentUserId)) {
          setState(() {
            _userCompanyCode = doc.id;
          });
          break;
        }
      }
    } catch (e) {
      // Log ou mensagem de erro
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
          return const Text('Error');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          );
        }
        final users = snapshot.data!.docs;

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final doc = users[index];
            return _buildUserListItem(doc, index);
          },
        );
      },
    );
  }

  Widget _buildUserListItem(DocumentSnapshot document, int index) {
    Map<String, dynamic> data = document.data()! as Map<String, dynamic>;

    if (_auth.currentUser!.uid != data['uid']) {
      return Column(
        children: [
          const SizedBox(height: 5),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey,
            ),
            child: ListTile(
              trailing: const Icon(
                Icons.keyboard_arrow_right,
                size: 20,
              ),
              titleAlignment: ListTileTitleAlignment.center,
              title: Text(data['userName']),
              leading: const Icon(Icons.person),
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
            ),
          )
              .animate() // Aplica a animação
              .fadeIn(duration: 900.ms, delay: (index * 400).ms)
              .move(begin: const Offset(-100, 0), curve: Curves.easeOutQuad),
        ],
      );
    } else {
      return const SizedBox();
    }
  }
}
