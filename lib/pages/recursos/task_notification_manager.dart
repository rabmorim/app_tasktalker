import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class TaskNotificationManager {
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  TaskNotificationManager() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  }

  // Método para inicializar as configurações de notificações
  Future<void> initialize() async {
    // Configurações para Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(
            '@mipmap/ic_launcher'); // Ícone da notificação

    // Inicialização do plugin com as configurações de Android
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    // Inicializa o plugin de notificação
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
  }

  // Função para verificar tarefas e enviar notificações
  Future<void> checkAndSendNotifications() async {
    // Pega o usuário autenticado
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      String userId = currentUser.uid;

      // Consulta as tarefas do Firestore
      var snapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('assigned_to', isEqualTo: userId)
          .get();

      var now = DateTime.now();

      // Percorre todas as tarefas do usuário
      for (var doc in snapshot.docs) {
        var taskData = doc.data();
        DateTime taskStartTime = DateTime.parse(taskData['start_time']);

        // Se a tarefa ainda não começou e está dentro do tempo de 5 minutos
        if (taskStartTime.isAfter(now) &&
            taskStartTime.difference(now).inMinutes <= 2) {
          showNotification(
              taskData['title'], taskData['description'], taskStartTime);
        }
      }
    }
  }

  // Função para exibir a notificação
  Future<void> showNotification(
      String title, String description, DateTime startTime) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'channel_id', // ID do canal de notificação
      'Task Notifications', // Nome do canal
      channelDescription: 'Notificações para tarefas a fazer',
      importance: Importance.max, // Alta importância
      priority: Priority.high, // Alta prioridade
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0, // ID da notificação
      title, // Título da notificação
      '$description às ${startTime.hour}:${startTime.minute}', // Corpo da notificação
      notificationDetails,
    );
  }
}
