import 'package:flutter/material.dart';

import '../data/database.dart';
import '../l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Formats an amount with the currency symbol used throughout the app.
String money(double value) => '¥${value.toStringAsFixed(2)}';

String categoryLabel(BuildContext context, String category) {
  final l10n = context.l10n;
  switch (category) {
    case Categories.library:
      return l10n.categoryLibrary;
    case Categories.service:
      return l10n.categoryService;
    case Categories.hardware:
      return l10n.categoryHardware;
    default:
      return category;
  }
}

Color categoryColor(String category) {
  switch (category) {
    case Categories.library:
      return Colors.deepPurple;
    case Categories.service:
      return Colors.orange;
    case Categories.hardware:
      return Colors.cyan;
    default:
      return Colors.grey;
  }
}

IconData categoryIcon(String category) {
  switch (category) {
    case Categories.library:
      return Icons.collections_bookmark;
    case Categories.service:
      return Icons.subscriptions;
    case Categories.hardware:
      return Icons.settings_input_component;
    default:
      return Icons.help_outline;
  }
}
