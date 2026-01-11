import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';

const String kChannelId = 'tracking_channel';
const int kNotificationId = 7788;

Future<void> initializeTrackingService() async {
  if (kIsWeb || !Platform.isAndroid) {
    return;
  }

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    kChannelId,
    'Tracking Service',
    description: 'Persistent notification for background tracking',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await notificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('ic_bg_service_small'),
    ),
  );

  await notificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  final service = FlutterBackgroundService();
  await service.configure(
    iosConfiguration: IosConfiguration(
      autoStart: false,
    ),
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: kChannelId,
      initialNotificationTitle: 'Tracking active',
      initialNotificationContent: 'Recording GPS route in background',
      foregroundServiceNotificationId: kNotificationId,
      foregroundServiceTypes: [AndroidForegroundType.location],
    ),
  );
}

Future<void> startTrackingService() async {
  if (kIsWeb || !Platform.isAndroid) {
    return;
  }
  final service = FlutterBackgroundService();
  await service.startService();
}

Future<void> stopTrackingService() async {
  if (kIsWeb || !Platform.isAndroid) {
    return;
  }
  final service = FlutterBackgroundService();
  service.invoke('stopTracking');
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
    service.setForegroundNotificationInfo(
      title: 'Tracking active',
      content: 'Recording GPS route in background',
    );
  }

  StreamSubscription<Position>? subscription;

  service.on('stopTracking').listen((_) async {
    await subscription?.cancel();
    service.stopSelf();
  });

  final locationSettings = AndroidSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 5,
    intervalDuration: const Duration(seconds: 2),
  );

  subscription = Geolocator.getPositionStream(
    locationSettings: locationSettings,
  ).listen((position) {
    service.invoke('location', {
      'lat': position.latitude,
      'lng': position.longitude,
      'speed': position.speed,
      'heading': position.heading,
      'timestamp': position.timestamp?.toIso8601String(),
    });
  });
}
