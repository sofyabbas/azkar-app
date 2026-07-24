import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';
import '../providers/prayer_provider.dart';
import '../widgets/moon_illustration_widget.dart';
import '../widgets/sun_arc_progress_widget.dart';
import 'settings_screen.dart';
import 'qibla_screen.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  bool _useEnglishFormat = false; // Default to 100% Arabic

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1E3A37); // Dark Slate Teal

    return Scaffold(
      backgroundColor: primaryColor,
      body: Consumer<PrayerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (provider.errorMessage.isNotEmpty) {
            return _buildErrorState(context, provider);
          }

          final pt = provider.prayerTimes;
          if (pt == null) {
            return const Center(
              child: Text(
                'تعذر حساب مواقيت الصلاة',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final nextPrayer = provider.nextPrayer;
          final currentPrayer = provider.currentPrayer;
          final activePrayerForDisplay = (nextPrayer != Prayer.none) ? nextPrayer : Prayer.fajr;

          final nextPrayerName = _getPrayerName(activePrayerForDisplay, english: _useEnglishFormat);
          final nextPrayerTime = _getPrayerTime(pt, activePrayerForDisplay);

          return SafeArea(
            child: Column(
              children: [
                // TOP HERO SECTION (Dark Teal)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  child: Column(
                    children: [
                      // Header Row: City Dropdown & Location Target Icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // City Picker Dropdown Button
                          InkWell(
                            onTap: () => _showCityPickerBottomSheet(context, provider),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    provider.locationName.isEmpty
                                        ? (_useEnglishFormat ? 'City of London' : 'مدينة لندن')
                                        : provider.locationName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.white70,
                                    size: 22,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Location Target Button
                          IconButton(
                            onPressed: () async {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('جاري تحديث مواقيت الصلاة...'),
                                  duration: Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              await provider.refreshLocation();
                            },
                            icon: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                              child: const Icon(
                                Icons.my_location_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Main Hero Content: Prayer Name, Time, Countdown & Moon Illustration
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Left side: Text details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nextPrayerName.toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFFAECDCB),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  nextPrayerTime != null
                                      ? DateFormat('h:mm').format(nextPrayerTime)
                                      : '12:15',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 48,
                                    fontWeight: FontWeight.w800,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _useEnglishFormat
                                      ? provider.formattedCountdownShort
                                      : provider.formattedCountdownArabic,
                                  style: const TextStyle(
                                    color: Color(0xFFAECDCB),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Right side: Moon & Stars Illustration
                          const MoonIllustrationWidget(size: 110),
                        ],
                      ),
                    ],
                  ),
                ),

                // SUN PROGRESS ARC STRIP
                SunArcProgressWidget(
                  activePrayer: currentPrayer != Prayer.none ? currentPrayer : activePrayerForDisplay,
                  onPrayerSelected: (prayer) {},
                ),

                // OVERLAPPING WHITE CARD CONTAINER FOR PRAYER LIST
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 14),

                        // Date Header inside White Card (Clean Row layout to prevent overlap)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Empty spacer matching 3-dots width for perfect visual centering
                              const SizedBox(width: 40),

                              // Date Details (Gregorian + Hijri) in Center
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _getFormattedGregorianDate(_useEnglishFormat),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFF1E2827),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _getFormattedHijriDate(DateTime.now(), _useEnglishFormat),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // 3-dots Menu Icon on the side
                              SizedBox(
                                width: 40,
                                child: PopupMenuButton<String>(
                                  padding: EdgeInsets.zero,
                                  icon: Icon(Icons.more_vert, color: Colors.grey[700]),
                                  onSelected: (value) {
                                    if (value == 'language') {
                                      setState(() {
                                        _useEnglishFormat = !_useEnglishFormat;
                                      });
                                    } else if (value == 'qibla') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const QiblaScreen()),
                                      );
                                    } else if (value == 'settings') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                                      );
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'language',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.translate, size: 20),
                                          const SizedBox(width: 10),
                                          Text(_useEnglishFormat ? 'التحويل للعربية' : 'Switch to English'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'qibla',
                                      child: Row(
                                        children: [
                                          Icon(Icons.explore_outlined, size: 20),
                                          SizedBox(width: 10),
                                          Text('اتجاه القبلة'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'settings',
                                      child: Row(
                                        children: [
                                          Icon(Icons.settings_outlined, size: 20),
                                          SizedBox(width: 10),
                                          Text('الإعدادات والطريقة'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // PRAYER LIST
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                            child: Column(
                              children: [
                                _buildPrayerRow(context, provider, Prayer.fajr,
                                    _useEnglishFormat ? 'Fajr' : 'الفجر', pt.fajr, activePrayerForDisplay == Prayer.fajr),
                                _buildPrayerRow(context, provider, Prayer.sunrise,
                                    _useEnglishFormat ? 'Shuruq' : 'الشروق', pt.sunrise, activePrayerForDisplay == Prayer.sunrise),
                                _buildPrayerRow(context, provider, Prayer.dhuhr,
                                    _useEnglishFormat ? 'Dhuhr' : 'الظهر', pt.dhuhr, activePrayerForDisplay == Prayer.dhuhr),
                                _buildPrayerRow(context, provider, Prayer.asr,
                                    _useEnglishFormat ? 'Asr' : 'العصر', pt.asr, activePrayerForDisplay == Prayer.asr),
                                _buildPrayerRow(context, provider, Prayer.maghrib,
                                    _useEnglishFormat ? 'Maghrib' : 'المغرب', pt.maghrib, activePrayerForDisplay == Prayer.maghrib),
                                _buildPrayerRow(context, provider, Prayer.isha,
                                    _useEnglishFormat ? 'Isha' : 'العشاء', pt.isha, activePrayerForDisplay == Prayer.isha),
                                _buildQiyamRow(context, provider, pt, _useEnglishFormat),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Build Individual Prayer Row Widget matching the exact reference style
  Widget _buildPrayerRow(BuildContext context, PrayerProvider provider, Prayer prayer,
      String name, DateTime time, bool isHighlighted) {
    final isEnabled = provider.prayerToggles[prayer] ?? (prayer != Prayer.sunrise);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: isHighlighted
            ? Border.all(color: const Color(0xFF1E3A37), width: 1.8)
            : Border.all(color: Colors.transparent),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Prayer Name
          Text(
            name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
              color: const Color(0xFF1C2726),
            ),
          ),

          // Time & Speaker Icon
          Row(
            children: [
              Text(
                provider.formatTimeWithAmPm(time, locale: _useEnglishFormat ? 'en' : 'ar'),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () {
                  provider.togglePrayerNotification(prayer);
                },
                child: Icon(
                  isEnabled ? Icons.volume_up_outlined : Icons.volume_off_outlined,
                  color: isEnabled ? Colors.grey[700] : Colors.grey[400],
                  size: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Qiyam Row
  Widget _buildQiyamRow(BuildContext context, PrayerProvider provider, PrayerTimes pt, bool isEnglish) {
    final maghrib = pt.maghrib;
    final tomorrowFajr = pt.fajr.add(const Duration(days: 1));
    final nightSecs = tomorrowFajr.difference(maghrib).inSeconds;
    final qiyamTime = maghrib.add(Duration(seconds: (nightSecs * 2 / 3).round()));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isEnglish ? 'Qiyam' : 'قيام الليل',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C2726),
            ),
          ),
          Row(
            children: [
              Text(
                provider.formatTimeWithAmPm(qiyamTime, locale: isEnglish ? 'en' : 'ar'),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(width: 20),
              Icon(
                Icons.volume_off_outlined,
                color: Colors.grey[400],
                size: 22,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Bottom Sheet for City Selection in Arabic
  void _showCityPickerBottomSheet(BuildContext context, PrayerProvider provider) {
    final List<Map<String, String>> popularCities = [
      {'name': 'القاهرة', 'country': 'مصر'},
      {'name': 'الإسكندرية', 'country': 'مصر'},
      {'name': 'الجيزة', 'country': 'مصر'},
      {'name': 'مكة المكرمة', 'country': 'المملكة العربية السعودية'},
      {'name': 'المدينة المنورة', 'country': 'المملكة العربية السعودية'},
      {'name': 'الرياض', 'country': 'المملكة العربية السعودية'},
      {'name': 'جدة', 'country': 'المملكة العربية السعودية'},
      {'name': 'دبي', 'country': 'الإمارات العربية المتحدة'},
      {'name': 'أبو ظبي', 'country': 'الإمارات العربية المتحدة'},
      {'name': 'إسطنبول', 'country': 'تركيا'},
      {'name': 'لندن', 'country': 'المملكة المتحدة'},
    ];

    final TextEditingController searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'اختر المدينة',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // GPS Auto Location Option
              ListTile(
                leading: const Icon(Icons.my_location, color: Color(0xFF1E3A37)),
                title: const Text('التحديد التلقائي للموقع عبر GPS'),
                subtitle: const Text('استخدام الموقع الحالي بالجهاز'),
                onTap: () async {
                  Navigator.pop(context);
                  await provider.updateSettings(true, '', provider.calculationMethod, provider.adhanSound);
                },
              ),
              const Divider(),

              // Manual City Search Field
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'ابحث عن اسم مدينتك...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onSubmitted: (value) async {
                  if (value.trim().isNotEmpty) {
                    Navigator.pop(context);
                    await provider.updateSettings(false, value.trim(), provider.calculationMethod, provider.adhanSound);
                  }
                },
              ),
              const SizedBox(height: 12),

              // Popular Cities List
              SizedBox(
                height: 220,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: popularCities.length,
                  itemBuilder: (context, index) {
                    final city = popularCities[index];
                    return ListTile(
                      title: Text(city['name']!),
                      subtitle: Text(city['country']!),
                      onTap: () async {
                        Navigator.pop(context);
                        await provider.updateSettings(
                            false, '${city['name']}، ${city['country']}', provider.calculationMethod, provider.adhanSound);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Error State Widget
  Widget _buildErrorState(BuildContext context, PrayerProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off_rounded, size: 64, color: Colors.white70),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1E3A37),
              ),
              onPressed: () => provider.refreshLocation(),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Methods for Formatting Dates
  String _getPrayerName(Prayer prayer, {required bool english}) {
    if (english) {
      switch (prayer) {
        case Prayer.fajr:
          return 'Fajr';
        case Prayer.sunrise:
          return 'Shuruq';
        case Prayer.dhuhr:
          return 'Dhuhr';
        case Prayer.asr:
          return 'Asr';
        case Prayer.maghrib:
          return 'Maghrib';
        case Prayer.isha:
          return 'Isha';
        default:
          return 'Dhuhr';
      }
    } else {
      switch (prayer) {
        case Prayer.fajr:
          return 'الفجر';
        case Prayer.sunrise:
          return 'الشروق';
        case Prayer.dhuhr:
          return 'الظهر';
        case Prayer.asr:
          return 'العصر';
        case Prayer.maghrib:
          return 'المغرب';
        case Prayer.isha:
          return 'العشاء';
        default:
          return 'الظهر';
      }
    }
  }

  DateTime? _getPrayerTime(PrayerTimes pt, Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return pt.fajr;
      case Prayer.sunrise:
        return pt.sunrise;
      case Prayer.dhuhr:
        return pt.dhuhr;
      case Prayer.asr:
        return pt.asr;
      case Prayer.maghrib:
        return pt.maghrib;
      case Prayer.isha:
        return pt.isha;
      default:
        return pt.dhuhr;
    }
  }

  String _getFormattedGregorianDate(bool isEnglish) {
    try {
      if (isEnglish) {
        return DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());
      } else {
        return DateFormat('EEEE، d MMMM yyyy', 'ar').format(DateTime.now());
      }
    } catch (_) {
      return DateFormat('yyyy-MM-dd').format(DateTime.now());
    }
  }

  String _getFormattedHijriDate(DateTime date, bool isEnglish) {
    final double day = date.day.toDouble();
    final double month = date.month.toDouble();
    final double year = date.year.toDouble();

    double m = month;
    double y = year;
    if (m < 3) {
      y -= 1;
      m += 12;
    }

    double a = (y / 100).floorToDouble();
    double b = 2 - a + (a / 4).floorToDouble();
    if (y < 1583) b = 0;
    if (y == 1582) {
      if (m > 10) b = -10;
      if (m == 10) {
        b = 0;
        if (day >= 15) b = -10;
      }
    }

    double jd = (365.25 * (y + 4716)).floorToDouble() +
        (30.6001 * (m + 1)).floorToDouble() +
        day +
        b -
        1524.5;

    double l = jd - 1948440 + 10632;
    double n = ((l - 1) / 10631).floorToDouble();
    l = l - 10631 * n + 354;
    double j = (((10985 - l) / 5316)).floorToDouble() *
            (((50 * l) / 17719)).floorToDouble() +
        (((l / 5670)).floorToDouble() * (((43 * l) / 15238)).floorToDouble());
    l = l -
        (((30 - j) / 15)).floorToDouble() * (((17719 * j) / 50)).floorToDouble() -
        ((j / 16)).floorToDouble() * (((15238 * j) / 43)).floorToDouble() +
        29;
    double mH = ((24 * l) / 709).floorToDouble();
    double dH = l - ((709 * mH) / 24).floorToDouble();
    double yH = 30 * n + j - 30;

    final int hijriDay = dH.toInt();
    final int hijriMonth = mH.toInt();
    final int hijriYear = yH.toInt();

    const List<String> hijriMonthsAr = [
      'محرم', 'صفر', 'ربيع الأول', 'ربيع الثاني', 'جمادى الأولى', 'جمادى الآخرة',
      'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة'
    ];

    const List<String> hijriMonthsEn = [
      'Muḥarram', 'Ṣafar', 'Rabīʿ al-Awwal', 'Rabīʿ ath-Thānī',
      'Jumādá al-Ūlá', 'Jumādá al-Ākhirah', 'Rajab', 'Shaʿbān',
      'Ramaḍān', 'Shawwāl', 'Dhū al-Qaʿdah', 'Dhū al-Ḥijjah'
    ];

    final monthName = (hijriMonth >= 1 && hijriMonth <= 12)
        ? (isEnglish ? hijriMonthsEn[hijriMonth - 1] : hijriMonthsAr[hijriMonth - 1])
        : (isEnglish ? "Sha'ban" : 'شعبان');

    if (isEnglish) {
      return "$monthName $hijriDay, $hijriYear";
    } else {
      return "$hijriDay $monthName $hijriYear هـ";
    }
  }
}
