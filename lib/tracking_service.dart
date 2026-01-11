import 'dart:ui';

import 'package:background_locator_2/background_locator.dart';
import 'package:background_locator_2/settings/android_settings.dart';
import 'package:background_locator_2/settings/ios_settings.dart';
import 'package:background_locator_2/settings/locator_settings.dart';

import 'location_callback_handler.dart';

class TrackingService {
  static Future<void> start() async {
    final isRunning = await BackgroundLocator.isServiceRunning();
    if (isRunning) {
      return;
    }

    await BackgroundLocator.registerLocationUpdate(
      LocationCallbackHandler.callback,
      initCallback: LocationCallbackHandler.initCallback,
      disposeCallback: LocationCallbackHandler.disposeCallback,
      autoStop: false,
      iosSettings: const IOSSettings(
        accuracy: LocationAccuracy.NAVIGATION,
        distanceFilter: 5,
        stopWithTerminate: false,
      ),
      androidSettings: const AndroidSettings(
        accuracy: LocationAccuracy.NAVIGATION,
        interval: 2000,
        distanceFilter: 5,
        client: LocationClient.google,
        androidNotificationSettings: AndroidNotificationSettings(
          notificationChannelName: 'Ride tracking',
          notificationTitle: 'Ride in progress',
          notificationMsg: 'Tracking your route in the background',
          notificationBigMsg:
              'Tracking continues even when the screen is off.',
          notificationIconColor: const Color(0xFFFC4C02),
        ),
      ),
    );
  }

  static Future<void> stop() async {
    final isRunning = await BackgroundLocator.isServiceRunning();
    if (!isRunning) {
      return;
    }
    await BackgroundLocator.unRegisterLocationUpdate();
  }
}
