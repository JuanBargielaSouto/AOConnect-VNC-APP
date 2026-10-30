import 'package:flutter/material.dart';

Future<bool> confirmDelete(BuildContext context, String message) async {
  return await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Confirmar"),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Eliminar"),
        ),
      ],
    ),
  ) ??
      false;
}