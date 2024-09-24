import "package:flutter/material.dart";

class MyTextField extends StatelessWidget{
  
  final TextEditingController controller;
  final String labelText;
  final bool obscureText;
  
  const MyTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.obscureText
  });

  @override
  Widget build(BuildContext context) {
    Size tela = MediaQuery.of(context).size;
    return SizedBox(
      width: tela.width-60,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration:   InputDecoration(
        labelText: labelText,
        ),
      ),
    );
  }


}