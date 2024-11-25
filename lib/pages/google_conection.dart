/*
  Página para se conectar com o google
  Feito por: Rodrigo abreu Amorim
  Ultima modificação: 25/11/2024
 */

import 'package:app_mensagem/pages/recursos/barra_superior.dart';
import 'package:app_mensagem/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class ConnectGooglePage extends StatefulWidget {
  const ConnectGooglePage({super.key});

  @override
  State<ConnectGooglePage> createState() => _ConnectGooglePageState();
}

class _ConnectGooglePageState extends State<ConnectGooglePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: const BarraSuperior(
            titulo: 'Conecte ao Google', isCalendarPage: false),
        body: Center(
          child:
               ElevatedButton(
                  style: const ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Colors.red),
                    fixedSize: WidgetStatePropertyAll(
                      Size(280, 50),
                    ),
                  ),
                  onPressed: () {
                    connectionGoogle();
                  },
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

  ///////////////////////
  ///Método para conectar a conta do google
  Future connectionGoogle() async {
    //Primeiro obter o serviço de autenticação
    final authService = Provider.of<AuthService>(context, listen: false);
    String resposta;
    try {
      resposta = await authService.connectGoogleAccount();
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resposta),
        ),
      );
    } catch (e) {
      //ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          e.toString(),
        ),
      );
    }
  }
}
