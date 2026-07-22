import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adhan/adhan.dart';
import '../providers/prayer_provider.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _isAutomaticLocation;
  late TextEditingController _cityController;
  late CalculationMethod _calculationMethod;
  late String _adhanSound;

  final Map<String, String> _adhanSounds = {
    'adhan': 'الأذان الافتراضي',
    'adhan_makkah': 'أذان مكة المكرمة',
    'adhan_madina': 'أذان المدينة المنورة',
    'adhan_aqsa': 'أذان المسجد الأقصى',
    'adhan_egypt': 'الأذان المصري',
  };

  final Map<CalculationMethod, String> _methods = {
    CalculationMethod.egyptian: 'الهيئة المصرية العامة للمساحة',
    CalculationMethod.muslim_world_league: 'رابطة العالم الإسلامي',
    CalculationMethod.umm_al_qura: 'أم القرى',
    CalculationMethod.karachi: 'جامعة العلوم الإسلامية بكراتشي',
    CalculationMethod.qatar: 'قطر',
    CalculationMethod.kuwait: 'الكويت',
    CalculationMethod.moon_sighting_committee: 'لجنة رؤية الهلال',
  };

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<PrayerProvider>(context, listen: false);
    _isAutomaticLocation = provider.isAutomaticLocation;
    _cityController = TextEditingController(text: provider.manualLocationText);
    _calculationMethod = provider.calculationMethod;
    _adhanSound = provider.adhanSound;
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final provider = Provider.of<PrayerProvider>(context, listen: false);
    provider.updateSettings(
      _isAutomaticLocation,
      _cityController.text.trim(),
      _calculationMethod,
      _adhanSound,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Calculation Method Section
          Text('طريقة حساب المواقيت', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<CalculationMethod>(
                  value: _calculationMethod,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down),
                  items: _methods.entries.map((entry) {
                    return DropdownMenuItem<CalculationMethod>(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (CalculationMethod? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _calculationMethod = newValue;
                      });
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          // Adhan Sound Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('صوت الأذان', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
              IconButton(
                icon: const Icon(Icons.play_circle_fill),
                color: theme.colorScheme.primary,
                tooltip: 'تجربة الأذان',
                onPressed: () {
                  NotificationService().testAzanSound(_adhanSound);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _adhanSound,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down),
                  items: _adhanSounds.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _adhanSound = newValue;
                      });
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          // Location Section
          Text('الموقع الجغرافي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: SwitchListTile(
              title: const Text('تحديد الموقع تلقائياً (GPS)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('يفضل لتحديد دقيق لأوقات الصلاة'),
              value: _isAutomaticLocation,
              onChanged: (bool value) {
                setState(() {
                  _isAutomaticLocation = value;
                });
              },
            ),
          ),
          
          if (!_isAutomaticLocation) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _cityController,
              decoration: InputDecoration(
                labelText: 'اسم المدينة (مثال: Cairo, Egypt)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.location_city),
              ),
            ),
          ],
          
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('حفظ الإعدادات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
