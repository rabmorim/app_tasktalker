import 'package:app_mensagem/pages/calendar_page.dart';
import 'package:app_mensagem/pages/form_calendar_page.dart';
import 'package:app_mensagem/pages/home_page.dart';
import 'package:app_mensagem/services/auth/auth_gate.dart';
import 'package:app_mensagem/services/auth/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MenuDrawer extends StatelessWidget {
  MenuDrawer({super.key});

  // Pegando a instância do FirebaseAuth
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  // Pegando a instância do FirebaseFirestore
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    // Variável para armazenar o email do usuário autenticado
    final String accountEmail =
        _firebaseAuth.currentUser?.email ?? 'Unknown Email';

    // Variável para armazenar o userName do usuário autenticado
    Future<String> getUserName() async {
      String uid = _firebaseAuth.currentUser!.uid;
      DocumentSnapshot userDoc =
          await _firebaseFirestore.collection('users').doc(uid).get();
      return userDoc.get('userName') ?? 'Unknown User';
    }

    //método para mostrar o titulo e editar as configurações
    Text mostrarTitulo(String texto) {
      return Text(
        texto,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      );
    }

    //método para mostrar o subtitulo e editar as configurações
    Text mostrarSubTitulo(String texto) {
      return Text(
        texto,
        style: const TextStyle(color: Colors.white54),
      );
    }

    void signOut() {
      // Obter o serviço de autenticação
      final authService = Provider.of<AuthService>(context, listen: false);
      // Aqui você pode chamar o método para fazer o logout
      authService.signOut();
    }

    //Retorna o menu drawer da aplicação
    return Drawer(
      child: ListView(
        //Lógica para pegar o userName e colocar no header
        children: [
          FutureBuilder<String>(
            future: getUserName(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                );
              } else if (snapshot.hasError) {
                return const UserAccountsDrawerHeader(
                  accountName: Text('Error'),
                  accountEmail: Text('Error'),
                );
              } else {
                final String accountName = snapshot.data ?? 'Unknown User';
                return UserAccountsDrawerHeader(
                    accountName: mostrarTitulo(accountName),
                    accountEmail: mostrarSubTitulo(accountEmail),
                    decoration: const BoxDecoration(
                      color: Color(0xff303030),
                    ),);
              }
            },
          ),
          //Ícone Home
          ListTile(
            title: mostrarTitulo('Home'),
            subtitle: mostrarSubTitulo('Página inicial'),
            leading: const Icon(
              Icons.home,
              size: 26,
            ),
            trailing: const Icon(
              Icons.keyboard_arrow_right,
              size: 20,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomePage(),
                ),
              );
            },
          ),

          //Ícone Adicionar no Google Calendar
          ListTile(
            title: mostrarTitulo('Google Calendar'),
            subtitle: mostrarSubTitulo('Adicione tarefas e eventos ao Google Calendar'),
            leading: const Icon(
              Icons.calendar_month,
              size: 26,
            ),
            trailing: const Icon(
              Icons.keyboard_arrow_right,
              size: 20,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FormCalendarWidget(),
                ),
              );
            },
          ),
          //Ícone Calendário Imbutido no flutter
          ListTile(
            title: mostrarTitulo('Calendário'),
            subtitle: mostrarSubTitulo('Traga seus compromissos do Google Calendar'),
            leading: const Icon(
              Icons.calendar_view_month,
              size: 26,
            ),
            trailing: const Icon(
              Icons.keyboard_arrow_right,
              size: 20,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CalendarPage(),
                ),
              );
            },
          ),

          //Ícone logout
          ListTile(
            title: mostrarTitulo('Logout'),
            subtitle: mostrarSubTitulo('Sair'),
            leading: const Icon(
              Icons.logout,
              size: 26,
            ),
            trailing: const Icon(
              Icons.keyboard_arrow_right,
              size: 20,
            ),
            onTap: () {
              signOut();
              MaterialPageRoute(
                  builder: (context) => const AuthGate(),);
            },
          )
        ],
      ),
    );
  }
}
