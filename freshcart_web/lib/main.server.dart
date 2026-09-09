/// The entrypoint for the **server** environment.
///
/// The [main] method will only be executed on the server during pre-rendering.
/// To run code on the client, check the `main.client.dart` file.
library;

// Imports the [App] component.
import 'package:freshcart_web/app.dart';
// This file is generated automatically by Jaspr, do not remove or edit.
import 'package:freshcart_web/main.server.options.dart';
import 'package:jaspr/dom.dart';
// Server-specific Jaspr import.
import 'package:jaspr/server.dart';

void main() {
  // Initializes the server environment with the generated default options.
  Jaspr.initializeApp(
    options: defaultServerOptions,
  );

  // Starts the app.
  //
  // [Document] renders the root document structure (<html>, <head> and <body>)
  // with the provided parameters and components.
  runApp(
    const Document(
      title: 'FreshCart',
      lang: 'en',
      meta: {
        'description':
            'A shared shopping list your whole household actually keeps up '
            'to date.',
        'viewport': 'width=device-width, initial-scale=1',
      },
      head: [
        link(rel: 'stylesheet', href: 'styles.css'),
      ],
      body: App(),
    ),
  );
}
