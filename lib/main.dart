import 'dart:async';

import 'package:app_mensagem/firebase_options.dart';
import 'package:app_mensagem/pages/recursos/estilo.dart';
import 'package:app_mensagem/pages/recursos/task_notification_manager.dart';
import 'package:app_mensagem/services/auth/auth_gate.dart';
import 'package:app_mensagem/services/auth/auth_service.dart';
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

  runApp(ChangeNotifierProvider(
    create: (context) => AuthService(),
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
