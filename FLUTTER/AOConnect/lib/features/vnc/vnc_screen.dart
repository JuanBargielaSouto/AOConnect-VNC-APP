import 'package:flutter/material.dart';
import 'dart:io';

import 'package:AOConnect/features/vnc/vnc_controller.dart';
import 'webview/webview_mobile.dart';
import 'webview/webview_windows.dart';

class VncScreen extends StatefulWidget {
  final String url;

  const VncScreen({super.key, required this.url});

  @override
  State<VncScreen> createState() => _VncScreenState();
}

class _VncScreenState extends State<VncScreen> {
  final VncController controller = VncController();

  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool keyboardOpen = false;
  bool navigationMode = false;
  bool panMode = false;

  void toggleKeyboard() {
    setState(() => keyboardOpen = !keyboardOpen);

    if (keyboardOpen) {
      FocusScope.of(context).requestFocus(_focusNode);
    } else {
      FocusScope.of(context).unfocus();
    }
  }

  void handleTextChange(String text) {

    if (text.isEmpty) {
      controller.sendBackspace();
    } else {
      controller.sendText(text.characters.last);
    }

    _textController.text = "a";
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void toggleNavigationMode() {
    setState(() {
      navigationMode = !navigationMode;
    });

    controller.setNavigationMode(navigationMode);
  }

  @override
  Widget build(BuildContext context) {
    final isWindows = Platform.isWindows;

    return Scaffold(
      body: Stack(
        children: [
          // VNC
          isWindows
              ? VncWebViewWindows(url: widget.url, controller: controller)
              : VncWebViewMobile(url: widget.url, controller: controller),

          if (!isWindows)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: 0,
                child: TextField(
                  focusNode: _focusNode,
                  controller: _textController,
                  onChanged: handleTextChange,
                ),
              ),
            ),

          // BOTONES
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              heroTag: "main",
              onPressed: isWindows
                  ? () => Navigator.pop(context)
                  : toggleKeyboard,
              child: Icon(
                isWindows
                    ? Icons.arrow_back
                    : (keyboardOpen ? Icons.keyboard_hide : Icons.keyboard),
              ),
            ),
          ),
          if(!isWindows)
            Positioned(
              bottom: 100,
              right: 20,
              child: FloatingActionButton(
                heroTag: "nav_mode",
                backgroundColor: navigationMode ? Colors.blue : Colors.grey,
                onPressed: toggleNavigationMode,
                child: const Icon(Icons.open_with),
              ),
            ),
        ],
      ),
    );
  }
}