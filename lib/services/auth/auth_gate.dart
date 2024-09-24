import 'package:app_mensagem/pages/home_page.dart';
import 'package:app_mensagem/services/auth/login_ou_cadastro.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(), 
        builder: (context, snapshot){
          //usuario está logado
          if(snapshot.hasData){
            return const HomePage();
          }
          //usuario não está logado
          else{
            return const LoginOuCadastro();
          }
        },
        ),
    );
  }
}