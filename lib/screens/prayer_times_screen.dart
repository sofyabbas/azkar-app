import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adhan/adhan.dart';
import '../providers/prayer_provider.dart';
import 'settings_screen.dart';

class PrayerTimesScreen extends StatelessWidget {
  const PrayerTimesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مواقيت الصلاة', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<PrayerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage.isNotEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_disabled, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      provider.errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          }
          final pt = provider.prayerTimes;
          if (pt == null) {
            return const Center(child: Text('Could not calculate prayer times.'));
          }

          final nextPrayer = pt.nextPrayer();

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildCountdownCard(context, provider),
              const SizedBox(height: 12),
              _buildLocationInfoCard(context, provider),
              const SizedBox(height: 24),
              _buildPrayerRow(context, provider, Prayer.fajr, 'الفجر', pt.fajr, nextPrayer == Prayer.fajr),
              _buildPrayerRow(context, provider, Prayer.sunrise, 'الشروق', pt.sunrise, nextPrayer == Prayer.sunrise),
              _buildPrayerRow(context, provider, Prayer.dhuhr, 'الظهر', pt.dhuhr, nextPrayer == Prayer.dhuhr),
              _buildPrayerRow(context, provider, Prayer.asr, 'العصر', pt.asr, nextPrayer == Prayer.asr),
              _buildPrayerRow(context, provider, Prayer.maghrib, 'المغرب', pt.maghrib, nextPrayer == Prayer.maghrib),
              _buildPrayerRow(context, provider, Prayer.isha, 'العشاء', pt.isha, nextPrayer == Prayer.isha),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLocationInfoCard(BuildContext context, PrayerProvider provider) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'الموقع: ${provider.locationName}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calculate, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'طريقة الحساب: ${provider.calculationMethodName}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownCard(BuildContext context, PrayerProvider provider) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'الوقت المتبقي للصلاة القادمة',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            provider.formattedCountdown,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerRow(BuildContext context, PrayerProvider provider, Prayer prayer, String name, DateTime time, bool isNext) {
    final theme = Theme.of(context);
    final isEnabled = provider.prayerToggles[prayer] ?? false;

    return Card(
      elevation: isNext ? 4 : 1,
      color: isNext ? theme.colorScheme.primaryContainer : theme.cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isNext ? BorderSide(color: theme.colorScheme.primary, width: 2) : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(
          name,
          style: TextStyle(
            fontSize: 22,
            fontWeight: isNext ? FontWeight.bold : FontWeight.w600,
            color: isNext ? theme.colorScheme.onPrimaryContainer : null,
          ),
        ),
        subtitle: Text(
          provider.formatTime(time),
          style: TextStyle(
            fontSize: 18,
            fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
            color: isNext ? theme.colorScheme.onPrimaryContainer : Colors.grey[600],
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            isEnabled ? Icons.notifications_active : Icons.notifications_off,
            color: isEnabled ? theme.colorScheme.primary : Colors.grey,
            size: 28,
          ),
          onPressed: () {
            provider.togglePrayerNotification(prayer);
          },
        ),
      ),
    );
  }
}
