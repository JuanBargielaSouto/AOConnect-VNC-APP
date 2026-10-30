import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart';
import '../vnc_controller.dart';

class VncWebViewWindows extends StatefulWidget {
  final String url;
  final VncController controller;

  const VncWebViewWindows({
    super.key,
    required this.url,
    required this.controller,
  });

  @override
  State<VncWebViewWindows> createState() => _VncWebViewWindowsState();
}

class _VncWebViewWindowsState extends State<VncWebViewWindows> {
  WebviewController? _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;

    final controller = WebviewController();

    await controller.initialize();

    await controller.setBackgroundColor(Colors.black);

    await controller.setPopupWindowPolicy(
      WebviewPopupWindowPolicy.deny,
    );

    await controller.loadUrl(widget.url);

    widget.controller.setWindowsController(controller);

    if (mounted) {
      setState(() => _controller = controller);
    }
  }
  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Webview(_controller!);
  }
}