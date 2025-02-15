/*
  Classe Main
  Feito por: Rodrigo abreu Amorim
  Ultima modificação: 17/12/2024
 */

import 'dart:async';
import 'package:app_mensagem/firebase_options.dart';
import 'package:app_mensagem/pages/recursos/estilo.dart';
import 'package:app_mensagem/pages/recursos/task_notification_manager.dart';
import 'package:app_mensagem/services/auth/auth_gate.dart';
import 'package:app_mensagem/services/auth/auth_service.dart';
import 'package:app_mensagem/services/forum_provider.dart';
import 'package:app_mensagem/services/kanban_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicialize o FlutterLocalNotificationsPlugin para notificações locais
  await TaskNotificationManager().initialize();

  // Inicia o verificador de tarefas periodicamente
  startTaskCheck();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (context) => AuthService(),
      ),
      ChangeNotifierProvider(create: (context) => ForumProvider()),
      ChangeNotifierProvider(create: (context) => KanbanProvider())
    ],
    child: const MyApp(),
  ));
}

// Método para verificar periodicamente se tem tarefas a fazer e realizar a notificação
void startTaskCheck() {
  Timer.periodic(
    const Duration(minutes: 1),
    (timer) {
      TaskNotificationManager().checkAndSendNotifications();
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
      theme: estilo(),
    );
  }
}
