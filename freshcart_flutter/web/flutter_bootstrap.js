{{flutter_js}}
{{flutter_build_config}}

// The FreshCart web demo (lib/main_demo.dart) is embedded in another page.
// That page defines `window.freshcartDemo` and starts Flutter itself, in
// multi-view mode (docs/web-demo-plan.md, decisions.md #109).
//
// Every other page (the PWA's index.html) starts exactly like Flutter's own
// generated bootstrap: the `else` branch is a copy of it
// (flutter_tools generateDefaultFlutterBootstrapScript).
if (window.freshcartDemo) {
  window.freshcartDemo.boot(_flutter);
} else {
  _flutter.loader.load({
    serviceWorkerSettings: {
      serviceWorkerVersion: {{flutter_service_worker_version}}
    }
  });
}
