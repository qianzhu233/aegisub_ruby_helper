import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AegisubRubyHelper',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const DefaultTabController(
        length: 2, // 2 tabs: 1 for conversion, 1 for About
        child: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  String _convertedText = '';

  // Conversion logic
  String convertToK1Format(String text) {
    List<String> lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];

      // Process lines containing annotations or phonetic notations
      if (line.contains('{{photrans|') || line.contains('（')) {
        lines[i] = _processLineForK1(line);
      }
    }

    return lines.join('\n');
  }

  String _processLineForK1(String line) {
    // Step 1: 确保行首添加单个 {\k1}
    if (!line.startsWith(r'{\k1}')) {
      line = '{\\k1}$line';
    }

    // Step 2: 处理 {{photrans|汉字|假名}} 格式
    line = line.replaceAllMapped(RegExp(r'\{\{photrans\|([^|]+)\|([^}]+)\}\}'), (match) {
      return '{\\k1}${match.group(1)}|<${match.group(2)}{\\k1}';
    });

    // Step 3: 处理 汉字（假名） 格式，仅为汉字添加注音
    line = line.replaceAllMapped(RegExp(r'([\u4E00-\u9FFF]+)（([^）]+)）'), (match) {
      return '{\\k1}${match.group(1)}|<${match.group(2)}{\\k1}';
    });

    // Step 4: 处理空格（包含半角和全角空格），为其前后添加 {\k1}
    line = line.replaceAllMapped(RegExp(r'(\S)([ 　]+)(\S)'), (match) {
      return '${match.group(1)}{\\k1}${match.group(2)}{\\k1}${match.group(3)}';
    });

    // Step 5: 清除多余的 {\k1} 标记，确保不会重复
    line = line.replaceAll(RegExp(r'(\{\\k1\})+'), '{\\k1}');

    return line;
  }

  // Convert text when button is pressed
  void _convertText() {
    setState(() {
      _convertedText = convertToK1Format(_controller.text);
    });
  }

  // Copy converted text to clipboard
  void _copyToClipboard() {
    if (_convertedText.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _convertedText));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Text copied to clipboard!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AegisubRubyHelper'),
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Convert'),
            Tab(text: 'About'),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          // Convert Page
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: SingleChildScrollView(
                    child: TextField(
                      controller: _controller,
                      maxLines: null, // No limit on input lines
                      decoration: const InputDecoration(
                        hintText: 'Enter text here...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _convertText,
                  child: const Text('Convert'),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      _convertedText,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 16),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ElevatedButton(
                    onPressed: _copyToClipboard,
                    child: const Text('Copy to Clipboard'),
                  ),
                ),
              ],
            ),
          ),
          // About Page
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'AegisubRubyHelper',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Version: 1.0.2',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'A simple Flutter app to help with text conversion and phonetic annotation.\n'
                    'Developed by qianzhu233.',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
