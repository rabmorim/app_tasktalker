import 'package:app_mensagem/pages/recursos/task_color_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:googleapis_auth/auth_io.dart';

class AuthService extends ChangeNotifier {
  Future credentials() async {
    //Pegando as chaves de acesso de forma segura e privada
    QuerySnapshot<Map<String, dynamic>> keySnapshot =
        await FirebaseFirestore.instance.collection('key').get();
    var keyDoc = keySnapshot.docs;
    // Pegando as chaves do Firestore
    String privateKey = keyDoc[0]['private_key'];
    privateKey = privateKey.replaceAll("\\\\n", "\n");
    String privateKeyId = keyDoc[1]['private_key_id'];
    //Configuração para autenticação da conta de serviço
    final credentials = ServiceAccountCredentials.fromJson('''
  {
    "type": "service_account",
    "project_id": "chatapp-f6349",
    "private_key_id": "$privateKeyId",
    "private_key": "${privateKey.replaceAll('\n', '\\n')}",
    "client_email": "firebase-adminsdk-uqeoc@chatapp-f6349.iam.gserviceaccount.com",
    "client_id": "109927196779049391016",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-uqeoc%40chatapp-f6349.iam.gserviceaccount.com",
    "universe_domain": "googleapis.com"
  }
  ''');

    return credentials;
  }

  //Criando uma instãncia da classe de geração de cores
  TaskColorManager colorManager = TaskColorManager();
  //Lidar com os diferentes métodos de autenticação(Instancia do firebase_auth)
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  //Instancia do firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ////////////////////
  /// Método para fazer login do usuário
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

  //////////////////////////
  /// Método para criar novo usuário
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
      DocumentSnapshot enterpriseSnapshot = await _firestore
          .collection('enterprise')
          .doc(codeEnterprise.toLowerCase())
          .get();

      if (!enterpriseSnapshot.exists) {
        throw Exception('Empresa não encontrada');
      }

      // Criar um novo usuário na subcoleção 'users' dentro da empresa correta
      await _firestore
          .collection('enterprise')
          .doc(codeEnterprise.toLowerCase())
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'uid': userCredential.user!.uid,
        'email': email,
        'userName': userName,
        'color': colorHex,
      });

      //Cria o usuário também na coleçao global 'users'
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'userName': userName,
        'color': colorHex,
        'code': codeEnterprise.toLowerCase()
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  ////////////////////////
  /// Método  Log out do usuário
  Future<void> signOut() async {
    return await FirebaseAuth.instance.signOut();
  }

  /////////////////////////
  /// Método para Verificação do usuário
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

  //////////////////////
  /// Método para Verificação do codigo de empresa
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

  ///////////////////
  /// Método usado para conectar-se com a conta do google
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

  //////////////////////////////
  /// Método para adicionar o calendário da empresa ao usuário cadastrado naquela empresa
  Future<void> addUserToCalendarACL(
      {required String companyCode, required String userEmail}) async {
    final credentialss = await credentials();
    // Obter token de autenticação
    var client = await clientViaServiceAccount(
        credentialss, [CalendarApi.calendarScope]);

    // Iniciar API Calendar
    var calendar = CalendarApi(client);

    // Obter o ID do calendário com base no código da empresa
    String calendarId = await getCalendarIdFromCompanyCode(companyCode);

    // Adicionar o e-mail ao ACL do calendário e adiciona regras de leitura, adição e exclusão de eventos no calendário
    var rule = AclRule(
      scope: AclRuleScope(
        type: "user",
        value: userEmail,
      ),
      role: "owner",
    );

    await calendar.acl.insert(rule, calendarId);
  }

  ////////////////////////////
  /// Método para obter o ID do calendário
  Future<String> getCalendarIdFromCompanyCode(String companyCode) async {
    String calendarId = '';

    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('enterprise').get();

    List<Map<String, dynamic>> enterprise =
        snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    for (var document in enterprise) {
      String enterpriseCode = document['code'];
      if (enterpriseCode == companyCode) {
        calendarId = document['calendar_id'];
      }
    }
    return calendarId;
  }

  ///////////////////
  ///  Método para editar um evento no firestore
  Future<void> editEvent({
    required String eventId,
    required String companyId,
    required Map<String, dynamic> updatedData,
  }) async {
    try {
      await _firestore
          .collection('enterprise')
          .doc(companyId)
          .collection('tasks')
          .doc(eventId)
          .update(updatedData);
    } catch (e) {
      rethrow; // Relança o erro para tratamento externo
    }
  }

  ///////////////////////
  /// Método para Excluir um evento do Firestore
  Future<void> deleteEvent({
    required String eventId,
    required String companyId,
  }) async {
    try {
      await _firestore
          .collection('enterprise')
          .doc(companyId)
          .collection('tasks')
          .doc(eventId)
          .delete();
    } catch (e) {
      rethrow; // Relança o erro para tratamento externo
    }
  }
}
