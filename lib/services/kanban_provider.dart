/*
  Página do provider do kanban
  Feito por: Rodrigo abreu Amorim
  Ultima modificação: 17/12/2024
 */
import 'package:flutter/material.dart';

class KanbanProvider with ChangeNotifier {
  bool _isEditingColumns = false;
  bool get isEditingColumns => _isEditingColumns;

///////////////////////////////////
  /// Método para mudar o valor da variavel edição de colunas e gerenciar seu estado
  void toggleEditingColumns() {
    _isEditingColumns = !_isEditingColumns;
    notifyListeners();
  }
  
}
