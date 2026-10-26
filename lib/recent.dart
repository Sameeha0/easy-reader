import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'style.dart';
import 'reader.dart';

// Opened files are copied into the app's own folder, so "Recent files"
// still works after WhatsApp or the file picker clears its temporary copy.

String fileName(String path) => path.split(Platform.pathSeparator).last;
String fileType(String name) => name.split('.').last.toLowerCase();

Future<List<String>> loadRecent() async {
  final prefs = await SharedPreferences.getInstance();
  final list = prefs.getStringList('recent') ?? [];
  return list.where((p) => File(p).existsSync()).toList();
}

Future<void> openDocument(BuildContext context, String path, String name) async {
  final folder = Directory('${(await getApplicationSupportDirectory()).path}/recent');
  await folder.create(recursive: true);
  final saved = '${folder.path}/$name';
  if (path != saved) await File(path).copy(saved);

  // newest first, keep 10
  final prefs = await SharedPreferences.getInstance();
  final list = (prefs.getStringList('recent') ?? [])..remove(saved);
  list.insert(0, saved);
  for (final old in list.skip(10)) {
    if (File(old).existsSync()) File(old).deleteSync();
  }
  await prefs.setStringList('recent', list.take(10).toList());

  if (!context.mounted) return;
  await Navigator.push(context, MaterialPageRoute(builder: (_) => ReaderPage(saved, name)));
}

// Same colours as the Office apps so dad recognises the file type.
const typeColors = {
  'pdf': Color(0xFFC62828),
  'docx': Color(0xFF1E5BB8),
  'xlsx': Color(0xFF1D7044),
  'pptx': Color(0xFFC4501B),
};
const typeNames = {'pdf': 'PDF', 'docx': 'Word', 'xlsx': 'Excel', 'pptx': 'PowerPoint'};

class RecentTile extends StatelessWidget {
  final String path;
  final VoidCallback onTap;
  const RecentTile(this.path, this.onTap, {super.key});

  @override
  Widget build(BuildContext context) {
    final name = fileName(path);
    final type = fileType(name);
    return Pressable(
      onTap: onTap,
      child: Glass(
        tint: Colors.white,
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: typeColors[type] ?? muted, borderRadius: BorderRadius.circular(14)),
            child: Text(type.toUpperCase(), style: body(14, color: Colors.white, weight: 800)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: body(20, weight: 700)),
              Text(typeNames[type] ?? '', style: body(17, color: muted)),
            ]),
          ),
        ]),
      ),
    );
  }
}
