/*
  Página Home
  Feito por: Rodrigo abreu Amorim
  Ultima modificação: 25/11/2024
 */

import 'package:app_mensagem/pages/recursos/barra_superior.dart';
import 'package:app_mensagem/pages/recursos/drawer.dart';
import 'package:flutter/material.dart';
import 'package:app_mensagem/pages/recursos/list_users.dart';
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {




  @override
  Widget build(BuildContext context) {
    return  const Scaffold(
      appBar: BarraSuperior(titulo: 'HomePage', isCalendarPage: false,),
      body: BuildUserList(),
      drawer: MenuDrawer(),
    );
  }
}