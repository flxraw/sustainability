import 'dart:html';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:js/js.dart';

@JS('initMap')
external void initMap();

class GoogleMapWidget extends StatelessWidget {
  const GoogleMapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      'google-maps-html',
      (int viewId) {
        final div = DivElement()
          ..id = 'map'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.position = 'relative';
        return div;
      },
    );

    return const HtmlElementView(viewType: 'google-maps-html');
  }
}
