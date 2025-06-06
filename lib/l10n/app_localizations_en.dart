// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AegisubRubyHelper';

  @override
  String get tabConvert => 'Convert';

  @override
  String get tabAbout => 'About';

  @override
  String get themeSystem => 'System Default';

  @override
  String get themeLight => 'Light Mode';

  @override
  String get themeDark => 'Dark Mode';

  @override
  String get btnConvert => 'Convert Text';

  @override
  String get btnCopy => 'Copy to Clipboard';

  @override
  String get copiedText => 'Text copied to clipboard!';

  @override
  String get hintText => 'Enter text to convert...';

  @override
  String get version => 'Version: 1.0.3';

  @override
  String get aboutText => 'A simple and powerful tool to convert text to K1 format.\nDeveloped by qianzhu233.';

  @override
  String get inputLabel => 'Input';

  @override
  String get outputLabel => 'Output';

  @override
  String get previewLabel => 'Preview';
}
