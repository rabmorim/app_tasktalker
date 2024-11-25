/*
  Modelo Do balão do chat
  Feito por: Rodrigo abreu Amorim
  Ultima modificação: 25/11/2024
 */

import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 16
        ),
      ),
    );
  }
}
