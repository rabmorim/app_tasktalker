import 'package:app_mensagem/firebase_options.dart';
import 'package:app_mensagem/pages/recursos/estilo.dart';
import 'package:app_mensagem/services/auth/auth_gate.dart';
import 'package:app_mensagem/services/auth/auth_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main () async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(create: (context) => AuthService(), 
    child: const Myapp(),
    )
    );
}

class Myapp extends StatelessWidget{
  const Myapp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
      theme: estilo(),







 






      
    );
  }

}