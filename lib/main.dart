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

  String convertToK1Format(String text) {
    // Split text into lines
    List<String> lines = text.split('\n');

    // Process each line separately
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];

      // If the line contains any annotation, convert it
      if (line.contains('{{photrans|') || line.contains('（')) {
        // Process this line and update it in the list
        lines[i] = _processLineForK1(line);
      }
    }

    // Join the lines back into a single string
    return lines.join('\n');
  }

  String _processLineForK1(String line) {
    // Step 1: Add leading {\k1} if necessary
    line = '{\\k1}$line';

    // Step 2: Handle spaces (half-width and full-width) between non-whitespace characters
    line = line.replaceAllMapped(RegExp(r'(\S)([ 　]+)(\S)'), (match) {
      return '${match.group(1)}{\\k1}${match.group(2)}{\\k1}${match.group(3)}';
    }).replaceAllMapped(RegExp(r'([ 　]+)(\S)'), (match) {
      return '{\\k1}${match.group(1)}${match.group(2)}';
    }).replaceAllMapped(RegExp(r'(\S)([ 　]+)'), (match) {
      return '${match.group(1)}{\\k1}${match.group(2)}';
    });

    // Step 3: Convert {{photrans|汉字|假名}} to {\k1}汉字|<假名{\k1}
    line = line.replaceAllMapped(RegExp(r'\{\{photrans\|([^|]+)\|([^}]+)\}\}'), (match) {
      return '{\\k1}${match.group(1)}|<${match.group(2)}{\\k1}';
    });

    // Step 4: Convert 汉字（假名） to {\k1}汉字|<假名{\k1}
    line = line.replaceAllMapped(RegExp(r'([^（]+)（([^）]+)）'), (match) {
      // Ensure the 汉字 part is wrapped in {\k1}
      return '{\\k1}${match.group(1)}|<${match.group(2)}{\\k1}';
    });

    // Step 6: Remove consecutive {\k1} and ensure no duplicates
    line = line.replaceAll(RegExp(r'(\{\\k1\})+'), '{\\k1}');

    return line;
  }


  void _convertText() {
    setState(() {
      _convertedText = convertToK1Format(_controller.text);
    });
  }

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
                // Text field for input
                Expanded(
                  child: SingleChildScrollView(
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: 'Enter text here...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Button to trigger conversion
                ElevatedButton(
                  onPressed: _convertText,
                  child: const Text('Convert'),
                ),
                const SizedBox(height: 16),
                // Display the converted text
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      _convertedText,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 16),
                    ),
                  ),
                ),
                // Copy button
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
                    'Version: 1.0.1',
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
