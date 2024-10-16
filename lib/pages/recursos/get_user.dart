import 'package:cloud_firestore/cloud_firestore.dart';

class GetUser {

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
