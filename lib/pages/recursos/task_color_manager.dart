import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TaskColorManager {
  final Map<String, Color> _userColors = {};

  // Gera cor aleatória
  Color getRandomColor() {
    Random random = Random();
    return Color.fromARGB(
      150, // Opacidade
      random.nextInt(256), // Red
      random.nextInt(256), // Green
      random.nextInt(256), // Blue
    );
  }

  // Associa uma cor a um UID, se ainda não existir
  Color setColorForUser(String uid) {
    if (!_userColors.containsKey(uid)) {
      _userColors[uid] = getRandomColor(); // Gera cor e associa ao UID
    }
    return _userColors[uid]!;
  }

  // busca a cor associada ao usuário da tarefa
  Future<Color?> getUserColor(String userId) async {
    // Tenta buscar o documento do usuário
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    // Verifica se o documento existe e se contém o campo "color"
    if (userDoc.exists && userDoc.data() != null) {
      var data = userDoc.data() as Map<String, dynamic>;
      String? colorHex = data['color'];

      if (colorHex != null) {
        // Converte o código hexadecimal de volta para um objeto Color
        Color userColor =
            Color(int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);
        return userColor;
      }
    }
    return null; // Caso o documento não exista ou não tenha a cor
  }
}