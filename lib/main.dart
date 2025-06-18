import 'dart:html';
import 'package:flutter/material.dart';

void main() {
  runApp(const AsciiCleanerApp());
}

//comment
class AsciiCleanerApp extends StatelessWidget {
  const AsciiCleanerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ASCII Cleaner',
      theme: ThemeData.dark(),
      home: const AsciiCleanerHomePage(),
    );
  }
}

class AsciiCleanerHomePage extends StatefulWidget {
  const AsciiCleanerHomePage({super.key});

  @override
  State<AsciiCleanerHomePage> createState() => _AsciiCleanerHomePageState();
}

class _AsciiCleanerHomePageState extends State<AsciiCleanerHomePage> {
  String originalText = '';
  String cleanedText = '';
  final Map<String, TextEditingController> replacements = {};

  void loadFile() async {
    FileUploadInputElement uploadInput = FileUploadInputElement();
    uploadInput.accept = '.csv,.txt';
    uploadInput.click();
    uploadInput.onChange.listen((e) {
      final file = uploadInput.files!.first;
      FileReader reader = FileReader();
      reader.readAsText(file);
      reader.onLoadEnd.listen((e) {
        setState(() {
          originalText = reader.result as String;
          cleanedText = originalText;
          _scanForNonAscii();
        });
      });
    });
  }

  void _scanForNonAscii() {
    final seen = <String>{};
    replacements.clear();

    int index = 0;
    for (var c in originalText.characters) {
      final codeUnits = c.runes.toList();
      if (codeUnits.any((r) => r > 127)) {
        if (!seen.contains(c)) {
          seen.add(c);
          replacements[c] = TextEditingController(text: _suggestReplacement(c));
        }
      }
      index++;
    }
  }

  String _suggestReplacement(String char) {
    final normalized = char.toLowerCase().characters.first;
    switch (normalized) {
      case 'á':
      case 'à':
      case 'ä':
      case 'â':
      case 'å':
      case 'ã':
      case 'ā':
      case 'ă':
      case 'ą':
        return 'a';

      case 'é':
      case 'è':
      case 'ë':
      case 'ê':
      case 'ē':
      case 'ė':
      case 'ę':
        return 'e';

      case 'í':
      case 'ì':
      case 'ï':
      case 'î':
      case 'ī':
      case 'į':
        return 'i';

      case 'ó':
      case 'ò':
      case 'ö':
      case 'ô':
      case 'õ':
      case 'ő':
      case 'ō':
        return 'o';

      case 'ú':
      case 'ù':
      case 'ü':
      case 'û':
      case 'ų':
      case 'ū':
        return 'u';

      case 'ñ':
        return 'n';

      case 'ç':
        return 'c';

      case 'ß':
        return 'ss';

      case 'œ':
        return 'oe';

      case 'æ':
        return 'ae';

      case '½':
        return '1/2';

      case '×':
        return 'x';

      case '‼':
        return '!!';

      case '–': // en dash
      case '—': // em dash
        return '-';

      default:
        return '?';
    }
  }

  void _replaceAll() {
    var result = originalText;
    for (var entry in replacements.entries) {
      result = result.replaceAll(entry.key, entry.value.text);
    }
    setState(() {
      cleanedText = result;
    });
  }

  void _saveFile() {
    final blob = Blob([cleanedText]);
    final url = Url.createObjectUrlFromBlob(blob);
    final anchor =
        AnchorElement(href: url)
          ..setAttribute('download', 'cleaned_file.csv')
          ..click();
    Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ASCII Cleaner')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(onPressed: loadFile, child: const Text('Load File')),
            const SizedBox(height: 16),
            if (replacements.isNotEmpty) ...[
              const Text(
                'Non-ASCII Characters Found:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: ListView(
                  children:
                      replacements.entries.map((entry) {
                        final char = entry.key;
                        final codePoint = char.runes.first;
                        final positions = <int>[];

                        int i = 0;
                        for (final c in originalText.characters) {
                          if (c == char) positions.add(i);
                          i++;
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '"${char}" (U+$codePoint) → ',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: entry.value,
                                    decoration: InputDecoration(
                                      hintText: 'Replacement',
                                      filled:
                                          entry.value.text == '?'
                                              ? true
                                              : false,
                                      fillColor:
                                          entry.value.text == '?'
                                              ? Colors.red.withOpacity(0.2)
                                              : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                      }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _replaceAll,
                    child: const Text('Replace All'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _saveFile,
                    child: const Text('Save File'),
                  ),
                ],
              ),
            ] else if (originalText.isNotEmpty)
              const Text('No non-ASCII characters found.'),
          ],
        ),
      ),
    );
  }
}
