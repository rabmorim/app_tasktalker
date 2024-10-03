import 'package:app_mensagem/pages/recursos/barra_superior.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ConnectGooglePage extends StatefulWidget {
  const ConnectGooglePage({super.key});

  @override
  State<ConnectGooglePage> createState() => _ConnectGooglePageState();
}

class _ConnectGooglePageState extends State<ConnectGooglePage> {
  bool isLoading = false;

  Future<void> connectGoogleAccount() async {
    setState(() {
      isLoading = true;
    });

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: <String>[
          'https://www.googleapis.com/auth/calendar',
          'https://www.googleapis.com/auth/calendar.events',
        ],
      );

      // Deslogar o usuário atual para garantir uma nova autenticação
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // Usuário cancelou o login
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Obtenha o accessToken e o refreshToken diretamente (GoogleSignIn já faz isso para Android)
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? accessToken = googleAuth.accessToken;
      final String? refreshToken =
          googleAuth.idToken; // Usamos o idToken como refreshToken

      if (accessToken != null) {
        // Obter tempo de expiração do token (geralmente 1 hora)
        const int expiresIn = 3600;
        final DateTime expiryDate =
            DateTime.now().add(const Duration(seconds: expiresIn));

        // Salvar os tokens no Firestore sob o documento do usuário atual
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'googleAccessToken': accessToken,
            'googleRefreshToken': refreshToken,
            'tokenExpiryDate': expiryDate.toIso8601String(),
          }, SetOptions(merge: true));

          // Notificação de sucesso
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Google Calendar conectado com sucesso!'),
            ),
          );
        }
      }
    } catch (error) {
      // Tratamento de erro
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao conectar com Google Calendar: $error'),
        ),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  // Método para checar e renovar o access token
  Future<String?> _getValidAccessToken() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        final String? accessToken = data?['googleAccessToken'];
        final String? refreshToken = data?['googleRefreshToken'];
        final String? expiryDateString = data?['tokenExpiryDate'];

        if (accessToken != null &&
            refreshToken != null &&
            expiryDateString != null) {
          final DateTime expiryDate = DateTime.parse(expiryDateString);

          // Verifique se o token expirou
          if (DateTime.now().isAfter(expiryDate)) {
            // Token expirou, renove o token usando o refresh_token
            final newAccessToken = await _refreshAccessToken(refreshToken);
            return newAccessToken; // Retorna o novo access token
          } else {
            // Token ainda é válido
            return accessToken;
          }
        }
      }
    }

    return null;
  }

  // Método para renovar o token usando o refresh token
  Future<String?> _refreshAccessToken(String refreshToken) async {
    final Uri tokenUri = Uri.parse('https://oauth2.googleapis.com/token');

    final response = await http.post(tokenUri, body: {
      'client_id':
          '217184069177-5b2jctb7scvgafrtco4u9j4qok18kgdu.apps.googleusercontent.com', // Seu Client ID
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken,
    });

    if (response.statusCode == 200) {
      final tokens = json.decode(response.body);
      final String newAccessToken = tokens['access_token'];
      final int expiresIn = tokens['expires_in'];
      final DateTime expiryDate = DateTime.now().add(
        Duration(seconds: expiresIn),
      );

      // Atualizar os tokens e a data de expiração no Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'googleAccessToken': newAccessToken,
          'tokenExpiryDate': expiryDate.toIso8601String(),
        });
      }

      return newAccessToken;
    } else {
      return null;
    }
  }

  // Exemplo de como utilizar o _getValidAccessToken antes de uma requisição
  Future<void> _makeGoogleApiRequest() async {
    final accessToken = await _getValidAccessToken();

    if (accessToken != null) {
      // Agora você pode fazer sua requisição à API do Google usando o accessToken válido
      final Uri calendarUri = Uri.parse(
          'https://www.googleapis.com/calendar/v3/calendars/primary/events');

      final response = await http.get(calendarUri, headers: {
        'Authorization': 'Bearer $accessToken',
      });

      if (response.statusCode == 200) {
        // Processar a resposta da API
        if (kDebugMode) {
          print('Eventos do calendário: ${response.body}');
        }
      } else {
        if (kDebugMode) {
          print('Erro ao acessar a API: ${response.statusCode}');
        }
      }
    } else {
      if (kDebugMode) {
        print('Não foi possível obter um access token válido.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BarraSuperior(
          titulo: 'Conectar ao Google', isCalendarPage: false),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white54)
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                ElevatedButton(
                  onPressed: () {
                    connectGoogleAccount;
                    _makeGoogleApiRequest;
                  },
                  child: const Text(
                    'Conectar com Google',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ]),
      ),
    );
  }
}
