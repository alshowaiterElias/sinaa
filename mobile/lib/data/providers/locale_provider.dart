import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/local_storage.dart';

// Locale notifier using Riverpod 3.x Notifier
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    // Load saved locale asynchronously
    _loadSavedLocale();
    // Return default locale
    return const Locale('ar');
  }

  Future<void> _loadSavedLocale() async {
    final storage = ref.read(localStorageProvider);
    final languageCode = await storage.getLanguage();
    state = Locale(languageCode);
  }

  Future<void> setLocale(Locale locale) async {
    final storage = ref.read(localStorageProvider);
    await storage.saveLanguage(locale.languageCode);
    state = locale;
  }

  Future<void> toggleLocale() async {
    final newLocale =
        state.languageCode == 'ar' ? const Locale('en') : const Locale('ar');
    await setLocale(newLocale);
  }
}

// Providers
final localeProvider = NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});

// Helper to check if current locale is RTL
final isRtlProvider = Provider<bool>((ref) {
  final locale = ref.watch(localeProvider);
  return locale.languageCode == 'ar';
});
