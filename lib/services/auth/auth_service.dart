import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  //Lidar com os diferentes métodos de autenticação(Instancia do firebase_auth)
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  //Instancia do firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //Fazer login do usuário
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password, String userName) async {
    try {
      //login
      UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
              email: email, password: password, userName: userName);

      //adicionando um novo documento users para o usuário na coleção de usuários, se ainda não existir
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'userName': userName
      }, SetOptions(merge: true));

      return userCredential;
    }
    //Detecta os erros
    on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  //Criar novo usuário
  Future<UserCredential> signUpWithEmailAndPassword(
      String email, String password, String userName) async {
    try {
      UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
              email: email, password: password, userName: userName);

      //Depois de criar o usuário, vamos criar um documento para o usuário na coleção
      _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'userName': userName
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // Log out do usuário
  Future<void> signOut() async {
    return await FirebaseAuth.instance.signOut();
  }

// Verificação do usuário
  Future<bool> verifyUser(String username) async {
    CollectionReference users = FirebaseFirestore.instance.collection('users');

    // Garantir que o username não tenha espaços em branco e esteja em minúsculas
    String cleanedUsername = username.trim().toLowerCase();

    QuerySnapshot querySnapshot = await users.get();///

    for (var doc in querySnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      String? storedUsername =
          data?["userName"]?.toString().trim().toLowerCase();

     

      if (storedUsername == cleanedUsername) {
        return true; // Retorna true se encontrar o usuário
      }
    }
    return false; // Se nenhum documento tiver o nome de usuário
  }
}
