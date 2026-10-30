import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  Future<void> updatePassword() async {
    final password = passCtrl.text;

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mínimo 6 caracteres")),
      );
      return;
    }

    if (password != confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Las contraseñas no coinciden")),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final ip = dotenv.env['DEVICE_IP'];
    final port = dotenv.env['DATABASE_PORT'];
    final url = "http://$ip:$port";

    final response = await http.put(
      Uri.parse("$url/user/profile"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      },
      body: jsonEncode({
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("token");

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        "/login",
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cambiar contraseña")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Nueva contraseña"),
            ),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              decoration:
              const InputDecoration(labelText: "Confirmar contraseña"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: updatePassword,
              child: const Text("Actualizar"),
            ),
          ],
        ),
      ),
    );
  }
}