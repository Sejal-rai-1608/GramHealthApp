import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruralcare_flutter/l10n/app_language.dart';
import 'package:ruralcare_flutter/screens/login_screen.dart';
import 'package:ruralcare_flutter/theme/app_theme.dart';

void main() {
  testWidgets('LoginScreen renders and switches languages correctly', (WidgetTester tester) async {
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
    expect(find.text('Welcome Back'), findsOneWidget);

    // Switch to Hindi
    LanguageController.instance.setLanguage(AppLanguage.hindi);
    await tester.pumpAndSettle();
    expect(find.text('स्वागत है'), findsOneWidget);

    // Switch to Marathi
    LanguageController.instance.setLanguage(AppLanguage.marathi);
    await tester.pumpAndSettle();
    expect(find.text('पुन्हा स्वागत आहे'), findsOneWidget);

    // Switch to Gujarati
    LanguageController.instance.setLanguage(AppLanguage.gujarati);
    await tester.pumpAndSettle();
    expect(find.text('સ્વાગત છે'), findsOneWidget);
  });
}
