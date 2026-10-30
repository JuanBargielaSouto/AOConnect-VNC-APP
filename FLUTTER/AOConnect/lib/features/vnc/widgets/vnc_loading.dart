import 'package:flutter/material.dart';

class VncLoading extends StatelessWidget {
  const VncLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}