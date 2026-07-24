import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';

class SunArcProgressWidget extends StatelessWidget {
  final Prayer activePrayer;
  final Function(Prayer)? onPrayerSelected;

  const SunArcProgressWidget({
    super.key,
    required this.activePrayer,
    this.onPrayerSelected,
  });

  @override
  Widget build(BuildContext context) {
    final prayers = [
      {'prayer': Prayer.fajr, 'icon': Icons.nightlight_outlined, 'name': 'Fajr'},
      {'prayer': Prayer.sunrise, 'icon': Icons.wb_twilight, 'name': 'Sunrise'},
      {'prayer': Prayer.dhuhr, 'icon': Icons.wb_sunny, 'name': 'Dhuhr'},
      {'prayer': Prayer.asr, 'icon': Icons.wb_sunny_outlined, 'name': 'Asr'},
      {'prayer': Prayer.maghrib, 'icon': Icons.wb_twilight_outlined, 'name': 'Maghrib'},
      {'prayer': Prayer.isha, 'icon': Icons.nights_stay_outlined, 'name': 'Isha'},
    ];

    return Container(
      color: const Color(0xFF284845),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background dotted/line track
          Positioned(
            left: 20,
            right: 20,
            child: Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          // Prayer segment icons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: prayers.map((p) {
                final prayer = p['prayer'] as Prayer;
                final icon = p['icon'] as IconData;
                final isActive = (activePrayer == prayer);

                return GestureDetector(
                  onTap: () {
                    if (onPrayerSelected != null) {
                      onPrayerSelected!(prayer);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF1E3A37) : Colors.transparent,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      border: isActive
                          ? Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1)
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: isActive ? 22 : 18,
                          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
                        ),
                        if (isActive) ...[
                          const SizedBox(height: 2),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
