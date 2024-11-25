/*
  Classe para gerenciamento das notificações
  Feito por: Rodrigo abreu Amorim
  Ultima modificação: 25/11/2024
 */

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class TaskNotificationManager {
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  TaskNotificationManager() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  }

  /////////////////////////
  /// Método para inicializar as configurações de notificações
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

  ///////////////////////////
  /// Método para verificar tarefas e enviar notificações
  Future<void> checkAndSendNotifications() async {
    // Pega o usuário autenticado
    final String currentUser = FirebaseAuth.instance.currentUser!.uid;

    //Pega o código da empresa do usuário cadastrado
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser)
        .get();
    if (userDoc.exists) {
      String enterpriseCode = userDoc['code'];
      // Consulta as tarefas do Firestore
      var snapshot = await FirebaseFirestore.instance
          .collection('enterprise')
          .doc(enterpriseCode)
          .collection('tasks')
          .get();
      var now = DateTime.now();

      // Percorre todas as tarefas do usuário
      for (var doc in snapshot.docs) {
        var taskData = doc.data();
        if (taskData['assigned_to'] == currentUser) {
          DateTime taskStartTime = DateTime.parse(taskData['start_time']);

          // Se a tarefa ainda não começou e está dentro do tempo de 5 minutos
          if (taskStartTime.isAfter(now) &&
              taskStartTime.difference(now).inMinutes >= 4 &&
              taskStartTime.difference(now).inMinutes < 5) {
            showNotification(
                taskData['title'], taskData['description'], taskStartTime);
          }
        } else {
          return ;
        }
      }
    }
  }

  ///////////////////////////////
  /// Método para exibir a notificação
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
