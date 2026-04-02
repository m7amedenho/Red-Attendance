import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // أضفنا هذه المكتبة من أجل الـ HapticFeedback
import 'package:provider/provider.dart';

import '../../providers/attendance_provider.dart';
import '../../utils/date_utils_ar.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AttendanceProvider>(
      builder: (context, provider, _) {
        final isActive = provider.isClockedIn;

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)], // ألوان خلفية عصرية ومريحة للعين
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // وقت الساعة
                    Text(
                      DateUtilsAr.clock(provider.now),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: Color(0xFF0F172A), // لون داكن أنيق بدل الأسود الصريح
                      ),
                    ),
                    const SizedBox(height: 6),
                    // التاريخ
                    Text(
                      DateUtilsAr.dateHeader(provider.now),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B), // لون رمادي احترافي
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    // زر الحضور والانصراف
                    _clockButton(
                      isActive: isActive,
                      onPressed: () async {
                        // إضافة تأثير اهتزاز للموبايل عند الضغط لتحسين الـ UX
                        HapticFeedback.heavyImpact(); 
                        
                        if (isActive) {
                          await provider.clockOut();
                        } else {
                          await provider.clockIn();
                        }
                      },
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // كارت مدة الدوام (مع أنميشن سلس للظهور والاختفاء)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: isActive 
                          ? _buildDurationCard(provider.elapsed)
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // فصلنا كارت المدة في ويدجت منفصل لترتيب الكود
  Widget _buildDurationCard(Duration elapsed) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000), // ظل ناعم جداً
            blurRadius: 20,
            spreadRadius: 2,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'مدة الدوام الحالية',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            DateUtilsAr.hmsDuration(elapsed),
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 38,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()], // لمنع اهتزاز الأرقام أثناء العد
            ),
          ),
        ],
      ),
    );
  }

  Widget _clockButton({
    required bool isActive,
    required Future<void> Function() onPressed,
  }) {
    // ألوان متدرجة عصرية (أحمر زاهي للانصراف، أخضر زمردي للحضور)
    final gradient = isActive
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEF4444), Color(0xFFB91C1C)], 
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF10B981), Color(0xFF047857)],
          );

    // استخدام Material و InkWell لإضافة تأثير الـ Ripple عند الضغط
    final child = Container(
      width: 230,
      height: 230,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: (isActive ? const Color(0xFFDC2626) : const Color(0xFF059669)).withOpacity(0.4),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          // ignore: deprecated_member_use
          splashColor: Colors.white.withOpacity(0.2),
          // ignore: deprecated_member_use
          highlightColor: Colors.white.withOpacity(0.1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? Icons.logout_rounded : Icons.login_rounded,
                color: Colors.white,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                isActive ? 'تسجيل انصراف' : 'تسجيل حضور',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24, // تم تصغير الخط قليلاً ليكون متناسق مع الدائرة
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!isActive) return child;

    // تشغيل الـ Glow فقط في حالة الحضور
    return AvatarGlow(
      glowColor: const Color(0xFFEF4444), // يتناسب مع لون زر الانصراف الجديد
      duration: const Duration(milliseconds: 2000),
      repeat: true,
      child: child,
    );
  }
}