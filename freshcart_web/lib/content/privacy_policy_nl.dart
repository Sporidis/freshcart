import 'package:freshcart_web/content/privacy_policy.dart';

/// Het privacybeleid in het Nederlands.
const PrivacyPolicy privacyPolicyNl = PrivacyPolicy(
  languageCode: 'nl',
  title: 'Privacybeleid',
  lastUpdated: 'Laatst bijgewerkt: 30 oktober 2026',
  intro:
      'FreshCart is een gedeelde boodschappenlijst. Deze pagina legt uit '
      'welke persoonsgegevens FreshCart bewaart, waarom, wie ze nog krijgt, '
      'hoe lang ze bewaard worden en wat je ermee kunt doen. FreshCart heeft '
      'geen reclame, geen analytics en geen trackers, en verkoopt je gegevens '
      'nooit.',
  sections: [
    PolicySection('1. Wie is verantwoordelijk', [
      Paragraph(
        '${PolicyFacts.controller}, Roeselare, België, is verantwoordelijk '
        'voor je gegevens (de "verwerkingsverantwoordelijke" volgens de AVG). '
        'Voor elke vraag of elk verzoek over je gegevens: mail naar '
        '${PolicyFacts.contactEmail}.',
      ),
    ]),
    PolicySection('2. Wat we bewaren, en waarom', [
      Bullets([
        'Je account: een willekeurig accountnummer, automatisch aangemaakt '
            'wanneer je de app voor het eerst opent. Als je een e-mailadres '
            'toevoegt, bewaren we dat adres en je wachtwoord, en dat '
            'wachtwoord alleen als veilige (Argon2-)hash. Nodig om de app '
            'voor je te laten werken.',
        'Je profiel: de naam die je kiest, een avatarkleur en, als je er '
            'een toevoegt, een foto. Voor we een foto bewaren, halen we alle '
            'verborgen gegevens eruit (zoals waar en met welk toestel hij '
            'genomen is). Iedereen met de link kan de foto openen, en de '
            'leden van je lijsten zien hem.',
        'Je lijsten: de lijsten, items, notities en winkels die je maakt, en '
            'wie een item toevoegde of afvinkte. Gedeeld met de andere leden '
            'van elke lijst, want daarvoor is de app.',
        'Meldingen: als je ze toestaat, een technisch adres voor je telefoon '
            '(een pushtoken) en je meldingsinstellingen. Op basis van je '
            'toestemming, die je altijd kunt intrekken in de instellingen '
            'van je telefoon.',
        'Bescherming tegen misbruik: je IP-adres, kort, om te beperken '
            'hoeveel accounts en hoeveel foute deelcodes van één plek kunnen '
            'komen. Op basis van ons gerechtvaardigd belang om lijsten te '
            'beschermen tegen raden.',
      ]),
      Paragraph(
        'De rechtsgrond om de app te laten werken (account, profiel, lijsten) '
        'is de overeenkomst tussen jou en FreshCart wanneer je de app '
        'gebruikt (AVG art. 6, lid 1, b); voor meldingen is dat je '
        'toestemming (art. 6, lid 1, a); voor de bescherming tegen misbruik '
        'ons gerechtvaardigd belang (art. 6, lid 1, f).',
      ),
    ]),
    PolicySection('3. Wie ze nog krijgt', [
      Paragraph(
        'Alleen de diensten die nodig zijn om FreshCart te laten werken, '
        'elk alleen voor hun taak:',
      ),
      Bullets([
        'Hosting: de server en de database draaien bij '
            '${PolicyFacts.hosting}.',
        'Brevo (Parijs, Frankrijk): verstuurt de verificatiecodes wanneer je '
            'een e-mailadres toevoegt. Krijgt je e-mailadres en de code.',
        'Google Firebase Cloud Messaging: bezorgt meldingen op '
            'Android-telefoons. Krijgt je pushtoken en de melding. Google kan '
            'dit buiten de EU verwerken; het is gecertificeerd onder het '
            'EU-VS Data Privacy Framework.',
        'Apple Push Notification service: bezorgt meldingen op iPhones, '
            'onder dezelfde voorwaarden.',
        'De andere leden van je lijsten zien je naam, je foto en wat je op '
            'die lijsten toevoegt of afvinkt.',
      ]),
    ]),
    PolicySection('4. Hoe lang we ze bewaren', [
      Bullets([
        'Je account en de gegevens ervan: tot je je account verwijdert.',
        'Een account zonder e-mailadres dat een jaar niet gebruikt wordt: na '
            'een jaar zonder gebruik kan het niet meer geopend worden, dus '
            'wordt het automatisch verwijderd, met dezelfde regels als '
            'wanneer je het zelf verwijdert.',
        'IP-adressen voor de bescherming tegen misbruik: hoogstens een uur.',
        'Pushtokens: tot je je afmeldt, je account verwijdert of je telefoon '
            'ze niet meer aanvaardt.',
      ]),
    ]),
    PolicySection('5. Je account verwijderen', [
      Paragraph(
        'Ga in de app naar Instellingen en kies "Account verwijderen". Je '
        'naam, foto, login, instellingen en de lijsten waar alleen jij op '
        'staat, worden definitief verwijderd. Gedeelde lijsten blijven voor '
        'de andere leden; items die jij toevoegde, blijven erop staan, zonder '
        'je naam. Ben je eigenaar van een gedeelde lijst, dan wordt het lid '
        'dat er het eerst bij kwam de nieuwe eigenaar.',
      ),
    ]),
    PolicySection('6. Je rechten', [
      Paragraph(
        'Je hebt het recht om je gegevens in te zien, ze te laten '
        'verbeteren, ze te laten verwijderen, ze te krijgen in een leesbaar '
        'formaat voor computers, bezwaar te maken tegen het gebruik ervan en '
        'het te laten beperken, en je toestemming in te trekken. Je naam en '
        'foto aanpassen en je account verwijderen kan je zelf in de app; voor '
        'al de rest mail je naar ${PolicyFacts.contactEmail}. We antwoorden '
        'binnen een maand.',
      ),
      Paragraph(
        'We moeten zeker zijn dat een verzoek van de eigenaar van het account '
        'komt. Een account zonder e-mailadres kan alleen vanuit de app zelf '
        'bewezen worden; voor zo\'n verzoek kunnen we je dus eerst vragen om '
        'in de app een e-mailadres toe te voegen.',
      ),
      Paragraph(
        'Je kan ook een klacht indienen bij de Belgische '
        'Gegevensbeschermingsautoriteit '
        '(www.gegevensbeschermingsautoriteit.be).',
      ),
    ]),
    PolicySection('7. Beveiliging', [
      Paragraph(
        'Wachtwoorden worden alleen als veilige hash bewaard, afmelden en je '
        'account verwijderen beëindigen je sessie ook op de server, foto\'s '
        'worden ontdaan van verborgen gegevens, en deelcodes vervallen na een '
        'dag en zijn beschermd tegen raden.',
      ),
    ]),
    PolicySection('8. Deze website', [
      Paragraph(
        'Deze website plaatst geen cookies en gebruikt geen analytics, '
        'trackers of lettertypes van andere bedrijven. Zoals bij elke website '
        'ziet de server je IP-adres wanneer je een pagina opent.',
      ),
    ]),
    PolicySection('9. Kinderen', [
      Paragraph('FreshCart is niet bedoeld voor kinderen jonger dan 13.'),
    ]),
    PolicySection('10. Wijzigingen', [
      Paragraph(
        'Als dit beleid verandert, wordt de nieuwe versie hier gepubliceerd, '
        'met een nieuwe datum.',
      ),
    ]),
  ],
);
