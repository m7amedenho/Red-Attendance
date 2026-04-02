import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../shell/main_navigation_screen.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const MainNavigationScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(
            opacity: animation,
            child: child,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      // SafeArea عشان تضمن إن الاسم ميكونش متغطي بشريط الموبايل من تحت
      body: SafeArea(
        child: Stack(
          children: [
            // 1. لوجو التطبيق متسنطر في النص بالظبط
            Center(
              child: SvgPicture.asset(
                'assets/icons/red_attendance_logo.svg',
                width: 180,
              ),
            ),
            
            // 2. اسمك موجود تحت خالص
            const Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 32.0), // مسافة من تحت عشان الشكل الجمالي
                child: Text(
                  'M7amedenho',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: 1.5, // إضافة مسافة بين الحروف بتدي شكل احترافي
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}