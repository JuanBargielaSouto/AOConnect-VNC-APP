import 'dart:convert';
import 'dart:io';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart';

class VncController {
  WebViewController? _mobile;
  WebviewController? _windows;

  void setMobileController(WebViewController controller) {
    _mobile = controller;
  }

  void setWindowsController(WebviewController controller) {
    _windows = controller;
  }

  void runJS(String js) {

    if (Platform.isWindows) {
      _windows?.executeScript(js);
    } else {
      _mobile?.runJavaScript(js);
    }
  }

  void sendText(String text) {
    if (text.isEmpty) return;
    final js = "window.sendTextToVNC(${jsonEncode(text)});";
    runJS(js);
  }

  void sendBackspace() {
    runJS("window.sendTextToVNC('__BACKSPACE__');");
  }

  void sendEnter() {
    runJS("window.sendTextToVNC('Enter');");
  }

  void setNavigationMode(bool enabled) {
    runJS("window.setNavigationMode($enabled);");
  }

  void setPanMode(bool panMode){
    "window.setPanMode(${panMode ? "true" : "false"});";
  }

}
