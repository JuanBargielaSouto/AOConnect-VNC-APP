import 'package:flutter/material.dart';

class VncError extends StatelessWidget {
  final VoidCallback onRetry;

  const VncError({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: ElevatedButton(
          onPressed: onRetry,
          child: const Text("Reintentar"),
        ),
      ),
    );
  }
}