import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adhan/adhan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/prayer_provider.dart';
import '../providers/azkar_provider.dart';
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
  late double _currentFontSize;
  bool _fortyDaysReminders = true;

  final Map<String, String> _adhanSounds = {
    'adhan': 'الأذان الافتراضي',
    'adhan_makkah': 'أذان مكة المكرمة 🕋',
    'adhan_madinah': 'أذان المدينة المنورة 🕌',
    'adhan_egypt': 'الأذان المصري 🇪🇬',
    'adhan_aqsa': 'أذان المسجد الأقصى 🇵🇸',
  };

  final Map<CalculationMethod, String> _methods = {
    CalculationMethod.egyptian: 'الهيئة المصرية العامة للمساحة (مصر والدول العربية)',
    CalculationMethod.umm_al_qura: 'جامعة أم القرى (السعودية والخليج)',
    CalculationMethod.muslim_world_league: 'رابطة العالم الإسلامي (أوروبا وأمريكا)',
    CalculationMethod.karachi: 'جامعة العلوم الإسلامية بكراتشي (باكستان والهند)',
    CalculationMethod.qatar: 'دولة قطر',
    CalculationMethod.kuwait: 'دولة الكويت',
    CalculationMethod.moon_sighting_committee: 'لجنة رؤية الهلال',
  };

  @override
  void initState() {
    super.initState();
    final prayerProvider = Provider.of<PrayerProvider>(context, listen: false);
    final azkarProvider = Provider.of<AzkarProvider>(context, listen: false);

    _isAutomaticLocation = prayerProvider.isAutomaticLocation;
    _cityController = TextEditingController(text: prayerProvider.manualLocationText);
    _calculationMethod = prayerProvider.calculationMethod;
    _adhanSound = prayerProvider.adhanSound;
    _currentFontSize = azkarProvider.fontSize;
    _loadFortyDaysReminders();
  }

  void _loadFortyDaysReminders() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fortyDaysReminders = prefs.getBool('fortyDaysReminders') ?? true;
    });
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  void _saveSettings() async {
    final prayerProvider = Provider.of<PrayerProvider>(context, listen: false);
    final azkarProvider = Provider.of<AzkarProvider>(context, listen: false);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('fortyDaysReminders', _fortyDaysReminders);

    await prayerProvider.updateSettings(
      _isAutomaticLocation,
      _cityController.text.trim(),
      _calculationMethod,
      _adhanSound,
    );

    await azkarProvider.setFontSize(_currentFontSize);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.greenAccent),
              SizedBox(width: 10),
              Text('تم حفظ الإعدادات بنجاح! ✨', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: const Color(0xFF1E3A37),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1E3A37);

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF9),
      appBar: AppBar(
        title: const Text('الإعدادات', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        children: [
          // SECTION 1: FONT SIZE & READING SETTINGS
          _buildSectionHeader('🔤 إعدادات الخط والقراءة', primaryColor),
          Card(
            elevation: 1.5,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'حجم خط الأذكار:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_currentFontSize.toInt()} pt',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Slider with A- and A+ controls
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.text_fields, size: 18),
                        onPressed: _currentFontSize > 16
                            ? () => setState(() => _currentFontSize -= 1)
                            : null,
                      ),
                      Expanded(
                        child: Slider(
                          value: _currentFontSize,
                          min: 16.0,
                          max: 34.0,
                          divisions: 18,
                          activeColor: primaryColor,
                          inactiveColor: primaryColor.withValues(alpha: 0.2),
                          onChanged: (value) {
                            setState(() {
                              _currentFontSize = value;
                            });
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.text_fields, size: 28),
                        onPressed: _currentFontSize < 34
                            ? () => setState(() => _currentFontSize += 1)
                            : null,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Live Preview Box
                  const Text(
                    'معاينة الخط:',
                    style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FBFB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      '«بِسْمِ اللَّهِ الَّذِي لا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الأَرْضِ وَلا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ»',
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: _currentFontSize,
                        height: 1.7,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // SECTION 2: PRAYER TIMES & ADHAN SETTINGS
          _buildSectionHeader('🕌 مواقيت الصلاة والأذان', primaryColor),
          Card(
            elevation: 1.5,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Calculation Method Dropdown
                  const Text('طريقة حساب المواقيت:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F8F7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<CalculationMethod>(
                        value: _calculationMethod,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: primaryColor),
                        items: _methods.entries.map((entry) {
                          return DropdownMenuItem<CalculationMethod>(
                            value: entry.key,
                            child: Text(
                              entry.value,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
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

                  const SizedBox(height: 20),

                  // Adhan Voice Dropdown + Test Sound Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('صوت الأذان:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: () {
                          NotificationService().testAzanSound(_adhanSound);
                        },
                        icon: const Icon(Icons.play_circle_fill, color: primaryColor, size: 22),
                        label: const Text('تجربة الأذان', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F8F7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _adhanSound,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: primaryColor),
                        items: _adhanSounds.entries.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(
                              entry.value,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
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
                  const Divider(height: 24),
                  SwitchListTile(
                    activeColor: primaryColor,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('تذكيرات مشروع 40 يوم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    subtitle: const Text('تنبيهك قبل كل صلاة بـ 15 دقيقة لتستعد للذهاب للمسجد'),
                    value: _fortyDaysReminders,
                    onChanged: (bool value) {
                      setState(() {
                        _fortyDaysReminders = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // SECTION 3: LOCATION SETTINGS
          _buildSectionHeader('📍 الموقع الجغرافي', primaryColor),
          Card(
            elevation: 1.5,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                SwitchListTile(
                  activeColor: primaryColor,
                  title: const Text('التحديد التلقائي عبر GPS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: const Text('لحساب مواقيت الصلاة بدقة بناءً على موقعك الحالي'),
                  value: _isAutomaticLocation,
                  onChanged: (bool value) {
                    setState(() {
                      _isAutomaticLocation = value;
                    });
                  },
                ),
                if (!_isAutomaticLocation) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        labelText: 'اسم المدينة (مثال: Cairo, Egypt)',
                        hintText: 'اكتب اسم مدينتك...',
                        prefixIcon: const Icon(Icons.location_city, color: primaryColor),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 32),

          // SAVE BUTTON
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save_rounded, color: Colors.white),
              label: const Text('حفظ الإعدادات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, right: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
      ),
    );
  }
}
