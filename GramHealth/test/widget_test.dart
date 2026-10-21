import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruralcare_flutter/l10n/app_language.dart';
import 'package:ruralcare_flutter/l10n/translations.dart';
import 'package:ruralcare_flutter/screens/common/login_screen.dart';
import 'package:ruralcare_flutter/theme/app_theme.dart';

/// Reads the expected string straight from the translation table so the
/// assertion can never drift from the shipped copy (and never depends on the
/// file encoding of non-Latin scripts).
String tr(String code, String lang) => kTranslations[lang]![code]!;

void main() {
  testWidgets('LoginScreen renders and switches languages correctly',
      (WidgetTester tester) async {
    LanguageController.instance.setLanguage(AppLanguage.english);

    await tester.pumpWidget(
      ValueListenableBuilder<AppLanguage>(
        valueListenable: LanguageController.instance.currentLanguage,
        builder: (context, lang, child) {
          return MaterialApp(
            key: ValueKey(lang.code),
            theme: AppTheme.theme,
            locale: lang.locale,
            home: LoginScreen(key: ValueKey(lang.code)),
          );
        },
      ),
    );

    // English
    expect(find.text(tr('welcome_back', 'en')), findsOneWidget);

    // Switch to Hindi
    LanguageController.instance.setLanguage(AppLanguage.hindi);
    await tester.pumpAndSettle();
    expect(find.text(tr('welcome_back', 'hi')), findsOneWidget);

    // Switch to Marathi
    LanguageController.instance.setLanguage(AppLanguage.marathi);
    await tester.pumpAndSettle();
    expect(find.text(tr('welcome_back', 'mr')), findsOneWidget);

    // Switch to Gujarati
    LanguageController.instance.setLanguage(AppLanguage.gujarati);
    await tester.pumpAndSettle();
    expect(find.text(tr('welcome_back', 'gu')), findsOneWidget);

    // Back to English
    LanguageController.instance.setLanguage(AppLanguage.english);
    await tester.pumpAndSettle();
    expect(find.text(tr('welcome_back', 'en')), findsOneWidget);
  });
}
