/*
  Classe padrão dos text-fields da aplicação
  Feito por: Rodrigo abreu Amorim
  Ultima modificação: 25/11/2024
 */

import "package:flutter/material.dart";
import 'package:flutter/services.dart';

class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final bool obscureText;
  final bool
      isCnpjField;

  const MyTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.obscureText,
    this.isCnpjField = false, // Valor padrão como falso para uso flexível
  });

  @override
  Widget build(BuildContext context) {
    Size tela = MediaQuery.of(context).size;
    return SizedBox(
      width: tela.width - 60,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: isCnpjField ? TextInputType.number : TextInputType.text,
        inputFormatters: isCnpjField
            ? [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(14)
              ]
            : [],
        decoration: InputDecoration(
          labelText: labelText,
        ),
      ),
    );
  }
}
