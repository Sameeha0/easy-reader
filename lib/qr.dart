import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

import 'style.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool found = false;

  @override
  Widget build(BuildContext context) {
    // just the camera, the gold box, the words and a Back button
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        Positioned.fill(
          child: MobileScanner(
            // only drawn while the camera works
            overlayBuilder: (context, constraints) => Stack(children: [
              // gold box showing where to put the code
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: gold, width: 5),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: Glass(
                      tint: navy,
                      padding: const EdgeInsets.all(20),
                      child: Text('Put the QR code inside the gold box.\nHold still for a moment.',
                          textAlign: TextAlign.center, style: body(21, color: cream, weight: 600)),
                    ),
                  ),
                ),
              ),
            ]),
            // e.g. dad pressed "Don't allow" on the camera question
            errorBuilder: (context, error) => Container(
              color: cream,
              padding: const EdgeInsets.all(28),
              alignment: Alignment.center,
              child: Text(
                'The camera is not allowed.\n\nTap Back, open Scan again, and choose "While using the app".',
                textAlign: TextAlign.center,
                style: body(22, weight: 600),
              ),
            ),
            onDetect: (capture) {
              final text = capture.barcodes.firstOrNull?.rawValue;
              if (text == null || found) return;
              found = true; // the camera sees the code many times a second, only react once
              HapticFeedback.mediumImpact();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => QrResultPage(text)));
            },
          ),
        ),
        // outside the camera, so it shows even if the camera is not allowed
        Positioned(
          left: 16,
          top: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(width: 132, child: BigButton('‹ Back', () => Navigator.pop(context), filled: false)),
            ),
          ),
        ),
      ]),
    );
  }
}

class QrResultPage extends StatelessWidget {
  final String text;
  const QrResultPage(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final isWebsite = text.startsWith('http://') || text.startsWith('https://');
    return Scaffold(
      appBar: topBar(context, 'QR code result'),
      body: NotebookGrid(
        line: goldDark.withValues(alpha: 0.45),
        glow: Colors.white.withValues(alpha: 0.8),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(isWebsite ? 'This code is a website:' : 'This code says:', style: body(21, color: muted)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: block(Colors.white, border: navy),
              child: SelectableText(text, style: body(23, weight: 600)),
            ),
            const SizedBox(height: 24),
            // never open links by itself: dad sees the address first (QR scams are common)
            if (isWebsite) ...[
              BigButton('Open website', () => launchUrl(Uri.parse(text), mode: LaunchMode.externalApplication)),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text('Only open websites you trust.', style: body(18, color: cherry, weight: 600)),
              ),
              const SizedBox(height: 8),
            ],
            BigButton('Copy text', () {
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(backgroundColor: navy, content: Text('Copied', style: body(20, color: gold))));
            }, filled: false),
            const SizedBox(height: 16),
            BigButton('Scan another code', () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ScanPage()));
            }, filled: false),
          ],
        ),
      ),
    );
  }
}
