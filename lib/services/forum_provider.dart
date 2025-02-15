/*
  Página do Provider do Forum
  Feito por: Rodrigo abreu Amorim
  Última modificação: 03/12/2024
 */
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app_mensagem/model/forum.dart';
import 'package:app_mensagem/services/auth/forum_service.dart';

final _auth = FirebaseAuth.instance;

class ForumProvider with ChangeNotifier {
  final ForumService _forumService = ForumService();

  final String currentUserId = _auth.currentUser!.uid;

  List<Post> _forums = [];

  List<Post> get getForums => _forums;

  /////////////////
  /// Método para buscar todos os forums do firebase
  Future<void> fetchForums() async {
    try {
      _forums = await _forumService.fetchForums();
      notifyListeners();
      // Retorna os fóruns buscados
    } catch (e) {
      debugPrint("Erro ao buscar fóruns: $e");
      rethrow; // Propaga o erro para o FutureBuilder lidar com ele
    }
  }

  /////////////////
  /// Método para dar like nos posts
  Future<void> likeForum(String forumId) async {
    try {
      await _forumService.likeForum(forumId);
      notifyListeners();
      await fetchForums(); // Atualiza a lista após curtir
      notifyListeners();
    } catch (e) {
      debugPrint("Erro ao curtir fórum: $e");
    }
  }

  /////////////////
  /// Método para dar unlike nos posts
  Future<void> unlikeForum(String forumId) async {
    try {
      await _forumService.unlikeForum(forumId);
      await fetchForums(); // Atualiza a lista após descurtir
    } catch (e) {
      debugPrint("Erro ao descurtir fórum: $e");
    }
  }

  /////////////////
  /// Método para criar posts
  Future<void> createForum(String name, String message) async {
    try {
      await _forumService.createForum(name, message);
      notifyListeners();
      await fetchForums(); // Atualiza a lista após criar
    } catch (e) {
      debugPrint("Erro ao criar fórum: $e");
    }
  }

  /////////////////
  /// Método para atualizar posts
  Future<void> updateForum(
      String forumId, String newName, String newMessage) async {
    try {
      await _forumService.updateForum(forumId, newName, newMessage);
      await fetchForums(); // Atualiza a lista após editar
    } catch (e) {
      debugPrint("Erro ao atualizar fórum: $e");
    }
  }

  /////////////////
  /// Método para excluir posts
  Future<void> deleteForum(String forumId) async {
    try {
      await _forumService.deleteForum(forumId);
      await fetchForums(); // Atualiza a lista após excluir
    } catch (e) {
      debugPrint("Erro ao excluir fórum: $e");
    }
  }
}
