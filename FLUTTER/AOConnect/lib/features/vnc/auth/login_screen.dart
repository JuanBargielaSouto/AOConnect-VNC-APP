import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../devices/device_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final userController = TextEditingController();
  final passController = TextEditingController();

  Future<void> login() async {
    final ip = dotenv.env['DEVICE_IP'];
    final port = dotenv.env['DATABASE_PORT'];
    final url = "http://$ip:$port";
    final response = await http.post(
      Uri.parse("$url/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": userController.text,
        "password": passController.text,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", data["token"]);
      await prefs.setString("role", data["role"]);

      final user = User(
        username: data["username"] ?? "",
        role: data["role"],
        token: data["token"],
      );

      Provider.of<AuthProvider>(context, listen: false).setUser(user);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DeviceScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login incorrecto")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo_aotech.png',
                height: 120,
              ),
              const SizedBox(height: 30),
              TextField(
                controller: userController,
                decoration: const InputDecoration(labelText: "Usuario"),
              ),
              TextField(
                controller: passController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Contraseña"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: login,
                child: const Text("Entrar"),
              )
            ],
          ),
        ),
      ),
    );
  }
}