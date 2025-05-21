import 'dart:html';
import 'dart:ui' as ui;
import 'dart:js' as js;
import 'package:flutter/material.dart';

class PlatformMap extends StatelessWidget {
  const PlatformMap({super.key});

  @override
  Widget build(BuildContext context) {
    const viewType = 'google-maps-html';

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final containerId = 'map-container-$viewId';

      final container =
          DivElement()
            ..id = containerId
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.border = 'none'
            ..text = 'Loading map...';

      final token = window.localStorage['MAP_CREDENTIAL'];
      final callbackName = 'initMapCallback$viewId';

      if (token != null && token.trim().isNotEmpty) {
        // Only inject if not already injected
        final existing = document.querySelectorAll(
          'script[src*="maps.googleapis.com/maps/api/js"]',
        );
        if (existing.isEmpty) {
          // Define callback to init map once script loads
          js.context[callbackName] = js.allowInterop(() {
            final mapOptions = js.JsObject.jsify({
              'center': js.JsObject.jsify({'lat': 48.137154, 'lng': 11.576124}),
              'zoom': 14,
            });

            final mapConstructor = js.context['google']['maps']['Map'];
            mapConstructor.callMethod('call', [
              null,
              document.getElementById(containerId),
              mapOptions,
            ]);

            container.text = ''; // Clear loading text
          });

          // Inject script
          final script =
              ScriptElement()
                ..type = 'text/javascript'
                ..async = true
                ..defer = true
                ..src =
                    'https://maps.googleapis.com/maps/api/js?key=$token&callback=$callbackName';

          document.head!.append(script);
        } else {
          container.text = '🟡 Google Maps script already injected.';
        }
      } else {
        container.text = '❌ Missing MAP_CREDENTIAL in localStorage.';
        container.style.color = 'red';
      }

      return container;
    });

    return const HtmlElementView(viewType: viewType);
  }
}
