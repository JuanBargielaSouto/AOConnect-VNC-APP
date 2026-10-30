import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../providers/auth_provider.dart';

import '../admin/assign_devices_screen.dart';
import '../widgets/confirm_delete.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List users = [];

  Future<void> loadUsers() async {
    final ip = dotenv.env['DEVICE_IP'];
    final port = dotenv.env['DATABASE_PORT'];
    final url = "http://$ip:$port";
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.get(
      Uri.parse("$url/admin/users"),
      headers: {"Authorization": "Bearer $token"},
    );

    setState(() {
      users = jsonDecode(response.body);
    });
  }

  Future<void> createUser(String username, String password, String role) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final ip = dotenv.env['DEVICE_IP'];
    final port = dotenv.env['DATABASE_PORT'];
    final url = "http://$ip:$port";

    final response = await http.post(
      Uri.parse("$url/admin/users"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      },
      body: jsonEncode({
        "username": username,
        "password": password,
        "role": role
      }),
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuario creado")),
      );
      loadUsers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.body)),
      );
    }
    loadUsers();
  }

  Future<void> deleteUser(int id) async {
    final ip = dotenv.env['DEVICE_IP'];
    final port = dotenv.env['DATABASE_PORT'];
    final url = "http://$ip:$port";
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    await http.delete(
      Uri.parse("$url/admin/users/$id"),
      headers: {"Authorization": "Bearer $token"},
    );

    loadUsers();
  }

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  void showCreateUserDialog() {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    String role = "user";

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Crear usuario"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: userCtrl,
                    decoration: const InputDecoration(labelText: "Usuario"),
                  ),
                  TextField(
                    controller: passCtrl,
                    decoration: const InputDecoration(labelText: "Contraseña"),
                  ),
                  const SizedBox(height: 10),

                  // 👇 DROPDOWN ARREGLADO
                  DropdownButton<String>(
                    value: role,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: "user", child: Text("User")),
                      DropdownMenuItem(value: "admin", child: Text("Admin")),
                    ],
                    onChanged: (value) {
                      setStateDialog(() {
                        role = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    final username = userCtrl.text.trim();
                    final password = passCtrl.text;

                    if (username.length < 4) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Usuario mínimo 4 caracteres")),
                      );
                      return;
                    }

                    if (password.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Contraseña mínimo 6 caracteres")),
                      );
                      return;
                    }

                    createUser(username, password, role);

                    Navigator.pop(context);
                  },
                  child: const Text("Crear"),
                )
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().role;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel de Administración"),
        actions: [
          IconButton(
            tooltip: "Añadir usuario",
            icon: const Icon(Icons.add),
            onPressed: showCreateUserDialog,
          )
        ],
      ),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (_, i) {
          final u = users[i];

          return ListTile(
            title: Text(u["username"]),
            subtitle: Text("Rol: ${u["role"]}"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AssignDevicesScreen(
                    userId: u["id"],
                    username: u["username"],
                  ),
                ),
              );
            },
            trailing: role == "boss"
                ? IconButton(
              tooltip: "Eliminar usuario",
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirm = await confirmDelete(
                  context,
                  "¿Seguro que quieres eliminar a ${u["username"]}?",
                );

                if (confirm) {
                  deleteUser(u["id"]);
                }
              },
            )
                : null,
          );
        },
      ),
    );
  }
}