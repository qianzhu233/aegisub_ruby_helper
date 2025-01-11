import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AegisubRubyHelper',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      themeMode: _themeMode,
      home: DefaultTabController(
        length: 2,
        child: MyHomePage(
          themeMode: _themeMode,
          onThemeChanged: _toggleThemeMode,
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  const MyHomePage({super.key, required this.themeMode, required this.onThemeChanged});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  String _convertedText = '';

  Widget _buildInputField(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Scrollbar(
        thumbVisibility: true,
        child: TextField(
          controller: _controller,
          maxLines: null,
          expands: true,
          scrollPhysics: const BouncingScrollPhysics(),
          decoration: const InputDecoration(
            hintText: 'Enter text to convert...',
            border: InputBorder.none,
          ),
          style: const TextStyle(fontFamily: 'monospace', fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildOutputField(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        child: SelectableText(
          _convertedText,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 16,
          ),
        ),
      ),
    );
  }


  String convertToK1Format(String text) {
    List<String> lines = text.split('\n');
    RegExp pattern = RegExp(
      r'\{\{[pP]hotrans\|[^|]+\|[^}]+\}\}|' +   // {{photrans|汉字|假名}}
      r'([\u4E00-\u9FFF]+)（([^）]+)）|' +        // 汉字（假名）
      r'\[[\u4E00-\u9FFF]+\|[^\]]+\]|' +       // [汉字|假名]
      r'〈[\u4E00-\u9FFF]+\/[^〉]+〉|' +        // 〈汉字/假名〉
      r'【[\u4E00-\u9FFF]+\([^)]+\)】'         // 【汉字(假名)】
    );
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      if (pattern.hasMatch(line)) {
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

  // Step 2: 处理 {{p(P)hotrans|汉字|假名}} 格式
  line = line.replaceAllMapped(RegExp(r'\{\{[pP]hotrans\|([^|]+)\|([^}]+)\}\}'), (match) {
    return '{\\k1}${match.group(1)}|<${match.group(2)}{\\k1}';
  });

  // Step 3: 处理 汉字（假名） 格式
  line = line.replaceAllMapped(RegExp(r'([\u4E00-\u9FFF]+)（([^）]+)）'), (match) {
    return '{\\k1}${match.group(1)}|<${match.group(2)}{\\k1}';
  });

  // Step 4: 处理 [汉字|假名] 格式
  line = line.replaceAllMapped(RegExp(r'\[([\u4E00-\u9FFF]+)\|([^\]]+)\]'), (match) {
    return '{\\k1}${match.group(1)}|<${match.group(2)}{\\k1}';
  });

  // Step 5: 处理 〈汉字/假名〉 格式
  line = line.replaceAllMapped(RegExp(r'〈([\u4E00-\u9FFF]+)\/([^〉]+)〉'), (match) {
    return '{\\k1}${match.group(1)}|<${match.group(2)}{\\k1}';
  });

  // Step 6: 处理 【汉字(假名)】 格式
  line = line.replaceAllMapped(RegExp(r'【([\u4E00-\u9FFF]+)\(([^)]+)\)】'), (match) {
    return '{\\k1}${match.group(1)}|<${match.group(2)}{\\k1}';
  });

  // Step 7: 处理空格（包含半角和全角空格），为其前后添加 {\k1}
  line = line.replaceAllMapped(RegExp(r'(\S)([ 　]+)(\S)'), (match) {
    return '${match.group(1)}{\\k1}${match.group(2)}{\\k1}${match.group(3)}';
  });

  // Step 8: 清除多余的 {\k1} 标记，确保不会重复
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
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_outline, color: Colors.green),
              SizedBox(width: 8),
              Expanded(child: Text('Text copied to clipboard!', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.text_fields, size: 28),
            const SizedBox(width: 8),
            Text(
              'AegisubRubyHelper',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        bottom: const TabBar(
          tabs: [
            Tab(icon: Icon(Icons.edit, size: 20), text: 'Convert'),
            Tab(icon: Icon(Icons.info_outline, size: 20), text: 'About'),
          ],
        ),
        actions: [
          PopupMenuButton<ThemeMode>(
            icon: const Icon(Icons.brightness_6),
            onSelected: widget.onThemeChanged,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: ThemeMode.system,
                child: Text('System Default'),
              ),
              const PopupMenuItem(
                value: ThemeMode.light,
                child: Text('Light Mode'),
              ),
              const PopupMenuItem(
                value: ThemeMode.dark,
                child: Text('Dark Mode'),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isMobile = constraints.maxWidth < 600;

                return Column(
                  children: [
                    // 输入框和输出框的布局，根据屏幕宽度动态调整
                    Expanded(
                      child: isMobile
                          ? Column(
                              children: [
                                // 输入框部分
                                Flexible(
                                  flex: 1,
                                  child: _buildInputField(context),
                                ),
                                const SizedBox(width: 16),
                                // 输出框部分
                                Flexible(
                                  flex: 1,
                                  child: _buildOutputField(context),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                // 左侧输入框
                                Expanded(child: _buildInputField(context)),
                                const SizedBox(width: 16),
                                // 右侧输出框
                                Expanded(child: _buildOutputField(context)),
                              ],
                            ),
                    ),
                    const SizedBox(height: 16),
                    // 按钮区域
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _convertText,
                          icon: const Icon(Icons.transform),
                          label: const Text('Convert Text'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _copyToClipboard,
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy to Clipboard'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          // 关于页面
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.app_registration, size: 50),
                  SizedBox(height: 10),
                  Text(
                    'AegisubRubyHelper',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Version: 1.0.2',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'A simple and powerful tool to convert text to K1 format.\nDeveloped by qianzhu233.',
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
