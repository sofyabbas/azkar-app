import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  double? _qiblaDirection;
  bool _hasPermissions = false;

  @override
  void initState() {
    super.initState();
    _fetchQiblaDirection();
  }

  Future<void> _fetchQiblaDirection() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      setState(() => _hasPermissions = true);

      final position = await Geolocator.getCurrentPosition();
      final coordinates = Coordinates(position.latitude, position.longitude);
      final qibla = Qibla(coordinates);

      setState(() {
        _qiblaDirection = qibla.direction;
      });
    } catch (e) {
      debugPrint("Error fetching location for Qibla: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('القبلة', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Builder(
        builder: (context) {
          if (!_hasPermissions) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_disabled, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('الرجاء تفعيل خدمات الموقع وتحديث الصلاحيات'),
                  ElevatedButton(
                    onPressed: _fetchQiblaDirection,
                    child: const Text('تحديث'),
                  )
                ],
              ),
            );
          }

          if (_qiblaDirection == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<CompassEvent>(
            stream: FlutterCompass.events,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('خطأ في قراءة البوصلة: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              double? heading = snapshot.data?.heading;

              if (heading == null) {
                return const Center(child: Text('جهازك لا يدعم مستشعر البوصلة.'));
              }

              // The angle between current heading and Qibla direction
              final qiblaAngle = (_qiblaDirection! - heading) * (math.pi / 180) * -1;

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'اتجاه القبلة بالنسبة لموقعك الحالي',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 48),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.rotate(
                          angle: heading * (math.pi / 180) * -1,
                          child: Icon(
                            Icons.explore_outlined,
                            size: 300,
                            color: Colors.grey[300],
                          ),
                        ),
                        Transform.rotate(
                          angle: qiblaAngle,
                          child: Icon(
                            Icons.navigation,
                            size: 150,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    Text(
                      'ضع هاتفك بشكل مسطح للحصول على دقة أفضل',
                      style: TextStyle(color: Colors.grey[600]),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
