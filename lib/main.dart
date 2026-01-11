import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

import 'background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && Platform.isAndroid) {
    await initializeTrackingService();
  }
  runApp(const TrackerApp());
}

class TrackerApp extends StatelessWidget {
  const TrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Background GPS Tracker',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2A9D8F),
        useMaterial3: true,
      ),
      home: const TrackingScreen(),
    );
  }
}

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final List<Position> _route = [];
  final List<LatLng> _routePoints = [];
  LatLng? _currentPoint;
  final MapController _mapController = MapController();
  final FlutterBackgroundService _service = FlutterBackgroundService();
  StreamSubscription? _locationSub;
  bool _tracking = false;
  String _status = 'Idle';

  @override
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }

  void _listenForLocations() {
    _locationSub?.cancel();
    _locationSub = _service.on('location').listen((event) {
      if (event == null) {
        return;
      }
      final position = Position(
        latitude: (event['lat'] as num).toDouble(),
        longitude: (event['lng'] as num).toDouble(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: (event['heading'] as num?)?.toDouble() ?? 0,
        headingAccuracy: 0,
        speed: (event['speed'] as num?)?.toDouble() ?? 0,
        speedAccuracy: 0,
        timestamp: event['timestamp'] != null
            ? (DateTime.tryParse(event['timestamp'] as String) ?? DateTime.now())
            : DateTime.now(),
      );
      setState(() {
        _route.add(position);
        final point = LatLng(position.latitude, position.longitude);
        _currentPoint = point;
        _routePoints.add(point);
        _status = 'Tracking';
      });
      _mapController.move(
        _currentPoint ?? const LatLng(37.7749, -122.4194),
        _mapController.camera.zoom,
      );
    });
  }

  Future<void> _requestPermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && mounted) {
      setState(() {
        _status = 'Enable location services';
      });
      return;
    }

    await Permission.locationWhenInUse.request();
    await Permission.locationAlways.request();
    await Permission.notification.request();
  }

  Future<void> _requestIgnoreBatteryOptimizations() async {
    await Permission.ignoreBatteryOptimizations.request();
  }

  Future<void> _startTracking() async {
    await _requestPermissions();
    _listenForLocations();
    await startTrackingService();
    setState(() {
      _tracking = true;
      _status = 'Tracking';
    });
  }

  Future<void> _stopTracking() async {
    await stopTrackingService();
    await _locationSub?.cancel();
    setState(() {
      _tracking = false;
      _status = 'Stopped';
    });
  }

  @override
  Widget build(BuildContext context) {
    final last = _route.isNotEmpty ? _route.last : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Background GPS Tracker'),
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: LatLng(37.7749, -122.4194),
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.strava_like',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: const Color(0xFF2A9D8F),
                      strokeWidth: 5,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    if (_currentPoint != null)
                      Marker(
                        point: _currentPoint!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Color(0xFFD7263D),
                          size: 40,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text('Status: $_status'),
            const SizedBox(height: 8),
            Text('Points: ${_route.length}'),
            const SizedBox(height: 8),
            Text(
              last == null
                  ? 'Last: -'
                  : 'Last: ${last.latitude.toStringAsFixed(6)}, '
                    '${last.longitude.toStringAsFixed(6)}',
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: (!kIsWeb && Platform.isAndroid)
                  ? (_tracking ? _stopTracking : _startTracking)
                  : null,
              child: Text(_tracking ? 'Stop Tracking' : 'Start Tracking'),
            ),
            const SizedBox(height: 12),
            if (kIsWeb || !Platform.isAndroid)
              const Text('Android-only: background tracking is disabled on this platform.'),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: (!kIsWeb && Platform.isAndroid)
                  ? _requestIgnoreBatteryOptimizations
                  : null,
              child: const Text('Disable Battery Optimization'),
            ),
            const SizedBox(height: 12),
            if (kIsWeb || !Platform.isAndroid)
              const Text('Android-only: background tracking is disabled on this platform.'),
            const SizedBox(height: 12),
            const Text(
              'Why it works with screen off: a foreground service keeps the '
              'Dart isolate alive and the GPS stream continues in the service, '
              'so updates keep flowing even when the app is minimized or locked.',
            ),
          ],
        ),
          ),
        ],
      ),
    );
  }
}
