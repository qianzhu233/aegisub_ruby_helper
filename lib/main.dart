import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:aegisub_ruby_helper/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

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
  Locale? _locale;

  void _toggleThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  void _changeLocale(Locale locale) {
    setState(() {
      _locale = locale;
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
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('zh'),
        Locale('zh', 'CN'),
        Locale('zh', 'TW'),
        Locale('ja'),
      ],
      home: DefaultTabController(
        length: 2,
        child: MyHomePage(
          themeMode: _themeMode,
          onThemeChanged: _toggleThemeMode,
          onLocaleChanged: _changeLocale,
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final ValueChanged<Locale> onLocaleChanged;

  const MyHomePage({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
    required this.onLocaleChanged,
  });

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  String _convertedText = '';
  String _previewText = '';

  int _selectedDrawerIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _convertedText = convertToK1Format(_controller.text);
        _previewText = buildPreviewText(_controller.text);
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildInputField(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.inputLabel ?? 'Input',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          // 用Expanded包裹Scrollbar+TextField，防止溢出
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                scrollPhysics: const BouncingScrollPhysics(),
                decoration: InputDecoration(
                  hintText: loc.hintText,
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 16),
              ),
            ),
          ),
        ],
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

  /// 预览文本生成：将带假名的格式转为“汉字[假名]”的可视化文本
  String buildPreviewText(String text) {
    // 只做简单处理，优先匹配常见格式
    String result = text;
    // {{photrans|汉字|假名}}
    result = result.replaceAllMapped(
      RegExp(r'\{\{[pP]hotrans\|([^|]+)\|([^}]+)\}\}'),
      (m) => '${m.group(1)}[${m.group(2)}]',
    );
    // 汉字（假名）
    result = result.replaceAllMapped(
      RegExp(r'([\u4E00-\u9FFF]+)（([^）]+)）'),
      (m) => '${m.group(1)}[${m.group(2)}]',
    );
    // [汉字|假名]
    result = result.replaceAllMapped(
      RegExp(r'\[([\u4E00-\u9FFF]+)\|([^\]]+)\]'),
      (m) => '${m.group(1)}[${m.group(2)}]',
    );
    // 〈汉字/假名〉
    result = result.replaceAllMapped(
      RegExp(r'〈([\u4E00-\u9FFF]+)\/([^〉]+)〉'),
      (m) => '${m.group(1)}[${m.group(2)}]',
    );
    // 【汉字(假名)】
    result = result.replaceAllMapped(
      RegExp(r'【([\u4E00-\u9FFF]+)\(([^)]+)\)】'),
      (m) => '${m.group(1)}[${m.group(2)}]',
    );
    return result;
  }

  Widget _buildPreviewField(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${loc.tabConvert} ${loc.appTitle} ${loc.tabAbout}'.contains('预览') ? '预览' : 'Preview',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          _buildRubyPreviewMultiline(_controller.text, isDark: isDark),
        ],
      ),
    );
  }

  /// 多行支持的 ruby 预览
  Widget _buildRubyPreviewMultiline(String text, {bool isDark = false}) {
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: _buildRubyPreview(line, isDark: isDark),
          ),
      ],
    );
  }

  /// 单行 ruby 预览
  Widget _buildRubyPreview(String text, {bool isDark = false}) {
    final List<InlineSpan> spans = [];
    int last = 0;
    final pattern = RegExp(
      r'\{\{[pP]hotrans\|([^|]+)\|([^}]+)\}\}|' +   // {{photrans|汉字|假名}}
      r'([\u4E00-\u9FFF]+)（([^）]+)）|' +           // 汉字（假名）
      r'\[([\u4E00-\u9FFF]+)\|([^\]]+)\]|' +        // [汉字|假名]
      r'〈([\u4E00-\u9FFF]+)\/([^〉]+)〉|' +         // 〈汉字/假名〉
      r'【([\u4E00-\u9FFF]+)\(([^)]+)\)】'          // 【汉字(假名)】
    );
    final matches = pattern.allMatches(text);
    for (final match in matches) {
      if (match.start > last) {
        spans.add(TextSpan(
          text: text.substring(last, match.start),
          style: TextStyle(fontSize: 18, color: isDark ? Colors.white : Colors.black),
        ));
      }
      String? kanji;
      String? kana;
      if (match.group(1) != null && match.group(2) != null) {
        kanji = match.group(1);
        kana = match.group(2);
      } else if (match.group(3) != null && match.group(4) != null) {
        kanji = match.group(3);
        kana = match.group(4);
      } else if (match.group(5) != null && match.group(6) != null) {
        kanji = match.group(5);
        kana = match.group(6);
      } else if (match.group(7) != null && match.group(8) != null) {
        kanji = match.group(7);
        kana = match.group(8);
      } else if (match.group(9) != null && match.group(10) != null) {
        kanji = match.group(9);
        kana = match.group(10);
      }
      if (kanji != null && kana != null) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: Text(
                  kana,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Text(
                kanji,
                style: TextStyle(
                  fontSize: 20,
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ));
      }
      last = match.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(
        text: text.substring(last),
        style: TextStyle(fontSize: 18, color: isDark ? Colors.white : Colors.black),
      ));
    }
    return RichText(
      text: TextSpan(children: spans),
      textAlign: TextAlign.left,
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

  void _copyToClipboard() {
    if (_convertedText.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _convertedText));
      final loc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.copiedText,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.text_fields, size: 28),
            const SizedBox(width: 8),
            Text(
              loc.appTitle,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<ThemeMode>(
            icon: const Icon(Icons.brightness_6),
            onSelected: widget.onThemeChanged,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: ThemeMode.system,
                child: Text(loc.themeSystem),
              ),
              PopupMenuItem(
                value: ThemeMode.light,
                child: Text(loc.themeLight),
              ),
              PopupMenuItem(
                value: ThemeMode.dark,
                child: Text(loc.themeDark),
              ),
            ],
          ),
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language),
            onSelected: widget.onLocaleChanged,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: Locale('en'),
                child: Text('English'),
              ),
              const PopupMenuItem(
                value: Locale('zh', 'CN'),
                child: Text('简体中文'),
              ),
              const PopupMenuItem(
                value: Locale('zh', 'TW'),
                child: Text('繁體中文'),
              ),
              const PopupMenuItem(
                value: Locale('ja'),
                child: Text('日本語'),
              ),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Center(
                child: Text(
                  loc.appTitle,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(loc.tabConvert),
              selected: _selectedDrawerIndex == 0,
              onTap: () {
                setState(() {
                  _selectedDrawerIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(loc.tabAbout),
              selected: _selectedDrawerIndex == 1,
              onTap: () {
                setState(() {
                  _selectedDrawerIndex = 1;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: _selectedDrawerIndex == 0
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  bool isMobile = constraints.maxWidth < 600;

                  return Column(
                    children: [
                      // 输入框和输出/预览框的布局，根据屏幕宽度动态调整
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
                                  // 输出/预览框部分（合并为Tab）
                                  Flexible(
                                    flex: 1,
                                    child: _buildOutputPreviewTabs(context, isDark),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  // 左侧输入框
                                  Expanded(child: _buildInputField(context)),
                                  const SizedBox(width: 16),
                                  // 右侧输出/预览框（合并为Tab）
                                  Expanded(child: _buildOutputPreviewTabs(context, isDark)),
                                ],
                              ),
                      ),
                      const SizedBox(height: 16),
                      // 按钮区域
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _copyToClipboard,
                            icon: const Icon(Icons.copy),
                            label: Text(loc.btnCopy),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.app_registration, size: 50),
                    const SizedBox(height: 10),
                    Text(
                      loc.appTitle,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      loc.version,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      loc.aboutText,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// 输出/预览 Tab 合并
  Widget _buildOutputPreviewTabs(BuildContext context, bool isDark) {
    final loc = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
            tabs: [
              Tab(text: loc.outputLabel ?? 'Output'),
              Tab(text: loc.previewLabel ?? 'Preview'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // 输出框
                _buildOutputField(context),
                // 预览框
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _buildRubyPreviewMultiline(_controller.text, isDark: isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
