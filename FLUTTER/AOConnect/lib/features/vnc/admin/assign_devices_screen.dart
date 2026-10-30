import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AssignDevicesScreen extends StatefulWidget {
  final int userId;
  final String username;

  const AssignDevicesScreen({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<AssignDevicesScreen> createState() => _AssignDevicesScreenState();
}

class _AssignDevicesScreenState extends State<AssignDevicesScreen> {
  List allDevices = [];
  List userDevices = [];

  Future<void> loadData() async {
    final ip = dotenv.env['DEVICE_IP'];
    final port = dotenv.env['DATABASE_PORT'];
    final url = "http://$ip:$port";
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final resAll = await http.get(
      Uri.parse("$url/admin/devices"),
      headers: {"Authorization": "Bearer $token"},
    );

    final resUser = await http.get(
      Uri.parse("$url/admin/user-devices/${widget.userId}"),
      headers: {"Authorization": "Bearer $token"},
    );

    setState(() {
      allDevices = jsonDecode(resAll.body);
      userDevices = jsonDecode(resUser.body);
    });
  }

  bool isAssigned(int deviceId) {
    return userDevices.any((d) => d["id"] == deviceId);
  }

  Future<void> toggleDevice(int deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final ip = dotenv.env['DEVICE_IP'];
    final port = dotenv.env['DATABASE_PORT'];
    final url = "http://$ip:$port";
    final assigned = isAssigned(deviceId);

    final urlAux = assigned
        ? "$url/admin/unassign"
        : "$url/admin/assign";

    await http.post(
      Uri.parse(urlAux),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      },
      body: jsonEncode({
        "user_id": widget.userId,
        "device_id": deviceId
      }),
    );

    loadData();
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dispositivos de ${widget.username}"),
      ),
      body: ListView.builder(
        itemCount: allDevices.length,
        itemBuilder: (_, i) {
          final d = allDevices[i];
          final assigned = isAssigned(d["id"]);

          return ListTile(
            title: Text(d["name"]),
            subtitle: Text(d["ip"]),
            trailing: Switch(
              value: assigned,
              onChanged: (_) => toggleDevice(d["id"]),

              thumbColor: WidgetStateProperty.all(Colors.white),

              trackColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.green;
                }
                return Colors.red;
              }),
            ),
          );
        },
      ),
    );
  }
}