import 'package:app_mensagem/pages/recursos/button.dart';
import 'package:app_mensagem/pages/recursos/logo.dart';
import 'package:app_mensagem/pages/recursos/text_field.dart';
import 'package:app_mensagem/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  final void Function()? onTap;
  const LoginPage({super.key, required this.onTap});

  @override
  State<StatefulWidget> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  //Text controllers
  final userName = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  //Logar
  void login() async {
    
    //Primeiro obter o serviço de autenticação
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      await authService.signInWithEmailAndPassword(
          emailController.text, passwordController.text, userName.text);
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //Espaçamento
                const SizedBox(height: 65),
                //Mensagem de bem vindo
                const Text(
                  "Bem vindo ao ",
                  style: TextStyle(
                      color: Colors.white54,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: BorderSide.strokeAlignInside),
                ),
                //Nome do App
                const LogoWidget(titulo: 'TaskTalker'),
                //Espaçamento
                const SizedBox(height: 25),

                const SizedBox(height: 25),

                //Nome do usuário textfield
                MyTextField(
                    controller: userName,
                    labelText: 'Nome do Usuário',
                    obscureText: false),

                //Espaçamento
                const SizedBox(height: 20),

                //email textfield
                MyTextField(
                    controller: emailController,
                    labelText: 'Email',
                    obscureText: false),

                //Espaçamento
                const SizedBox(height: 20),

                //senha textfield
                MyTextField(
                    controller: passwordController,
                    labelText: 'Senha',
                    obscureText: true),

                //Espaçamento
                const SizedBox(height: 20),

                // logar button
                MyButton(
                    onTap: () {
                      login();
                    },
                    text: "Login"),

                const SizedBox(height: 20),
                // Registra-se

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: widget.onTap,
                      child: const Text(
                        "Cadastre-se",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
