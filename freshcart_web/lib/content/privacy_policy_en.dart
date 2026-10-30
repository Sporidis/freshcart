import 'package:freshcart_web/content/privacy_policy.dart';

/// The privacy policy in English.
const PrivacyPolicy privacyPolicyEn = PrivacyPolicy(
  languageCode: 'en',
  title: 'Privacy policy',
  lastUpdated: 'Last updated: 30 October 2026',
  intro:
      'FreshCart is a shared shopping list. This page explains which '
      'personal data FreshCart keeps, why, who else receives it, how long it '
      'is kept, and what you can do about it. FreshCart has no advertising, '
      'no analytics and no trackers, and never sells your data.',
  sections: [
    PolicySection('1. Who is responsible', [
      Paragraph(
        '${PolicyFacts.controller}, ${PolicyFacts.place}, is responsible for '
        'your data (the "controller" under the GDPR). For any question or '
        'request about your data, email ${PolicyFacts.contactEmail}.',
      ),
    ]),
    PolicySection('2. What we keep, and why', [
      Bullets([
        'Your account: a random account number, created automatically the '
            'first time you open the app. If you add an email address, we '
            'keep that address and your password, stored only as a secure '
            '(Argon2) hash. Needed to run the app for you.',
        'Your profile: the name you choose, an avatar colour and, if you '
            'add one, a photo. Before storing a photo we remove all its '
            'hidden data (such as where and on which device it was taken). '
            'The photo can be opened by anyone who has its link, and is shown '
            'to the people on your lists.',
        'Your lists: the lists, items, notes and shops you create, and who '
            'added or checked off an item. Shared with the other members of '
            'each list, which is what the app is for.',
        'Notifications: if you allow them, a technical address for your '
            'phone (a push token) and your notification settings. Based on '
            'your permission, which you can withdraw in your phone\'s '
            'settings at any time.',
        'Protection against abuse: your IP address, briefly, to limit how '
            'many accounts and how many wrong join codes can come from one '
            'place. Based on our legitimate interest in keeping lists safe '
            'from guessing.',
      ]),
      Paragraph(
        'The legal basis for running the app (account, profile, lists) is '
        'the agreement between you and FreshCart when you use it (GDPR '
        'Art. 6(1)(b)); for notifications it is your consent (Art. 6(1)(a)); '
        'for abuse protection our legitimate interest (Art. 6(1)(f)).',
      ),
    ]),
    PolicySection('3. Who else receives it', [
      Paragraph(
        'Only the services needed to run FreshCart, each only for its task:',
      ),
      Bullets([
        'Hosting: the server and database run at ${PolicyFacts.hosting}, '
            'in Amsterdam, the Netherlands. Your data stays in the EU.',
        'Brevo (Paris, France): sends the verification codes when you add an '
            'email address. Receives your email address and the code.',
        'Google Firebase Cloud Messaging: delivers notifications to Android '
            'phones. Receives your push token and the notification. Google '
            'may process this outside the EU; it is certified under the '
            'EU-U.S. Data Privacy Framework.',
        'Apple Push Notification service: delivers notifications to '
            'iPhones, under the same conditions.',
        'The other members of your lists see your name, photo and what you '
            'add or check off on those lists.',
      ]),
    ]),
    PolicySection('4. How long we keep it', [
      Bullets([
        'Your account and its data: until you delete your account.',
        'An account without an email address that is not used for a year: '
            'after a year without use it can no longer be opened, so it is '
            'deleted automatically, with the same rules as deleting it '
            'yourself.',
        'IP addresses for abuse protection: at most an hour.',
        'Push tokens: until you sign out, delete your account, or your '
            'phone no longer accepts them.',
      ]),
    ]),
    PolicySection('5. Deleting your account', [
      Paragraph(
        'In the app, go to Settings and choose "Delete account". Your name, '
        'photo, login, settings and lists that only you are on are deleted '
        'for good. Lists you share stay for the other members; items you '
        'added stay on them, without your name. If you own a shared list, '
        'the member who joined it first becomes its owner.',
      ),
    ]),
    PolicySection('6. Your rights', [
      Paragraph(
        'You have the right to see your data, to correct it, to have it '
        'deleted, to receive it in a machine-readable format, to object to '
        'and limit its use, and to withdraw your consent. You can change '
        'your name and photo and delete your account in the app yourself; '
        'for anything else, email ${PolicyFacts.contactEmail}. We answer '
        'within a month.',
      ),
      Paragraph(
        'We have to be sure a request comes from the account\'s owner. An '
        'account without an email address can only be proven from the app '
        'itself, so for such a request we may first ask you to add an email '
        'address in the app.',
      ),
      Paragraph(
        'You can also complain to the Belgian Data Protection Authority '
        '(Gegevensbeschermingsautoriteit, www.dataprotectionauthority.be).',
      ),
    ]),
    PolicySection('7. Security', [
      Paragraph(
        'Passwords are stored only as secure hashes, sign-out and account '
        'deletion end your session on the server, photos are stripped of '
        'hidden data, and join codes expire after a day and are protected '
        'against guessing.',
      ),
    ]),
    PolicySection('8. This website', [
      Paragraph(
        'This website sets no cookies and uses no analytics, trackers or '
        'fonts from other companies. Like any website, the server sees your '
        'IP address when you open a page.',
      ),
    ]),
    PolicySection('9. Children', [
      Paragraph('FreshCart is not meant for children under 13.'),
    ]),
    PolicySection('10. Changes', [
      Paragraph(
        'If this policy changes, the new version is published here with a '
        'new date.',
      ),
    ]),
  ],
);
