/*
  Botões feitos da aplicação
  Feito por: Rodrigo abreu Amorim
  Ultima modificação: 25/11/2024
 */
import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final void Function() ? onTap;
  final String text;
  const MyButton({
    super.key,
      required this.onTap,
      required this.text
    }
    );

  @override
  Widget build(BuildContext context) {
    Size tela = MediaQuery.of(context).size;
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            height: 55,
            width: tela.width-60,
            padding: const EdgeInsets.all(9),
            decoration:  const BoxDecoration(
                color: Colors.white54,
                borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: Center(
              child: Text(
                textAlign: TextAlign.center,
                text,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white
                ),
                ),
            ),
          ),
        
        );
      }
    );
  }
  
}