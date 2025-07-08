import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:carboneye/screens/home_screen.dart';
import 'package:carboneye/utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _sweepController;
  late Animation<double> _sweepAnimation;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _sweepAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sweepController,
        curve: Curves.easeInOut,
      ),
    );

    _sweepController.forward();
    _navigateToHome();
  }

  void _navigateToHome() {
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
            transitionDuration: const Duration(milliseconds: 1000),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: _DataGridBackgroundPainter(),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _sweepAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: _SatelliteSweepPainter(sweepProgress: _sweepAnimation.value),
                  child: const SizedBox(
                    width: 300,
                    height: 200,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DataGridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..color = kAccentColor.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 5; i++) {
      canvas.drawCircle(center, size.width / 5 * i, paint);
    }

    for (int i = 0; i < 12; i++) {
      final angle = i * (pi / 6);
      final start = center;
      final end = Offset(
        center.dx + size.width * cos(angle),
        center.dy + size.width * sin(angle),
      );
      canvas.drawLine(start, end, paint);
    }

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    final random = Random(1337);
    for (int i = 0; i < 70; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      textPainter.text = TextSpan(
        text: random.nextBool() ? '1' : '0',
        style: TextStyle(color: kAccentColor.withOpacity(0.15), fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SatelliteSweepPainter extends CustomPainter {
  final double sweepProgress;

  _SatelliteSweepPainter({required this.sweepProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.text = TextSpan(
      text: "CARBONEYE",
      style: kSectionTitleStyle.copyWith(
        fontSize: 40,
        letterSpacing: 1.5,
        color: kSecondaryTextColor.withOpacity(0.3),
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2 + 20),
    );
    textPainter.text = TextSpan(
      text: "Eyes on the forest. Always.",
      style: kSecondaryBodyTextStyle.copyWith(
        fontSize: 16,
        color: kSecondaryTextColor.withOpacity(0.3),
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, -textPainter.height / 2),
    );

    final sweepY = size.height * sweepProgress;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, sweepY));

    final revealedTextPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    revealedTextPainter.text = TextSpan(
      text: "CARBONEYE",
      style: kSectionTitleStyle.copyWith(
        fontSize: 40,
        letterSpacing: 1.5,
        color: kWhiteColor,
      ),
    );
    revealedTextPainter.layout();
    revealedTextPainter.paint(
      canvas,
      center - Offset(revealedTextPainter.width / 2, revealedTextPainter.height / 2 + 20),
    );
    revealedTextPainter.text = TextSpan(
      text: "Eyes on the forest. Always.",
      style: kSecondaryBodyTextStyle.copyWith(
        fontSize: 16,
        color: kWhiteColor.withOpacity(0.9),
      ),
    );
    revealedTextPainter.layout();
    revealedTextPainter.paint(
      canvas,
      center - Offset(revealedTextPainter.width / 2, -revealedTextPainter.height / 2),
    );
    canvas.restore();

    final linePaint = Paint()
      ..color = kAccentColor
      ..strokeWidth = 2.0;
    final glowPaint = Paint()
      ..color = kAccentColor.withOpacity(0.5)
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawLine(Offset(0, sweepY), Offset(size.width, sweepY), glowPaint);
    canvas.drawLine(Offset(0, sweepY), Offset(size.width, sweepY), linePaint);
  }

  @override
  bool shouldRepaint(covariant _SatelliteSweepPainter oldDelegate) {
    return oldDelegate.sweepProgress != sweepProgress;
  }
}
