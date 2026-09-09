import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(configurePluralResolvers);

  group('locales', () {
    test('ships nl, en, fr, ru and tl, with nl as the base', () {
      expect(
        AppLocale.values.map((l) => l.languageCode),
        containsAll(<String>['nl', 'en', 'fr', 'ru', 'tl']),
      );
      expect(AppLocale.nl, AppLocale.values.first);
    });

    test('every locale resolves the same keys', () {
      // slang's fallback_strategy means a missing key falls back to nl rather
      // than throwing, so this asserts each locale actually carries its own
      // translation instead of silently inheriting Dutch.
      for (final locale in AppLocale.values) {
        final t = translationsFor(locale);
        expect(t.lists.title, isNotEmpty, reason: locale.languageCode);
        expect(t.items.add, isNotEmpty, reason: locale.languageCode);
        expect(t.errors.conflict, isNotEmpty, reason: locale.languageCode);
        if (locale != AppLocale.nl) {
          expect(
            t.lists.title,
            isNot(translationsFor(AppLocale.nl).lists.title),
            reason: '${locale.languageCode} should not fall back to Dutch',
          );
        }
      }
    });
  });

  group('pluralisation', () {
    test('English uses one/other', () {
      final t = translationsFor(AppLocale.en);
      expect(t.lists.memberCount(n: 1), '1 member');
      expect(t.lists.memberCount(n: 2), '2 members');
      expect(t.lists.memberCount(n: 0), '0 members');
    });

    test('Russian picks the right form out of four', () {
      // The reason memberCount is a plural rather than a plain string: Russian
      // has one/few/many categories, so "5 участник" would be visibly wrong.
      final t = translationsFor(AppLocale.ru);
      expect(t.lists.memberCount(n: 1), '1 участник');
      expect(t.lists.memberCount(n: 2), '2 участника');
      expect(t.lists.memberCount(n: 5), '5 участников');
      expect(t.lists.memberCount(n: 11), '11 участников');
      expect(t.lists.memberCount(n: 21), '21 участник');
      expect(t.lists.memberCount(n: 22), '22 участника');
    });

    test('Dutch and French agree on one/other', () {
      expect(translationsFor(AppLocale.nl).lists.memberCount(n: 1), '1 lid');
      expect(translationsFor(AppLocale.nl).lists.memberCount(n: 3), '3 leden');
      expect(translationsFor(AppLocale.fr).lists.memberCount(n: 1), '1 membre');
      expect(
        translationsFor(AppLocale.fr).lists.memberCount(n: 3),
        '3 membres',
      );
    });

    test('Tagalog follows the CLDR last-digit rule, not the fallback', () {
      // slang ships no resolver for tl, so without configurePluralResolvers
      // this would use the tolerant fallback (one only for n == 1) and get
      // every one of these wrong except 1 and 3.
      final t = translationsFor(AppLocale.tl);
      expect(t.lists.memberCount(n: 1), '1 miyembro');
      expect(t.lists.memberCount(n: 3), '3 miyembro');
      expect(t.lists.memberCount(n: 5), '5 miyembro');
      expect(t.lists.memberCount(n: 10), '10 miyembro');
      // Integers ending in 4, 6 or 9 take `other`.
      expect(t.lists.memberCount(n: 4), '4 na miyembro');
      expect(t.lists.memberCount(n: 6), '6 na miyembro');
      expect(t.lists.memberCount(n: 9), '9 na miyembro');
      expect(t.lists.memberCount(n: 14), '14 na miyembro');
    });

    test('Dutch uses an explicitly registered resolver, not a fallback', () {
      final t = translationsFor(AppLocale.nl);
      expect(t.lists.memberCount(n: 0), '0 leden');
      expect(t.lists.memberCount(n: 1), '1 lid');
      expect(t.lists.memberCount(n: 2), '2 leden');
    });
  });

  group('interpolation', () {
    test('named parameters substitute in every locale', () {
      for (final locale in AppLocale.values) {
        expect(
          translationsFor(locale).items.checkedBy(name: 'Mom'),
          contains('Mom'),
        );
      }
    });
  });
}
