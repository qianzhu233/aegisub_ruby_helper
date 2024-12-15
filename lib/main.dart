import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AegisubRubyHelper',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: DefaultTabController(
        length: 2, // 2 tabs: 1 for conversion, 1 for About
        child: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  String _convertedText = '';

  String convertToK1Format(String text) {
    // Step 1: Check if the text contains "{{photrans|"
    if (!text.contains('{{photrans|') && !text.contains('（')) {
      return text; // Return original text if no annotation
    }

    // Step 2: Ensure text starts with {\k1}
    text = '{\\k1}' + text;

    // Step 3: Handle spaces (half-width and full-width)
    text = text.replaceAllMapped(RegExp(r'(\S)([ 　]+)(\S)'), (match) {
      return '${match.group(1)}{\\k1}${match.group(2)}{\\k1}${match.group(3)}';
    });
    text = text.replaceAllMapped(RegExp(r'([ 　]+)(\S)'), (match) {
      return '{\\k1}${match.group(1)}${match.group(2)}';
    });
    text = text.replaceAllMapped(RegExp(r'(\S)([ 　]+)'), (match) {
      return '${match.group(1)}{\\k1}${match.group(2)}';
    });

    // Step 4: Match and convert {{photrans|汉字|假名}} format
    text = text.replaceAllMapped(RegExp(r'\{\{photrans\|([^|]+)\|([^}]+)\}\}'), (match) {
      return '{\\k1}${match.group(1)}|<${match.group(2)}{\\k1}';
    });

    // Step 5: Match and convert 汉字（假名） format
    text = text.replaceAllMapped(RegExp(r'([^（]+)（([^）]+)）'), (match) {
      // Ensure 汉字 part has {\k1}, then add the rest of the formatting
      return '{\\k1}${match.group(1)}|<${match.group(2)}{\\k1}';
    });

    // Step 6: Remove multiple consecutive {\k1}
    text = text.replaceAll(RegExp(r'(\{\\k1\})+'), '{\\k1}');

    // Step 7: Ensure every 漢字 is prefixed with {\k1} at the final stage
    // This regular expression now ensures that we only add {\k1} if it's missing
    text = text.replaceAllMapped(RegExp(r'(?<!\\k1)[一-龯々〆〤]'), (match) {
      return '{\\k1}${match.group(0)}';
    });

    // Step 8: Remove any redundant {\k1} at the beginning (if it was duplicated)
    text = text.replaceAll(RegExp(r'\{\\k1\}\{\\k1\}'), '{\\k1}');

    return text;
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
        SnackBar(content: Text('Text copied to clipboard!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AegisubRubyHelper'),
        bottom: TabBar(
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
                      decoration: InputDecoration(
                        hintText: 'Enter text here...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Button to trigger conversion
                ElevatedButton(
                  onPressed: _convertText,
                  child: Text('Convert'),
                ),
                SizedBox(height: 16),
                // Display the converted text
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      _convertedText,
                      style: TextStyle(fontFamily: 'monospace', fontSize: 16),
                    ),
                  ),
                ),
                // Copy button
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ElevatedButton(
                    onPressed: _copyToClipboard,
                    child: Text('Copy to Clipboard'),
                  ),
                ),
              ],
            ),
          ),
          // About Page
          Padding(
            padding: const EdgeInsets.all(16.0),
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
                    'Version: 1.0.0',
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
