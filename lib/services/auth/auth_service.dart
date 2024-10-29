import 'package:app_mensagem/pages/recursos/task_color_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends ChangeNotifier {
  //Criando uma instãncia da classe de geração de cores
  TaskColorManager colorManager = TaskColorManager();
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
      await _firestore.collection('users').doc(userCredential.user!.uid).set(
        {'uid': userCredential.user!.uid, 'email': email, 'userName': userName},
        SetOptions(merge: true),
      );

      return userCredential;
    }
    //Detecta os erros
    on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  //Criar novo usuário
  Future<UserCredential> signUpWithEmailAndPassword(String email,
      String password, String userName, String codeEnterprise) async {
    try {
      UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
              email: email, password: password, userName: userName);

      // Gerar uma cor aleatória para o usuário
      Color userColor = colorManager.setColorForUser(userCredential.user!.uid);

      // Converter a cor para uma string hexadecimal
      String colorHex =
          '#${userColor.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';

      // Obter o documento da empresa com base no código da empresa
      DocumentSnapshot enterpriseSnapshot =
          await _firestore.collection('enterprise').doc(codeEnterprise).get();

      if (!enterpriseSnapshot.exists) {
        throw Exception('Empresa não encontrada');
      }

      // Criar um novo usuário na subcoleção 'users' dentro da empresa correta
      await _firestore
          .collection('enterprise')
          .doc(codeEnterprise)
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'uid': userCredential.user!.uid,
        'email': email,
        'userName': userName,
        'color': colorHex,
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

// Método para Verificação do usuário
  Future<bool> verifyUser(String username) async {
    CollectionReference users = FirebaseFirestore.instance.collection('users');

    // Garantir que o username não tenha espaços em branco e esteja em minúsculas
    String cleanedUsername = username.trim().toLowerCase();

    QuerySnapshot querySnapshot = await users.get();

    ///

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

  // Método para Verificação do codigo de empresa
  Future<bool> verifyEnterprise(String code) async {
    CollectionReference enterprise =
        FirebaseFirestore.instance.collection('enterprise');

    // Garantir que o código da empresa não tenha espaços em branco e esteja em minúsculas
    String cleanedEnterprise = code.trim().toLowerCase();

    QuerySnapshot querySnapshot = await enterprise.get();

    ///

    for (var doc in querySnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      String? storedEnterprise = data?["code"]?.toString().trim().toLowerCase();

      if (storedEnterprise == cleanedEnterprise) {
        return true; // Retorna true se encontrar a empresa
      }
    }
    return false; // Se não tiver a empresa
  }

  //Método usado para conectar-se com a conta do google
  Future connectGoogleAccount() async {
    String validou = 'Google Conectado com Sucesso.';
    String invalidou = 'Erro ao conectar ao google';

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: <String>[
          'https://www.googleapis.com/auth/calendar',
          'https://www.googleapis.com/auth/calendar.events',
        ],
      );

      // Deslogar usuário atual para garantir uma nova autenticação
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? accessToken = googleAuth.accessToken;

      if (accessToken != null) {
        // Salvar o token no Firestore sob o documento do usuário atual
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(
            {'googleAccessToken': accessToken},
            SetOptions(merge: true),
          );
        }
        return validou;
      }
    } catch (error) {
      return invalidou;
    }
  }
}
