import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'style.dart';
import 'recent.dart';

class ReaderPage extends StatefulWidget {
  final String path, name;
  const ReaderPage(this.path, this.name, {super.key});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  late final String type = fileType(widget.name);
  PdfControllerPinch? pdf;
  WebViewController? web;
  double zoom = 1.0; // changed with the Smaller / Bigger buttons

  @override
  void initState() {
    super.initState();
    if (type == 'pdf') {
      pdf = PdfControllerPinch(document: PdfDocument.openFile(widget.path));
    } else {
      // Word, Excel and PowerPoint are drawn by assets/viewer/viewer.html (with pictures)
      web = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(cream)
        ..setNavigationDelegate(NavigationDelegate(onPageFinished: (_) async {
          final data = base64Encode(await File(widget.path).readAsBytes());
          web!.runJavaScript("openFile('$data', '$type')");
        }))
        ..loadFlutterAsset('assets/viewer/viewer.html');
    }
  }

  @override
  void dispose() {
    pdf?.dispose();
    super.dispose();
  }

  void changeZoom(double step) {
    setState(() => zoom = (zoom + step).clamp(0.75, 3.0));
    if (web != null) {
      web!.runJavaScript('setZoom($zoom)');
    } else {
      pdf!.value = Matrix4.identity()..scaleByDouble(zoom, zoom, 1.0, 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: topBar(context, widget.name),
      body: pdf != null
          ? PdfViewPinch(controller: pdf!, backgroundDecoration: const BoxDecoration(color: cream))
          : WebViewWidget(controller: web!),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: cream, border: Border(top: BorderSide(color: navy, width: 2))),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(children: [
              Expanded(child: BigButton('−  Smaller', () => changeZoom(-0.25), filled: false)),
              const SizedBox(width: 12),
              Expanded(child: BigButton('+  Bigger', () => changeZoom(0.25))),
            ]),
          ),
        ),
      ),
    );
  }
}
