import 'package:app_mensagem/pages/calendar_page.dart';
import 'package:app_mensagem/pages/google_conection.dart';
import 'package:app_mensagem/pages/home_page.dart';
import 'package:app_mensagem/pages/user_task_list.dart';
import 'package:app_mensagem/services/auth/auth_gate.dart';
import 'package:app_mensagem/services/auth/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

class MenuDrawer extends StatefulWidget {
  const MenuDrawer({super.key});

  @override
  State<MenuDrawer> createState() => _MenuDrawerState();
}

class _MenuDrawerState extends State<MenuDrawer> {
  // Pegando a instância do FirebaseAuth
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Pegando a instância do FirebaseFirestore
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  // Variável de controle de estado dos botões
  bool isLoggedInWithGoogle = false;

  @override
  void initState() {
    super.initState();
    checkGoogleLogin();
  }

  void checkGoogleLogin() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Verifica se o usuário está logado com o Google
      final googleUser = await GoogleSignIn().isSignedIn();
      setState(() {
        isLoggedInWithGoogle = googleUser;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Variável para armazenar o email do usuário autenticado
    final String accountEmail =
        _firebaseAuth.currentUser?.email ?? 'Unknown Email';

    ///////////////////////////////////
    /// Método para armazenar o userName do usuário autenticado
    Future<String> getUserName() async {
      String uid = _firebaseAuth.currentUser!.uid;
      DocumentSnapshot userDoc =
          await _firebaseFirestore.collection('users').doc(uid).get();
      return userDoc.get('userName') ?? 'Unknown User';
    }

    ///////////////////////////////
    /// Método para mostrar o título e editar as configurações
    Text mostrarTitulo(String texto) {
      return Text(
        texto,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      );
    }

    ////////////////////////////////
    /// Método para mostrar o subtítulo e editar as configurações
    Text mostrarSubTitulo(String texto) {
      return Text(
        texto,
        style: const TextStyle(color: Colors.white54),
      );
    }
     ///////////////////////////////////////
     ///Método para realizar o logout.
    void signOut() {
      // Obter o serviço de autenticação
      final authService = Provider.of<AuthService>(context, listen: false);
      // Aqui você pode chamar o método para fazer o logout
      authService.signOut();
    }

    return Drawer(
      child: ListView(
        // Lógica para pegar o userName e colocar no header
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
                  ),
                );
              }
            },
          ),

          // Exibir apenas o botão de login se o usuário não estiver logado
          if (!isLoggedInWithGoogle) ...[
            // Ícone de Logar com o Google 
            ListTile(
              title: mostrarTitulo('Conectar ao Google'),
              subtitle: mostrarSubTitulo(
                  'Conecte ao google para utilizar as funcionalidades do app'),
              leading: const FaIcon(
                FontAwesomeIcons.google,
                size: 24,
              ),
              trailing: const Icon(
                Icons.keyboard_arrow_right,
                size: 20,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ConnectGooglePage(),
                  ),
                );
              },
            ),
            // Ícone logout
            ListTile(
              title: mostrarTitulo('Logout'),
              subtitle: mostrarSubTitulo('Sair'),
              leading: const FaIcon(
                FontAwesomeIcons.rightFromBracket,
                size: 24,
              ),
              trailing: const Icon(
                Icons.keyboard_arrow_right,
                size: 20,
              ),
              onTap: () {
                signOut();
                MaterialPageRoute(
                  builder: (context) => const AuthGate(),
                );
              },
            ),
          ] else ...[
            // Exibir os outros botões somente após o login com o Google
            ListTile(
              title: mostrarTitulo('Home'),
              subtitle: mostrarSubTitulo('Página inicial'),
              leading: const FaIcon(
                FontAwesomeIcons.house,
                size: 24,
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
            // Ícone Calendário 
            ListTile(
              title: mostrarTitulo('Calendário'),
              subtitle: mostrarSubTitulo(
                  'Veja seus Compromissos'),
              leading: const FaIcon(
                FontAwesomeIcons.calendarDays,
                size: 24,
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

            // Ícone Tarefas
            ListTile(
              title: mostrarTitulo('Tarefas'),
              subtitle: mostrarSubTitulo('Minhas Tarefas'),
              leading: const FaIcon(
                FontAwesomeIcons.barsProgress,
                size: 24,
              ),
              trailing: const Icon(
                Icons.keyboard_arrow_right,
                size: 20,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserTaskList(),
                  ),
                );
              },
            ),
            // Ícone logout
            ListTile(
              title: mostrarTitulo('Logout'),
              subtitle: mostrarSubTitulo('Sair'),
              leading: const FaIcon(
                FontAwesomeIcons.rightFromBracket,
                size: 24,
              ),
              trailing: const Icon(
                Icons.keyboard_arrow_right,
                size: 20,
              ),
              onTap: () {
                signOut();
                MaterialPageRoute(
                  builder: (context) => const AuthGate(),
                );
              },
            ),
          ]
        ],
      ),
    );
  }
}
