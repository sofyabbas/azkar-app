import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/stats_provider.dart';
import '../services/auth_service.dart';
import 'statistics_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final statsProvider = Provider.of<StatsProvider>(context);
    final authService = AuthService();
    const primaryColor = Color(0xFF1E3A37);

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF9),
      appBar: AppBar(
        title: const Text('حسابي', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'الإحصائيات التفصيلية',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StatisticsScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<User?>(
        stream: authService.userStream,
        builder: (context, snapshot) {
          final user = snapshot.data;
          
          return ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              // Sleek Profile Card
              Card(
                elevation: 2,
                shadowColor: Colors.black.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: primaryColor.withValues(alpha: 0.15), width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 44,
                          backgroundColor: primaryColor.withValues(alpha: 0.08),
                          backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                          child: user?.photoURL == null
                              ? const Icon(Icons.person_rounded, size: 44, color: primaryColor)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // User Info
                      Text(
                        user != null ? (user.displayName ?? 'مستخدم') : 'حساب زائر (محلّي)',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user != null ? (user.email ?? '') : 'لم يتم تسجيل الدخول بعد',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      
                      if (user != null) ...[
                        const SizedBox(height: 20),
                        OutlinedButton.icon(
                          onPressed: () => authService.signOut(),
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: const Text('تسجيل الخروج', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent, width: 1.2),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await authService.signInWithGoogle();
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('حدث خطأ أثناء تسجيل الدخول: $e')),
                                );
                              }
                            }
                          },
                          icon: Image.network(
                            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
                            height: 20,
                          ),
                          label: const Text(
                            'تسجيل الدخول بحساب جوجل',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            elevation: 1,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'قم بمزامنة إنجازاتك وأذكارك سحابياً لتتمكن من الوصول إليها من أي جهاز آخر.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: Colors.grey[500], height: 1.4),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Statistics Section Header
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  'إحصائياتك وإنجازاتك:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 12),

              // Total Azkar Dashboard Card
              Card(
                elevation: 1,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const StatisticsScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.auto_graph_rounded, color: primaryColor, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'إجمالي الأذكار المقروءة',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${statsProvider.totalAzkarCount} ذِكر',
                                style: const TextStyle(
                                  color: primaryColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
