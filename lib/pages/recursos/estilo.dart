import 'package:flutter/material.dart';


ThemeData estilo() {
  ThemeData base = ThemeData.dark();

  return base.copyWith(
      colorScheme: const ColorScheme.dark(),

      scaffoldBackgroundColor: const Color(0xff303030),

      inputDecorationTheme: const InputDecorationTheme(
        
        enabledBorder: 
            OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
              borderRadius: BorderRadius.all(Radius.circular(9))
              ),
        focusedBorder:  
            OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white54),
              borderRadius: BorderRadius.all(Radius.circular(9))
              ),
        fillColor:  Color.fromARGB(255, 93, 91, 91),
        filled: true,
        labelStyle:  TextStyle(color: Colors.white)
      ),

        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.white
      ),
    );
}
