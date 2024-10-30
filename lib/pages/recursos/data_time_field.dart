import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyDateTimeField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;

  const MyDateTimeField({
    super.key,
    required this.controller,
    required this.labelText,
  });

  @override
  // ignore: library_private_types_in_public_api
  _MyDateTimeFieldState createState() => _MyDateTimeFieldState();
}

class _MyDateTimeFieldState extends State<MyDateTimeField> {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  Future<void> _selectDateTime(BuildContext context) async {
    DateTime now = DateTime.now();

    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.grey, // Cor do destaque no calendário
              onPrimary: Colors.white, // Cor do texto na data selecionada
              onSurface: Colors.black, // Cor do texto geral
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      TimeOfDay? selectedTime = await showTimePicker(
        // ignore: use_build_context_synchronously
        context: context,
        initialTime: TimeOfDay.fromDateTime(now),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                primary: Colors.grey, // Cor do destaque no seletor de horas
                onPrimary: Colors.white, // Cor do texto na hora selecionada
                onSurface: Colors.black, // Cor do texto geral
              ),
            ),
            child: child!,
          );
        },
      );

      if (selectedTime != null) {
        final DateTime fullDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        widget.controller.text = _dateFormat.format(fullDateTime);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Size tela = MediaQuery.of(context).size;
    return SizedBox(
      width: tela.width - 60,
      child: TextField(
        controller: widget.controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: widget.labelText,
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        onTap: () => _selectDateTime(context),
      ),
    );
  }
}
