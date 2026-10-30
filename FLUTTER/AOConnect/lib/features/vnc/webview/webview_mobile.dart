import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../vnc_controller.dart';


class VncWebViewMobile extends StatefulWidget {
  final String url;
  final VncController controller;

  const VncWebViewMobile({
    super.key,
    required this.url,
    required this.controller,
  });

  @override
  State<VncWebViewMobile> createState() => _VncWebViewMobileState();
}

class _VncWebViewMobileState extends State<VncWebViewMobile> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadRequest(Uri.parse(widget.url));

    widget.controller.setMobileController(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }

}