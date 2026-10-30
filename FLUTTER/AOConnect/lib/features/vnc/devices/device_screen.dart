import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../admin/admin_screen.dart';
import '../vnc_screen.dart';
import '../profile/change_password_screen.dart';
import '../widgets/confirm_delete.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  List devices = [];
  String role = "";

  Future<void> loadDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final ip = dotenv.env['DEVICE_IP'];
    final port = dotenv.env['DATABASE_PORT'];
    final url = "http://$ip:$port";

    role = prefs.getString("role") ?? "";

    final response = await http.get(
      Uri.parse("$url/devices"),
      headers: {"Authorization": "Bearer $token"},
    );

    setState(() {
      devices = jsonDecode(response.body);
    });
  }

  Future<void> addDevice(String newName, String newIp) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final ip = dotenv.env['DEVICE_IP'];
    final port = dotenv.env['DATABASE_PORT'];
    final url = "http://$ip:$port";

    await http.post(
      Uri.parse("$url/devices"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      },
      body: jsonEncode({
        "name": newName,
        "ip": newIp,
        "port": port,
      }),
    );

    loadDevices();
  }

  Future<void> deleteDevice(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final ip = dotenv.env['DEVICE_IP'];
    final port = dotenv.env['DATABASE_PORT'];
    final url = "http://$ip:$port";

    await http.delete(
      Uri.parse("$url/devices/$id"),
      headers: {"Authorization": "Bearer $token"},
    );

    loadDevices();
  }

  @override
  void initState() {
    super.initState();
    loadDevices();
  }

  void showAddDialog() {
    final nameCtrl = TextEditingController();
    final ipCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Nuevo dispositivo"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Nombre")),
            TextField(controller: ipCtrl, decoration: const InputDecoration(labelText: "IP")),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              addDevice(nameCtrl.text, ipCtrl.text);
              Navigator.pop(context);
            },
            child: const Text("Guardar"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final port = dotenv.env['APP_PORT'];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dispositivos"),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: "Cerrar sesión",
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Cerrar sesión"),
                    content: const Text("¿Seguro que quieres cerrar sesión?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancelar"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          "Cerrar sesión",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  );
                },
              );

              if (confirm == true) {
                logout();
              }
            },
          ),

          IconButton(
            tooltip: "Cambiar contraseña",
            icon: const Icon(Icons.lock_reset),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChangePasswordScreen(),
                ),
              );
            },
          ),

          if (role == "admin" || role == "boss")
            IconButton(
              tooltip: "Administrar dispositivos",
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminScreen(),
                  ),
                ).then((_) {
                  loadDevices();
                });
              },
            ),

          if (role == "admin" || role == "boss")
            IconButton(
              tooltip: "Añadir dispositivo",
              icon: const Icon(Icons.add),
              onPressed: showAddDialog,
            ),
        ],
      ),
      body: ListView.builder(
        itemCount: devices.length,
        itemBuilder: (_, i) {
          final d = devices[i];

          return ListTile(
            title: Text(d["name"]),
            subtitle: Text(d["ip"]),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (role=="boss")
                IconButton(
                  tooltip: "Eliminar dispositivo",
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    final confirm = await confirmDelete(
                      context,
                      "¿Seguro que quieres eliminar el dispositivo ${d["name"]}?",
                    );
                    if (confirm) {
                      deleteDevice(d["id"]);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VncScreen(
                          url: "http://${d["ip"]}:$port/client.html",
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  Future<void> logout() async {
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