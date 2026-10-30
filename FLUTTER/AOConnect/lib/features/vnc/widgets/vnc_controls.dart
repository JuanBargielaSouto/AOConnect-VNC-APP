import 'package:flutter/material.dart';

class VncControls extends StatelessWidget {
  final VoidCallback onReconnect;

  const VncControls({super.key, required this.onReconnect});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 20,
      child: FloatingActionButton(
        onPressed: onReconnect,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}