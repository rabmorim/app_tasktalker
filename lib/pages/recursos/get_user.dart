/*
  Classe para pegar o username do usuário
  Feito por: Rodrigo abreu Amorim
  Ultima modificação: 25/11/2024
 */

import 'package:cloud_firestore/cloud_firestore.dart';

class GetUser {
  ////////////////////////////////
  ///Método para pegar o Username do usuário
  Future<String?> getUserName(String userId) async {

    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
        if(userDoc.exists && userDoc.data() != null){
           var data = userDoc.data() as Map<String, dynamic>;
           String? userName = data['userName'];
           if(userName != null){
            return userName;
           }
        }
     return null;
  }
}
