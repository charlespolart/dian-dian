import 'package:flutter/services.dart';

/// The app's tablet threshold (also used by the tracker layout).
const tabletMinShortestSideDp = 600.0;

/// Phones are locked to portrait: landscape shows too little of the grid,
/// and a phone read in bed should not flip. Tablets keep every orientation
/// (`null` = no lock; Info.plist / the manifest stay the upper bound).
List<DeviceOrientation>? preferredOrientationsFor(double shortestSideDp) =>
    shortestSideDp < tabletMinShortestSideDp ? const [DeviceOrientation.portraitUp] : null;
