/*
  Página do Provider do Forum
  Feito por: Rodrigo abreu Amorim
  Última modificação: 27/11/2024
 */
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app_mensagem/model/forum.dart';
import 'package:app_mensagem/services/auth/forum_service.dart';
final _auth = FirebaseAuth.instance;

class ForumProvider with ChangeNotifier {
  final ForumService _forumService = ForumService();
  
  final String currentUserId =_auth.currentUser!.uid;


      

  List<Post> _forums = [];

  List<Post> get forums => _forums;

  Future<List<Post>> fetchForums() async {
    try {
      _forums = await _forumService.fetchForums();
      notifyListeners();
      return _forums; // Retorna os fóruns buscados
    } catch (e) {
      debugPrint("Erro ao buscar fóruns: $e");
      rethrow; // Propaga o erro para o FutureBuilder lidar com ele
    }
  }

  Future<void> likeForum(String forumId) async {
    try {
      await _forumService.likeForum(forumId);
      notifyListeners();
      await fetchForums(); // Atualiza a lista após curtir
    } catch (e) {
      debugPrint("Erro ao curtir fórum: $e");
    }
  }

  Future<void> unlikeForum(String forumId) async {
    try {
      // await _forumService.unlikeForum(forumId);
      await fetchForums(); // Atualiza a lista após descurtir
    } catch (e) {
      debugPrint("Erro ao descurtir fórum: $e");
    }
  }

  Future<void> createForum(String name, String message) async {
    try {
      await _forumService.createForum(name, message);
      await fetchForums(); // Atualiza a lista após criar
    } catch (e) {
      debugPrint("Erro ao criar fórum: $e");
    }
  }
}
