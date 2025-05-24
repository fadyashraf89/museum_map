import 'package:flutter/material.dart';
import 'package:museum_map/Scanning_Widget.dart';
import 'package:sizer/sizer.dart';

import 'first_floor.dart';

class InteractiveMap extends StatelessWidget {
  const InteractiveMap({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Museum Map',
          theme: ThemeData(primarySwatch: Colors.blue),
          home: const FirstFloorPlanSketch(),
        );
      },
    );
  }
}
