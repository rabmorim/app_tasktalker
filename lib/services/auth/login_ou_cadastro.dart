import 'package:app_mensagem/pages/login_page.dart';
import 'package:app_mensagem/pages/register_page.dart';
import 'package:flutter/material.dart';

class LoginOuCadastro extends StatefulWidget {
  const LoginOuCadastro({super.key});

  @override
  State<LoginOuCadastro> createState() => _LoginOuCadastroState();
}

class _LoginOuCadastroState extends State<LoginOuCadastro> {
//mostrar inicialmente a tela de login
bool mostrarLoginPage = true;

//alternar entre login ou registrar-se
void alternarPaginas() {
  setState(() {
     mostrarLoginPage =! mostrarLoginPage;
  });
}

  @override
  Widget build(BuildContext context) {
    if (mostrarLoginPage) {
      return LoginPage(onTap: alternarPaginas);
    } else {
      return Register(onTap: alternarPaginas);
    }
  }
}