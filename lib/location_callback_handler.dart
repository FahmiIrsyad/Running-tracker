import 'dart:isolate';
import 'dart:ui';

import 'package:background_locator_2/location_dto.dart';

class LocationCallbackHandler {
  static const String isolateName = 'LocatorIsolate';

  static void initCallback(Map<String, dynamic> params) {
    return;
  }

  static Future<void> callback(LocationDto locationDto) async {
    final SendPort? send = IsolateNameServer.lookupPortByName(isolateName);
    send?.send(locationDto);
  }

  static Future<void> disposeCallback() async {
    return;
  }
}
