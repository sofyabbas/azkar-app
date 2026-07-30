import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import '../providers/quit_smoking_provider.dart';
import '../models/quit_smoking_model.dart';

class QuitSmokingScreen extends StatelessWidget {
  const QuitSmokingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<QuitSmokingProvider>(context);

    if (provider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final state = provider.state;
    final isConfigured = state?.isConfigured ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('رئة نقية (الإقلاع عن التدخين)', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (isConfigured) ...[
            IconButton(
              icon: Icon(
                provider.currentUser != null ? Icons.cloud_sync : Icons.cloud_off,
                color: provider.currentUser != null ? Colors.white : Colors.white60,
              ),
              tooltip: provider.currentUser != null ? 'مزامنة البيانات' : 'المزامنة غير نشطة',
              onPressed: () async {
                if (provider.currentUser == null) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('المزامنة السحابية', textAlign: TextAlign.right),
                      content: const Text(
                        'يرجى تسجيل الدخول من صفحة "الحساب" لتفعيل المزامنة السحابية التلقائية وحفظ تقدمك.',
                        textAlign: TextAlign.right,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('حسناً'),
                        ),
                      ],
                    ),
                  );
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('جاري مزامنة بيانات الإقلاع عن التدخين...'), duration: Duration(seconds: 1)),
                );
                await provider.syncData();
                if (context.mounted) {
                  if (provider.errorMessage.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage)));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تمت المزامنة السحابية بنجاح! ☁️')),
                    );
                  }
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.restart_alt, color: Colors.white),
              tooltip: 'إعادة تعيين الرحلة',
              onPressed: () => _showResetDialog(context, provider),
            ),
          ]
        ],
      ),
      body: isConfigured
          ? _buildDashboard(context, provider, state!)
          : _buildSetupForm(context, provider),
    );
  }

  Widget _buildSetupForm(BuildContext context, QuitSmokingProvider provider) {
    return _SetupFormWidget(provider: provider);
  }

  Widget _buildDashboard(BuildContext context, QuitSmokingProvider provider, QuitSmokingState state) {
    final theme = Theme.of(context);
    final health = provider.lungHealth;
    final healthPercentage = (health * 100).toStringAsFixed(0);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Lung Display Card
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
            child: Column(
              children: [
                const Text(
                  'حالة الرئة ومستوى التطهير',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                BreathingLungWidget(healthProgress: health),
                const SizedBox(height: 24),
                Text(
                  'صحة الرئة: $healthPercentage%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color.lerp(const Color(0xFF2C2C2C), const Color(0xFF1E3A37), health),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getLungHealthStatusArabic(health),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Stats Title
        Text(
          'إنجازاتك منذ البدء',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 12),

        // 2x2 Stats Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.45,
          children: [
            _buildStatCard(
              theme,
              title: 'أيام نقية',
              value: '${provider.smokeFreeDays} أيام',
              subtitle: 'من أصل ${provider.daysSinceStart} يوم',
              icon: Icons.calendar_today_rounded,
              iconColor: Colors.blue,
            ),
            _buildStatCard(
              theme,
              title: 'سجائر تجنبتها',
              value: '${provider.avoidedCigarettes}',
              subtitle: 'سيجارة غير مدخنة',
              icon: Icons.smoke_free_rounded,
              iconColor: Colors.green,
            ),
            _buildStatCard(
              theme,
              title: 'الأموال الموفرة',
              value: provider.moneySaved.toStringAsFixed(1),
              subtitle: 'جنيه مصري',
              icon: Icons.savings_rounded,
              iconColor: Colors.amber[700]!,
            ),
            _buildStatCard(
              theme,
              title: 'دقائق مستردة',
              value: _formatLifeMinutes(provider.lifeMinutesRegained),
              subtitle: 'من متوسط عمرك',
              icon: Icons.health_and_safety_rounded,
              iconColor: Colors.redAccent,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Log Today's Slip-ups
        _buildTodayLogCard(context, provider),
        const SizedBox(height: 16),

        // Last 7 Days History Check
        _buildWeeklyHistoryCard(context, provider, state),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStatCard(
    ThemeData theme, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Card(
      elevation: 1.5,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
                Icon(icon, color: iconColor, size: 20),
              ],
            ),
            const Spacer(),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayLogCard(BuildContext context, QuitSmokingProvider provider) {
    final theme = Theme.of(context);
    final count = provider.cigarettesSmokedToday;
    final isClean = count == 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isClean ? BorderSide(color: theme.colorScheme.primary, width: 1.5) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'سجل سجائرك اليوم 📝',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (isClean)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'اليوم نقي 🌿',
                      style: TextStyle(color: theme.colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: Colors.redAccent),
                  onPressed: () => provider.logCigarettes(DateTime.now(), count + 1),
                  icon: const Icon(Icons.add, color: Colors.white),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      Text(
                        '$count',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const Text('سجائر اليوم', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black87,
                  ),
                  onPressed: count > 0 ? () => provider.logCigarettes(DateTime.now(), count - 1) : null,
                  icon: const Icon(Icons.remove),
                ),
              ],
            ),
            if (isClean) ...[
              const SizedBox(height: 14),
              const Text(
                'استمر هكذا! كل سيجارة تتجنبها تعيد الحياة واللون الوردي لرئتك.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
              ),
            ] else ...[
              const SizedBox(height: 14),
              Text(
                'لقد خسرت ${(count * 1.5).toStringAsFixed(1)}% من صحة رئتك اليوم. لا بأس، حاول النهوض مجدداً غداً!',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12, height: 1.4, fontWeight: FontWeight.bold),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyHistoryCard(BuildContext context, QuitSmokingProvider provider, QuitSmokingState state) {
    final cleanStartDate = DateTime(state.startDate.year, state.startDate.month, state.startDate.day);
    final today = DateTime.now();
    final cleanToday = DateTime(today.year, today.month, today.day);

    // List of last 7 days
    final List<DateTime> last7Days = [];
    for (int i = 6; i >= 0; i--) {
      last7Days.add(cleanToday.subtract(Duration(days: i)));
    }

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'سجل الأيام السبعة الأخيرة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: last7Days.map((date) {
                final dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                final isBeforeStart = date.isBefore(cleanStartDate);
                final int count = state.dailyLogs[dateKey] ?? 0;
                
                String dayName = intl.DateFormat('E', 'ar').format(date);
                if (date.day == cleanToday.day) dayName = 'اليوم';

                Color circleColor;
                Widget content;

                if (isBeforeStart) {
                  circleColor = Colors.grey[200]!;
                  content = const Icon(Icons.block, size: 16, color: Colors.grey);
                } else if (count == 0) {
                  circleColor = Colors.green.shade100;
                  content = const Icon(Icons.check, size: 16, color: Colors.green);
                } else {
                  circleColor = Colors.red.shade100;
                  content = Text(
                    '$count',
                    style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                  );
                }

                return Column(
                  children: [
                    Text(dayName, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    const SizedBox(height: 6),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: circleColor,
                        border: count > 0 && !isBeforeStart
                            ? Border.all(color: Colors.red.shade300)
                            : (count == 0 && !isBeforeStart
                                ? Border.all(color: Colors.green.shade300)
                                : null),
                      ),
                      child: Center(child: content),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context, QuitSmokingProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إعادة تعيين التقدم؟', textAlign: TextAlign.right),
        content: const Text(
          'هل أنت متأكد من رغبتك في حذف بيانات التدخين الحالية والبدء من جديد؟ سيتم محو جميع السجلات والبدء بإدخال بيانات جديدة.',
          textAlign: TextAlign.right,
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              provider.resetProgress();
              Navigator.pop(ctx);
            },
            child: const Text('نعم، ابدأ من جديد', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _getLungHealthStatusArabic(double health) {
    if (health >= 0.9) return '🌿 رئتك نظيفة تماماً وصحية جداً. رئة وردية ونظيفة!';
    if (health >= 0.7) return '✨ صحة الرئة في تطور مستمر. بدأت الأهداب الرئوية في العمل والتنظيف الذاتي.';
    if (health >= 0.5) return '👍 رئتك تتعافى بشكل مقبول. احرص على عدم التدخين لتجنب إعادتها للون الأسود.';
    if (health >= 0.25) return '⚠️ رئتك تعاني من تراكم السموم والقطران. توقف تماماً لمساعدة الأنسجة على الالتئام.';
    return '🚨 رئتك في حالة حرجة وشديدة التلف والقطران. توقف عن التدخين فوراً لإنقاذ رئتيك!';
  }

  String _formatLifeMinutes(int totalMinutes) {
    if (totalMinutes < 60) {
      return "$totalMinutes دقيقة";
    }
    final int hours = totalMinutes ~/ 60;
    final int minutes = totalMinutes % 60;
    if (hours < 24) {
      return "$hours ساعة و $minutes د.";
    }
    final int days = hours ~/ 24;
    final int remainingHours = hours % 24;
    return "$days يوم و $remainingHours س.";
  }
}

class _SetupFormWidget extends StatefulWidget {
  final QuitSmokingProvider provider;

  const _SetupFormWidget({required this.provider});

  @override
  State<_SetupFormWidget> createState() => _SetupFormWidgetState();
}

class _SetupFormWidgetState extends State<_SetupFormWidget> {
  int _years = 5;
  int _dailyRate = 20;
  final _priceController = TextEditingController(text: '50.0');
  DateTime _startDate = DateTime.now();

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1E3A37);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primaryColor, Color(0xFF284845)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              children: [
                Icon(Icons.health_and_safety, color: Color(0xFFFFD700), size: 40),
                SizedBox(height: 10),
                Text(
                  'ابدأ رحلة رئتك النقية 🫁',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 6),
                Text(
                  'أدخل بياناتك الحالية لبناء محاكاة الرئة، وراقب كيف تعود رئتك للونها الطبيعي النظيف مع كل يوم التزام.',
                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Years of smoking Slider
          _buildFormCard(
            title: 'منذ كم سنة تدخن؟',
            valueText: '$_years سنوات',
            child: Slider(
              value: _years.toDouble(),
              min: 1,
              max: 40,
              divisions: 39,
              label: '$_years سنوات',
              onChanged: (val) {
                setState(() {
                  _years = val.round();
                });
              },
            ),
          ),
          const SizedBox(height: 16),

          // Daily rate Slider
          _buildFormCard(
            title: 'كم سيجارة تدخنها يومياً عادة؟',
            valueText: '$_dailyRate سيجارة',
            child: Slider(
              value: _dailyRate.toDouble(),
              min: 1,
              max: 60,
              divisions: 59,
              label: '$_dailyRate سجائر',
              onChanged: (val) {
                setState(() {
                  _dailyRate = val.round();
                });
              },
            ),
          ),
          const SizedBox(height: 16),

          // Pack Price Input
          _buildFormCard(
            title: 'ما هو سعر علبة السجائر (بها 20 سيجارة)؟',
            valueText: '',
            child: TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                prefixText: 'جنيه مصري ',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                hintText: 'مثال: 50.0',
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quitting Start Date
          _buildFormCard(
            title: 'تاريخ بدء برنامج الإقلاع والتعافي:',
            valueText: intl.DateFormat('yyyy-MM-dd').format(_startDate),
            child: OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 90)),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() {
                    _startDate = picked;
                  });
                }
              },
              icon: const Icon(Icons.calendar_month),
              label: const Text('اختيار التاريخ'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Submit button
          ElevatedButton(
            onPressed: () async {
              final price = double.tryParse(_priceController.text.trim()) ?? 50.0;
              await widget.provider.configure(
                years: _years,
                dailyRate: _dailyRate,
                price: price,
                date: _startDate,
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('ابدأ برنامج التطهير والالتزام 🌿', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildFormCard({required String title, required String valueText, required Widget child}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                if (valueText.isNotEmpty)
                  Text(
                    valueText,
                    style: const TextStyle(color: Color(0xFF1E3A37), fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class BreathingLungWidget extends StatefulWidget {
  final double healthProgress;

  const BreathingLungWidget({super.key, required this.healthProgress});

  @override
  State<BreathingLungWidget> createState() => _BreathingLungWidgetState();
}

class _BreathingLungWidgetState extends State<BreathingLungWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScaleTransition(
      scale: _animation,
      child: CustomPaint(
        size: const Size(200, 180),
        painter: LungPainter(
          healthProgress: widget.healthProgress,
          isDark: isDark,
        ),
      ),
    );
  }
}

class LungPainter extends CustomPainter {
  final double healthProgress;
  final bool isDark;

  LungPainter({required this.healthProgress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Healthy lung: Soft bright pink-rose
    // Damaged lung: Charcoal black-dark grey
    final healthyColor = const Color(0xFFFF9494);
    final damagedColor = const Color(0xFF282828);
    final lungColor = Color.lerp(damagedColor, healthyColor, healthProgress)!;

    final borderPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.8) // Gold borders
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final lungPaint = Paint()
      ..color = lungColor
      ..style = PaintingStyle.fill;

    // Draw trachea & bronchi branches
    final tracheaPaint = Paint()
      ..color = isDark ? Colors.grey[600]! : Colors.grey[400]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    final tracheaPath = Path();
    tracheaPath.moveTo(w / 2, h * 0.1);
    tracheaPath.lineTo(w / 2, h * 0.38);

    // Left bronchus branch
    tracheaPath.moveTo(w / 2, h * 0.38);
    tracheaPath.quadraticBezierTo(w / 2 - 12, h * 0.41, w / 2 - 32, h * 0.48);

    // Right bronchus branch
    tracheaPath.moveTo(w / 2, h * 0.38);
    tracheaPath.quadraticBezierTo(w / 2 + 12, h * 0.41, w / 2 + 32, h * 0.48);

    // Left bronchus fine branches
    tracheaPath.moveTo(w / 2 - 20, h * 0.44);
    tracheaPath.lineTo(w / 2 - 38, h * 0.41);
    tracheaPath.moveTo(w / 2 - 26, h * 0.46);
    tracheaPath.lineTo(w / 2 - 34, h * 0.54);

    // Right bronchus fine branches
    tracheaPath.moveTo(w / 2 + 20, h * 0.44);
    tracheaPath.lineTo(w / 2 + 38, h * 0.41);
    tracheaPath.moveTo(w / 2 + 26, h * 0.46);
    tracheaPath.lineTo(w / 2 + 34, h * 0.54);

    canvas.drawPath(tracheaPath, tracheaPaint);

    // Draw Left Lung Lobe
    final leftLungPath = Path();
    leftLungPath.moveTo(w * 0.46, h * 0.35);
    // Outer upper curve
    leftLungPath.cubicTo(w * 0.3, h * 0.2, w * 0.08, h * 0.38, w * 0.1, h * 0.6);
    // Outer lower curve
    leftLungPath.cubicTo(w * 0.11, h * 0.76, w * 0.26, h * 0.88, w * 0.42, h * 0.82);
    // Inner cardiac notch and up
    leftLungPath.cubicTo(w * 0.36, h * 0.72, w * 0.48, h * 0.62, w * 0.46, h * 0.35);
    leftLungPath.close();

    // Draw Right Lung Lobe
    final rightLungPath = Path();
    rightLungPath.moveTo(w * 0.54, h * 0.35);
    // Outer upper curve
    rightLungPath.cubicTo(w * 0.7, h * 0.2, w * 0.92, h * 0.38, w * 0.9, h * 0.6);
    // Outer lower curve
    rightLungPath.cubicTo(w * 0.89, h * 0.76, w * 0.74, h * 0.88, w * 0.58, h * 0.82);
    // Inner curve and up
    rightLungPath.cubicTo(w * 0.64, h * 0.72, w * 0.52, h * 0.62, w * 0.54, h * 0.35);
    rightLungPath.close();

    // Draw drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    
    canvas.save();
    canvas.translate(0, 4);
    canvas.drawPath(leftLungPath, shadowPaint);
    canvas.drawPath(rightLungPath, shadowPaint);
    canvas.restore();

    // Draw lungs fill
    canvas.drawPath(leftLungPath, lungPaint);
    canvas.drawPath(rightLungPath, lungPaint);

    // Draw gold borders
    canvas.drawPath(leftLungPath, borderPaint);
    canvas.drawPath(rightLungPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant LungPainter oldDelegate) {
    return oldDelegate.healthProgress != healthProgress || oldDelegate.isDark != isDark;
  }
}
