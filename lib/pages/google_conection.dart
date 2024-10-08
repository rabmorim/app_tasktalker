import 'package:app_mensagem/pages/recursos/barra_superior.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

      // Deslogar usuário atual para garantir uma nova autenticação
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // Usuário cancelou o login
        setState(() {
          isLoading = false;
        });
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
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Google Calendar conectado com sucesso!')),
          );
        }
      }
    } catch (error) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao conectar com Google Calendar: $error')),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: const BarraSuperior(
            titulo: 'Conecte ao Google', isCalendarPage: false),
        body: Center(
          child: isLoading
              ? const CircularProgressIndicator(
                  color: Colors.white54,
                )
              : ElevatedButton(
                  style: const ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Colors.red),
                    fixedSize: WidgetStatePropertyAll(
                      Size(280, 50),
                    ),
                  ),
                  onPressed: connectGoogleAccount,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(
                        FontAwesomeIcons.google,
                        color: Colors.white,
                      ),
                      SizedBox(
                        width: 20,
                      ),
                      Text(
                        'Logar com o Google',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2),
                      )
                    ],
                  ),
                ),
        ));
  }
}
