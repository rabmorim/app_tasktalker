/*
  Classe para Estilização da logo
  Feito por: Rodrigo abreu Amorim
  Ultima modificação: 25/11/2024
 */

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LogoWidget extends StatelessWidget {
  final String titulo;
  const LogoWidget({super.key, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.white, Colors.grey, Color.fromARGB(255, 160, 187, 200)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight)
          .createShader(bounds),
      child: Text(
        titulo,
        style: GoogleFonts.getFont(
          'Fascinate Inline',
          fontSize: 50,
          fontWeight: FontWeight.bold
        ),
      ),
    );
  }
}
