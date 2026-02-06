import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

TileLayer get openStreetMapTileLayer => TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'dev.realk.adaptive_dashboard',
    );

class FlutterMapTestWidget extends StatelessWidget {
  const FlutterMapTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(),
      children: [
        openStreetMapTileLayer,
      ],
    );
  }
}
