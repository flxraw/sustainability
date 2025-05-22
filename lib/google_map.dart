// google_map.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Nur für Web:
/// `dart:html` ist nur auf Flutter Web erlaubt
/// `dart:ui` Zugriff nur über `dart:ui_web`-Schnittstelle
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'dart:ui' as ui;

import 'package:js/js.dart';

@JS('initMap')
external void initMap();

class GoogleMapWidget extends StatelessWidget {
  const GoogleMapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // 🔧 Nur auf Web registrieren
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(
        'google-maps-html',
        (int viewId) {
          final div = html.DivElement()
            ..id = 'map'
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.border = 'none';

          Future.delayed(const Duration(milliseconds: 10), () {
            initMap();
          });

          return div;
        },
      );

      return const SizedBox(
        width: double.infinity,
        height: 500,
        child: HtmlElementView(viewType: 'google-maps-html'),
      );
    } else {
      return const Center(child: Text("Google Maps nur im Web verfügbar."));
    }
  }
}
