import 'dart:html'; // Yes, still needed for now — safe for web-only use
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:js/js.dart'; // <-- This gives you @JS()

@JS('initMap') // <-- Now this works
external void initMap();

class GoogleMapWidget extends StatelessWidget {
  const GoogleMapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Register a raw HTML div as a platform view
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      'google-maps-html',
      (int viewId) {
        final div = DivElement()
          ..id = 'map'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.border = 'none';
        
        // Delay JS init slightly to ensure DOM is ready
        Future.delayed(const Duration(milliseconds: 10), () {
          initMap();
        });

        return div;
      },
    );

    return const SizedBox(
      width: double.infinity,
      height: 500, // You can adjust height
      child: HtmlElementView(viewType: 'google-maps-html'),
    );
  }
}
