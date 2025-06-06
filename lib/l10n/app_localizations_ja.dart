// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'AegisubRubyHelper';

  @override
  String get tabConvert => '変換';

  @override
  String get tabAbout => '情報';

  @override
  String get themeSystem => 'システムに従う';

  @override
  String get themeLight => 'ライトモード';

  @override
  String get themeDark => 'ダークモード';

  @override
  String get btnConvert => 'テキスト変換';

  @override
  String get btnCopy => 'クリップボードにコピー';

  @override
  String get copiedText => 'クリップボードにコピーしました！';

  @override
  String get hintText => '変換するテキストを入力してください...';

  @override
  String get version => 'バージョン：1.0.3';

  @override
  String get aboutText => 'K1形式テキストへの変換ツール。\n開発者：qianzhu233。';

  @override
  String get inputLabel => '入力';

  @override
  String get outputLabel => '出力';

  @override
  String get previewLabel => 'プレビュー';
}
