import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import 'package:provider/provider.dart';
import '../providers/prayer_provider.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String _errorMessage = '';
  
  double? _qiblaDirection; // Angle in degrees relative to North (0-360)
  double? _heading;        // Current device compass heading (0-360)
  double? _latitude;
  double? _longitude;
  String _locationName = '';

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndGetLocation();
  }

  Future<void> _checkPermissionsAndGetLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'خدمة الموقع معطلة. يرجى تفعيل GPS لتحديد القبلة.';
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'تم رفض الإذن بالحصول على الموقع.';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'صلاحيات الموقع مرفوضة دائمًا. يرجى تفعيلها من إعدادات الجهاز.';
          _isLoading = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      _latitude = position.latitude;
      _longitude = position.longitude;

      // Calculate Qibla direction using Adhan package
      final coordinates = Coordinates(_latitude!, _longitude!);
      final qibla = Qibla(coordinates);
      _qiblaDirection = qibla.direction;

      if (mounted) {
        final prayerProvider = Provider.of<PrayerProvider>(context, listen: false);
        _locationName = prayerProvider.locationName.isNotEmpty
            ? prayerProvider.locationName
            : '${_latitude!.toStringAsFixed(2)}°, ${_longitude!.toStringAsFixed(2)}°';
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      // Fallback to PrayerProvider data if available
      if (mounted) {
        final prayerProvider = Provider.of<PrayerProvider>(context, listen: false);
        if (prayerProvider.prayerTimes != null) {
          final coords = prayerProvider.prayerTimes!.coordinates;
          final qibla = Qibla(coords);
          setState(() {
            _latitude = coords.latitude;
            _longitude = coords.longitude;
            _qiblaDirection = qibla.direction;
            _locationName = prayerProvider.locationName;
            _isLoading = false;
          });
          return;
        }
      }

      setState(() {
        _errorMessage = 'تعذر تحديد موقع الجهاز: $e';
        _isLoading = false;
      });
    }
  }

  // Calculate shortest angle difference between Qibla and Heading (-180 to +180)
  double _getAngleDifference(double qibla, double heading) {
    double diff = (qibla - heading) % 360;
    if (diff < -180) diff += 360;
    if (diff > 180) diff -= 360;
    return diff;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'اتجاه القبلة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث الموقع',
            onPressed: _checkPermissionsAndGetLocation,
          ),
        ],
      ),
      body: _buildContent(theme, isDark),
    );
  }

  Widget _buildContent(ThemeData theme, bool isDark) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جاري تحديد موقعك وزاوية القبلة...'),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off_outlined, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _checkPermissionsAndGetLocation,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('خطأ في حساس البوصلة: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('جاري الاتصال بحساس البوصلة...'),
              ],
            ),
          );
        }

        final compassEvent = snapshot.data;
        if (compassEvent == null || compassEvent.heading == null) {
          return _buildNoCompassFallback(theme);
        }

        _heading = compassEvent.heading;
        final double qiblaAngle = _qiblaDirection ?? 0.0;
        final double headingAngle = _heading!;
        final double diff = _getAngleDifference(qiblaAngle, headingAngle);
        final bool isAligned = diff.abs() <= 3.5;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Location Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _locationName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Status Badge (Aligned or Turning)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isAligned
                      ? Colors.green.shade600
                      : theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: isAligned
                      ? [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.5),
                            blurRadius: 16,
                            spreadRadius: 2,
                          )
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAligned ? Icons.check_circle : Icons.navigation,
                      color: isAligned ? Colors.white : theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isAligned
                          ? 'أنت تتجه نحو القبلة الآن 🕋'
                          : 'قم بتدوير الهاتف نحو مؤشر القبلة',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isAligned ? Colors.white : theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Compass Display Area
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Glowing Ring when aligned
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 290,
                      height: 290,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                        boxShadow: isAligned
                            ? [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.4),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                )
                              ]
                            : [],
                      ),
                    ),

                    // Rotating Compass Dial
                    Transform.rotate(
                      angle: -headingAngle * (math.pi / 180),
                      child: _buildCompassDial(theme, isDark),
                    ),

                    // Rotating Qibla Needle (points to Kaaba relative to North dial)
                    Transform.rotate(
                      angle: (qiblaAngle - headingAngle) * (math.pi / 180),
                      child: _buildQiblaNeedle(isAligned, theme),
                    ),

                    // Center Pivot Dot
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isAligned ? Colors.green.shade700 : theme.colorScheme.primary,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Angles Info Card
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAngleInfoTile(
                    theme: theme,
                    title: 'زاوية القبلة',
                    value: '${qiblaAngle.toStringAsFixed(1)}°',
                    icon: Icons.mosque_outlined,
                  ),
                  _buildAngleInfoTile(
                    theme: theme,
                    title: 'اتجاه البوصلة',
                    value: '${headingAngle.toStringAsFixed(1)}°',
                    icon: Icons.explore_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'ضع الهاتف على سطح مستوٍ أفقياً للحصول على أفضل دقة',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompassDial(ThemeData theme, bool isDark) {
    return Container(
      width: 270,
      height: 270,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF1E2638) : Colors.white,
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : Colors.grey.withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cardinal Directions (N, E, S, W)
          const Positioned(
            top: 12,
            child: Text(
              'شمال',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
            ),
          ),
          const Positioned(
            bottom: 12,
            child: Text(
              'جنوب',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
            ),
          ),
          const Positioned(
            right: 14,
            child: Text(
              'شرق',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
            ),
          ),
          const Positioned(
            left: 14,
            child: Text(
              'غرب',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
            ),
          ),

          // Ticks around dial
          for (int i = 0; i < 360; i += 30)
            Transform.rotate(
              angle: i * (math.pi / 180),
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: i % 90 == 0 ? 3 : 1,
                  height: i % 90 == 0 ? 12 : 6,
                  color: i == 0
                      ? Colors.red
                      : (theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4) ?? Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQiblaNeedle(bool isAligned, ThemeData theme) {
    final Color needleColor = isAligned ? Colors.green.shade600 : Colors.amber.shade700;

    return Container(
      width: 270,
      height: 270,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Needle Pointer pointing UP towards Qibla
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Kaaba Icon at top of needle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: needleColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: needleColor.withValues(alpha: 0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mosque,
                  size: 22,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              // Pointer Triangle
              CustomPaint(
                size: const Size(18, 90),
                painter: _NeedlePainter(color: needleColor),
              ),
              const SizedBox(height: 105), // Balance distance
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAngleInfoTile({
    required ThemeData theme,
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoCompassFallback(ThemeData theme) {
    final double qiblaAngle = _qiblaDirection ?? 0.0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore_off_outlined, size: 64, color: Colors.amber.shade800),
            const SizedBox(height: 16),
            const Text(
              'حساس البوصلة غير متوفر على هذا الجهاز',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'زاوية اتجاه القبلة لموقعك الحالي هي: ${qiblaAngle.toStringAsFixed(1)}° من الشمال نحو الشرق.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          _locationName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'زاوية القبلة: ${qiblaAngle.toStringAsFixed(1)}°',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NeedlePainter extends CustomPainter {
  final Color color;

  _NeedlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0) // Top vertex
      ..lineTo(size.width, size.height) // Bottom right
      ..lineTo(size.width / 2, size.height - 10) // Inner notch
      ..lineTo(0, size.height) // Bottom left
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _NeedlePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
