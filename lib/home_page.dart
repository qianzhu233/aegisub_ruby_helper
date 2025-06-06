import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aegisub_ruby_helper/l10n/app_localizations.dart';

class HomePage extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final ValueChanged<Locale> onLocaleChanged;

  const HomePage({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
    required this.onLocaleChanged,
  });

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  String _convertedText = '';
  String _previewText = '';
  int _selectedDrawerIndex = 0;

  // 格式开关，新增 'paren2'
  final Map<String, bool> _formatEnabled = {
    'photrans': true,
    'paren': true,
    'paren2': true, // 新增
    'bracket': true,
    'angle': true,
    'square': true,
  };

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
            loc.inputLabel,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 6),
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

  Widget _buildFormatMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.tune),
      tooltip: '格式检测设置',
      itemBuilder: (context) => [
        CheckedPopupMenuItem(
          value: 'photrans',
          checked: _formatEnabled['photrans']!,
          child: const Text('{{photrans|汉字|假名}}'),
        ),
        CheckedPopupMenuItem(
          value: 'paren',
          checked: _formatEnabled['paren']!,
          child: const Text('汉字（假名）'),
        ),
        CheckedPopupMenuItem(
          value: 'paren2',
          checked: _formatEnabled['paren2']!,
          child: const Text('汉字(假名)'),
        ),
        CheckedPopupMenuItem(
          value: 'bracket',
          checked: _formatEnabled['bracket']!,
          child: const Text('[汉字|假名]'),
        ),
        CheckedPopupMenuItem(
          value: 'angle',
          checked: _formatEnabled['angle']!,
          child: const Text('〈汉字/假名〉'),
        ),
        CheckedPopupMenuItem(
          value: 'square',
          checked: _formatEnabled['square']!,
          child: const Text('【汉字(假名)】'),
        ),
      ],
      onSelected: (key) {
        setState(() {
          _formatEnabled[key] = !_formatEnabled[key]!;
          _convertedText = convertToK1Format(_controller.text);
          _previewText = buildPreviewText(_controller.text);
        });
      },
    );
  }

  String buildPreviewText(String text) {
    String result = text;
    if (_formatEnabled['photrans']!) {
      result = result.replaceAllMapped(
        RegExp(r'\{\{[pP]hotrans\|([^|]+)\|([^}]+)\}\}'),
        (m) => '${m.group(1)}[${m.group(2)}]',
      );
    }
    if (_formatEnabled['paren']!) {
      result = result.replaceAllMapped(
        RegExp(r'([\u4E00-\u9FFF]+)（([^）]+)）'),
        (m) => '${m.group(1)}[${m.group(2)}]',
      );
    }
    if (_formatEnabled['paren2']!) {
      result = result.replaceAllMapped(
        RegExp(r'([\u4E00-\u9FFF]+)\(([^)]+)\)'),
        (m) => '${m.group(1)}[${m.group(2)}]',
      );
    }
    if (_formatEnabled['bracket']!) {
      result = result.replaceAllMapped(
        RegExp(r'\[([\u4E00-\u9FFF]+)\|([^\]]+)\]'),
        (m) => '${m.group(1)}[${m.group(2)}]',
      );
    }
    if (_formatEnabled['angle']!) {
      result = result.replaceAllMapped(
        RegExp(r'〈([\u4E00-\u9FFF]+)\/([^〉]+)〉'),
        (m) => '${m.group(1)}[${m.group(2)}]',
      );
    }
    if (_formatEnabled['square']!) {
      result = result.replaceAllMapped(
        RegExp(r'【([\u4E00-\u9FFF]+)\(([^)]+)\)】'),
        (m) => '${m.group(1)}[${m.group(2)}]',
      );
    }
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

  Widget _buildRubyPreview(String text, {bool isDark = false}) {
    final List<InlineSpan> spans = [];
    int last = 0;
    final pattern = RegExp(
      r'\{\{[pP]hotrans\|([^|]+)\|([^}]+)\}\}|' +
      r'([\u4E00-\u9FFF]+)（([^）]+)）|' +
      r'([\u4E00-\u9FFF]+)\(([^)]+)\)|' +
      r'\[([\u4E00-\u9FFF]+)\|([^\]]+)\]|' +
      r'〈([\u4E00-\u9FFF]+)\/([^〉]+)〉|' +
      r'【([\u4E00-\u9FFF]+)\(([^)]+)\)】'
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
    List<String> parts = [];
    if (_formatEnabled['square']!) {
      parts.add(r'【[\u4E00-\u9FFF]+\([^)]+\)】');
    }
    if (_formatEnabled['photrans']!) {
      parts.add(r'\{\{[pP]hotrans\|[^|]+\|[^}]+\}\}');
    }
    if (_formatEnabled['paren']!) {
      parts.add(r'([\u4E00-\u9FFF]+)（([^）]+)）');
    }
    if (_formatEnabled['paren2']!) {
      parts.add(r'([\u4E00-\u9FFF]+)\(([^)]+)\)');
    }
    if (_formatEnabled['bracket']!) {
      parts.add(r'\[[\u4E00-\u9FFF]+\|[^\]]+\]');
    }
    if (_formatEnabled['angle']!) {
      parts.add(r'〈[\u4E00-\u9FFF]+\/[^〉]+〉');
    }
    RegExp pattern = RegExp(parts.join('|'));
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      if (pattern.hasMatch(line)) {
        lines[i] = _processLineForK1(line);
      }
    }
    return lines.join('\n');
  }

  String _processLineForK1(String line) {
    if (!line.startsWith(r'{\k1}')) {
      line = '{\\k1}$line';
    }
    if (_formatEnabled['square']!) {
      // 只转换【汉字(假名)】为{\k1}汉字|<假名{\k1}，去掉【和】
      line = line.replaceAllMapped(RegExp(r'【([\u4E00-\u9FFF]+)\(([^)]+)\)】'), (match) {
        return '{\\k1}${match.group(1)}|<${match.group(2)}{\\k1}';
      });
    }
    if (_formatEnabled['photrans']!) {
      line = line.replaceAllMapped(RegExp(r'\{\{[pP]hotrans\|([^|]+)\|([^}]+)\}\}'), (match) {
        return '{\\k1}${match.group(1)}|<${match.group(2)}{\\k1}';
      });
    }
    if (_formatEnabled['paren']!) {
      line = line.replaceAllMapped(RegExp(r'([\u4E00-\u9FFF]+)（([^）]+)）'), (match) {
        return '{\\k1}${match.group(1)}|<${match.group(2)}{\\k1}';
      });
    }
    if (_formatEnabled['paren2']!) {
      line = line.replaceAllMapped(RegExp(r'([\u4E00-\u9FFF]+)\(([^)]+)\)'), (match) {
        return '{\\k1}${match.group(1)}|<${match.group(2)}{\\k1}';
      });
    }
    if (_formatEnabled['bracket']!) {
      line = line.replaceAllMapped(RegExp(r'\[([\u4E00-\u9FFF]+)\|([^\]]+)\]'), (match) {
        return '{\\k1}${match.group(1)}|<${match.group(2)}{\\k1}';
      });
    }
    if (_formatEnabled['angle']!) {
      line = line.replaceAllMapped(RegExp(r'〈([\u4E00-\u9FFF]+)\/([^〉]+)〉'), (match) {
        return '{\\k1}${match.group(1)}|<${match.group(2)}{\\k1}';
      });
    }
    
    // 只对非【...】部分加{\k1}空格处理
    line = line.replaceAllMapped(RegExp(r'(?!【[^】]*)(\S)([ 　]+)(\S)(?![^【]*】)'), (match) {
      return '${match.group(1)}{\\k1}${match.group(2)}{\\k1}${match.group(3)}';
    });
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
          _buildFormatMenu(context),
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
                      Expanded(
                        child: isMobile
                            ? Column(
                                children: [
                                  Flexible(
                                    flex: 1,
                                    child: _buildInputField(context),
                                  ),
                                  const SizedBox(width: 16),
                                  Flexible(
                                    flex: 1,
                                    child: _buildOutputPreviewTabs(context, isDark),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(child: _buildInputField(context)),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildOutputPreviewTabs(context, isDark)),
                                ],
                              ),
                      ),
                      const SizedBox(height: 16),
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
              Tab(text: loc.outputLabel),
              Tab(text: loc.previewLabel),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildOutputField(context),
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
