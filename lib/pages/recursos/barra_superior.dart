import 'package:app_mensagem/services/auth/auth_gate.dart';
import 'package:app_mensagem/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class BarraSuperior extends StatefulWidget implements PreferredSizeWidget {
  final String titulo;
  final bool isCalendarPage;
  final void Function(CalendarFormat)? onFormatChanged; // Função de callback para mudança de visualização

  const BarraSuperior({
    super.key,
    required this.titulo,
    required this.isCalendarPage,
    this.onFormatChanged, // Adiciona a função de callback
  });

  @override
  State<BarraSuperior> createState() => _BarraSuperiorState();

  @override
  Size get preferredSize => const Size.fromHeight(56.0);
}

class _BarraSuperiorState extends State<BarraSuperior> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Center(
        child: Text(
          widget.titulo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: BorderSide.strokeAlignCenter,
            color: Colors.white54,
          ),
        ),
      ),
      actions: widget.isCalendarPage
          ? [
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white54),
                onPressed: () {
                  // Mostra o ModalBottomSheet para escolher a visualização
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          ListTile(
                            leading: const Icon(Icons.calendar_today),
                            title: const Text('Mensal'),
                            onTap: () {
                              Navigator.pop(context);
                              widget.onFormatChanged?.call(CalendarFormat.month);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.view_week),
                            title: const Text('Semanal'),
                            onTap: () {
                              Navigator.pop(context);
                              widget.onFormatChanged?.call(CalendarFormat.week);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.view_module),
                            title: const Text('Duas Semanas'),
                            onTap: () {
                              Navigator.pop(context);
                              widget.onFormatChanged?.call(CalendarFormat.twoWeeks);
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ]
          : [
              IconButton(
                onPressed: () {
                  signOut();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const AuthGate(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.logout,
                  color: Colors.white54,
                ),
              ),
            ],
      automaticallyImplyLeading: true,
      backgroundColor: const Color(0xff212121),
    );
  }
  ////////////////////////////////
  ///Método para fazer logout
  void signOut() {
    final authService = Provider.of<AuthService>(context, listen: false);
    authService.signOut();
  }
}
