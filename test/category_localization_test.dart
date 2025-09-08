import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:quick_start/utils/category_localization_helper.dart';
import 'package:quick_start/services/database_service.dart';
import 'package:quick_start/models/category.dart';

void main() {
  group('CategoryLocalizationHelper Tests', () {
    testWidgets('should return localized desktop category name in Chinese', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('en'),
            Locale('zh'),
          ],
          home: Builder(
            builder: (BuildContext context) {
              final localizedName = CategoryLocalizationHelper.getLocalizedCategoryName(
                context,
                DatabaseService.defaultDesktopCategoryName,
              );
              
              expect(localizedName, '桌面');
              
              return Container();
            },
          ),
        ),
      );
      
      await tester.pump();
    });

    testWidgets('should return localized desktop category name in English', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('en'),
            Locale('zh'),
          ],
          home: Builder(
            builder: (BuildContext context) {
              final localizedName = CategoryLocalizationHelper.getLocalizedCategoryName(
                context,
                DatabaseService.defaultDesktopCategoryName,
              );
              
              expect(localizedName, 'Desktop');
              
              return Container();
            },
          ),
        ),
      );
      
      await tester.pump();
    });

    testWidgets('should return original name for custom categories', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('en'),
            Locale('zh'),
          ],
          home: Builder(
            builder: (BuildContext context) {
              final customCategoryName = '工作';
              final localizedName = CategoryLocalizationHelper.getLocalizedCategoryName(
                context,
                customCategoryName,
              );
              
              expect(localizedName, customCategoryName);
              
              return Container();
            },
          ),
        ),
      );
      
      await tester.pump();
    });

    test('should correctly identify desktop category', () {
      expect(CategoryLocalizationHelper.isDesktopCategory(DatabaseService.defaultDesktopCategoryName), true);
      expect(CategoryLocalizationHelper.isDesktopCategory('工作'), false);
      expect(CategoryLocalizationHelper.isDesktopCategory('Games'), false);
    });

    test('should correctly identify desktop category from Category object', () {
      final desktopCategory = Category(
        name: DatabaseService.defaultDesktopCategoryName,
        iconResource: 'icon:desktop_windows',
      );
      
      final customCategory = Category(
        name: '工作',
        iconResource: 'icon:work',
      );
      
      expect(CategoryLocalizationHelper.isDesktopCategoryFromCategory(desktopCategory), true);
      expect(CategoryLocalizationHelper.isDesktopCategoryFromCategory(customCategory), false);
    });
  });
}