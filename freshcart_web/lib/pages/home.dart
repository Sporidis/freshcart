import 'package:freshcart_web/components/counter.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

// By using the @client annotation this component will be automatically compiled to javascript and mounted
// on the client. Therefore:
// - this file and any imported file must be compilable for both server and client environments.
// - this component and any child components will be built once on the server during pre-rendering and then
//   again on the client during normal rendering.
@client
class Home extends StatefulComponent {
  const Home({super.key});

  @override
  State<Home> createState() => HomeState();
}

/// State for [Home].
///
/// A `@client` component has no `main()` on the client, so any client-side
/// initialisation logic belongs in `initState` here — this component is mounted
/// once at the root of the client-side tree. Guard such work with `kIsWeb` when
/// it must not run during server pre-rendering.
class HomeState extends State<Home> {
  @override
  Component build(BuildContext context) {
    return section([
      const img(src: 'images/logo.svg', width: 80),
      const h1([.text('Welcome')]),
      const p([.text('You successfully create a new Jaspr site.')]),
      div(styles: Styles(height: 100.px), []),
      const Counter(),
    ]);
  }
}
