import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'qr.dart';
import 'recent.dart';
import 'style.dart';

void main() => runApp(const EasyReaderApp());

class EasyReaderApp extends StatelessWidget {
  const EasyReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Easy Reader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Figtree',
        colorScheme: ColorScheme.fromSeed(seedColor: navy, primary: navy, surface: cream),
        scaffoldBackgroundColor: cream,
        appBarTheme: const AppBarTheme(
          foregroundColor: navy,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        // iPhone-style sliding screens (also lets you swipe from the left edge to go back)
        pageTransitionsTheme: const PageTransitionsTheme(builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        }),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Android/iPhone send files here when dad picks "Open with Easy Reader"
  static const channel = MethodChannel('easy_reader/open');
  List<String> recent = [];

  @override
  void initState() {
    super.initState();
    loadRecent().then((list) => setState(() => recent = list));
    channel.invokeMethod('initialFile').then(openShared);
    channel.setMethodCallHandler((call) async => openShared(call.arguments));
  }

  void openShared(dynamic args) {
    if (args is List && mounted) open(args[0], args[1]);
  }

  Future<void> open(String path, String name) async {
    await openDocument(context, path, name);
    final list = await loadRecent();
    setState(() => recent = list);
  }

  Future<void> pickFile() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'xlsx', 'pptx'],
    );
    if (file?.path != null) open(file!.path!, file.name);
  }

  @override
  Widget build(BuildContext context) {
    // navy header at the top, so the status bar icons are white here
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: NotebookGrid(
          line: goldDark.withValues(alpha: 0.45),
          glow: Colors.white.withValues(alpha: 0.8),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                color: navy,
                child: NotebookGrid(
                  line: Colors.white.withValues(alpha: 0.16),
                  glow: const Color(0xFF2E3F8F),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 20, 20, 28),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset('assets/logo/logo.png', width: 44, height: 44),
                        ),
                        const SizedBox(width: 12),
                        Text('Easy Reader', style: heading(22, color: gold)),
                      ]),
                      const SizedBox(height: 30),
                      Text('Hello!', style: heading(46, color: cream)),
                      const SizedBox(height: 6),
                      Text('What would you like to do?', style: body(21, color: cream.withValues(alpha: 0.8))),
                    ]),
                  ),
                ),
              ),
              const Stripes(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  ActionTile(
                    icon: Icons.description_rounded,
                    color: gold,
                    textColor: navy,
                    title: 'Open a document',
                    subtitle: 'PDF, Word, Excel, PowerPoint',
                    onTap: pickFile,
                  ),
                  const SizedBox(height: 16),
                  ActionTile(
                    icon: Icons.qr_code_scanner_rounded,
                    color: cherry,
                    textColor: cream,
                    title: 'Scan a QR code',
                    subtitle: 'Use the camera',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanPage())),
                  ),
                  const SizedBox(height: 16),
                  // teaches the shortcut
                  Glass(
                    tint: Colors.white,
                    padding: const EdgeInsets.all(18),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('TIP', style: body(15, color: cherry, weight: 800).copyWith(letterSpacing: 1.5)),
                      const SizedBox(height: 4),
                      Text('Got a file on WhatsApp or email? Tap it, then choose Easy Reader.', style: body(19)),
                    ]),
                  ),
                  const SizedBox(height: 34),
                  Text('Recent files', style: heading(28)),
                  const SizedBox(height: 14),
                  if (recent.isEmpty) Text('Files you open will show here.', style: body(19, color: muted)),
                  for (final path in recent)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: RecentTile(path, () => open(path, fileName(path))),
                    ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color, textColor;
  final String title, subtitle;
  final VoidCallback onTap;
  const ActionTile({
    super.key,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Glass(
        tint: color,
        padding: const EdgeInsets.all(18),
        child: Row(children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: textColor, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, size: 36, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: heading(23, color: textColor)),
              const SizedBox(height: 4),
              Text(subtitle, style: body(17, color: textColor.withValues(alpha: 0.85))),
            ]),
          ),
          Icon(Icons.arrow_forward_rounded, size: 30, color: textColor),
        ]),
      ),
    );
  }
}
