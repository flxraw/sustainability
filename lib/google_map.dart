import 'dart:html';
import 'dart:js' as js;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PlatformMap extends StatelessWidget {
  const PlatformMap({super.key});

  @override
  Widget build(BuildContext context) {
    const viewType = 'google-maps-html';

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final container =
          DivElement()
            ..id = 'map'
            ..style.width = '100%'
            ..style.height = '100%';

      final apiKey = dotenv.env['google_nerv'];
      final callbackName = 'initMapCallback$viewId';

      js.context[callbackName] = js.allowInterop(() {
        final mapOptions = js.JsObject.jsify({
          'center': js.JsObject.jsify({'lat': 48.137154, 'lng': 11.576124}),
          'zoom': 14,
        });
        final mapConstructor = js.context['google']['maps']['Map'];
        mapConstructor.callMethod('call', [null, container, mapOptions]);
      });

      ScriptElement script =
          ScriptElement()
            ..type = 'text/javascript'
            ..async = true
            ..defer = true
            ..src =
                'https://maps.googleapis.com/maps/api/js?key=$apiKey&callback=$callbackName';
      document.head!.append(script);

      return container;
    });

    return const HtmlElementView(viewType: viewType);
  }
}
