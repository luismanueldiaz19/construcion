import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/constants.dart';
import '../../main.dart';
import 'login_screen.dart';

class Spark {
  Offset position;
  Offset velocity;
  double size;
  Color color;
  double opacity;

  Spark({
    required this.position,
    required this.velocity,
    required this.size,
    required this.color,
    this.opacity = 1.0,
  });

  void update() {
    position += velocity;
    // Apply air resistance and gravity
    velocity = Offset(velocity.dx * 0.94, velocity.dy * 0.94 + 0.12);
    opacity = (opacity - 0.035).clamp(0.0, 1.0);
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Spark> _sparks = [];

  bool _strike1SparksEmitted = false;
  bool _strike2SparksEmitted = false;
  bool _strike3SparksEmitted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _controller.addListener(() {
      final t = _controller.value;

      // Update sparks list inside the ticker to trigger redraw
      setState(() {
        for (var spark in _sparks) {
          spark.update();
        }
        _sparks.removeWhere((s) => s.opacity <= 0.0);
      });

      // Emit sparks at specific impact frames
      // Strike 1 Impact at t = 0.11 (nail goes from 0px to 20px)
      if (t >= 0.11 && !_strike1SparksEmitted) {
        _strike1SparksEmitted = true;
        _emitSparks(6, 0.0);
      }
      // Strike 2 Impact at t = 0.29 (nail goes from 20px to 40px)
      if (t >= 0.29 && !_strike2SparksEmitted) {
        _strike2SparksEmitted = true;
        _emitSparks(6, 20.0);
      }
      // Strike 3 Impact at t = 0.47 (nail goes from 40px to 60px - flush)
      if (t >= 0.47 && !_strike3SparksEmitted) {
        _strike3SparksEmitted = true;
        _emitSparks(30, 40.0);
      }
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToNext();
      }
    });

    _controller.forward();
  }

  void _navigateToNext() {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const MainLayout(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  void _emitSparks(int count, double nailDepthPx) {
    final random = Random();
    final double nailHeadX = MediaQuery.of(context).size.width / 2;
    // Nail rests at center vertical + 30px offset
    final double nailHeadY =
        MediaQuery.of(context).size.height / 2 + 10 + nailDepthPx;

    for (int i = 0; i < count; i++) {
      // Angle: upwards and outwards (from -165 to -15 degrees)
      double angle = -15 * pi / 180 - random.nextDouble() * 150 * pi / 180;
      double speed = 2.0 + random.nextDouble() * 9.0;
      double size = 2.0 + random.nextDouble() * 5.0;

      Color color;
      double rand = random.nextDouble();
      if (rand < 0.4) {
        color = const Color(0xFFFFD700); // Gold
      } else if (rand < 0.7) {
        color = const Color(0xFFFFA500); // Orange
      } else if (rand < 0.9) {
        color = const Color(0xFFFF4500); // Red Orange
      } else {
        color = Colors.white; // Hot white
      }

      _sparks.add(
        Spark(
          position: Offset(nailHeadX, nailHeadY),
          velocity: Offset(cos(angle) * speed, sin(angle) * speed),
          size: size,
          color: color,
        ),
      );
    }
  }

  // Calculate screen shake based on key frames
  double _getShake(double t) {
    // Strike 1
    if (t >= 0.11 && t < 0.16) {
      double dt = (t - 0.11) / 0.05;
      return sin(dt * 4 * pi) * (1.0 - dt) * 6.0;
    }
    // Strike 2
    if (t >= 0.29 && t < 0.34) {
      double dt = (t - 0.29) / 0.05;
      return sin(dt * 4 * pi) * (1.0 - dt) * 6.0;
    }
    // Strike 3 (strongest hit)
    if (t >= 0.47 && t < 0.54) {
      double dt = (t - 0.47) / 0.07;
      return sin(dt * 5 * pi) * (1.0 - dt) * 10.0;
    }
    return 0.0;
  }

  double _getNailDepth(double t) {
    if (t < 0.11) return 0.0;
    if (t >= 0.11 && t < 0.29) {
      if (t < 0.14) {
        double ratio = (t - 0.11) / 0.03;
        return ratio * 20.0; // 20px deep
      }
      return 20.0;
    }
    if (t >= 0.29 && t < 0.47) {
      if (t < 0.32) {
        double ratio = (t - 0.29) / 0.03;
        return 20.0 + ratio * 20.0; // 40px deep
      }
      return 40.0;
    }
    // t >= 0.47
    if (t < 0.50) {
      double ratio = (t - 0.47) / 0.03;
      return 40.0 + ratio * 20.0; // 60px deep (flush)
    }
    return 60.0;
  }

  double _getHammerAngle(double t) {
    if (t < 0.06) {
      // Strike 1 lift
      return -0.9 * (t / 0.06);
    } else if (t < 0.11) {
      // Strike 1 swing down
      return -0.9 * (1.0 - (t - 0.06) / 0.05);
    } else if (t < 0.18) {
      // Strike 1 bounce recoil
      double dt = (t - 0.11) / 0.07;
      return -0.15 * sin(dt * pi);
    } else if (t < 0.24) {
      // Strike 2 lift
      return -0.9 * ((t - 0.18) / 0.06);
    } else if (t < 0.29) {
      // Strike 2 swing down
      return -0.9 * (1.0 - (t - 0.24) / 0.05);
    } else if (t < 0.36) {
      // Strike 2 bounce recoil
      double dt = (t - 0.29) / 0.07;
      return -0.15 * sin(dt * pi);
    } else if (t < 0.42) {
      // Strike 3 lift
      return -0.9 * ((t - 0.36) / 0.06);
    } else if (t < 0.47) {
      // Strike 3 swing down
      return -0.9 * (1.0 - (t - 0.42) / 0.05);
    } else if (t < 0.54) {
      // Strike 3 bounce recoil
      double dt = (t - 0.47) / 0.07;
      return -0.15 * sin(dt * pi);
    }
    return 0.0;
  }

  double _getHammerOpacity(double t) {
    if (t < 0.53) return 1.0;
    if (t > 0.65) return 0.0;
    return 1.0 - (t - 0.53) / 0.12;
  }

  double _getLogoOpacity(double t) {
    if (t < 0.55) return 0.0;
    if (t > 0.75) return 1.0;
    return (t - 0.55) / 0.20;
  }

  double _getLogoScale(double t) {
    if (t < 0.55) return 0.0;
    if (t < 0.70) {
      double dt = (t - 0.55) / 0.15;
      return dt * 1.15; // Overshoot to 1.15
    }
    if (t < 0.80) {
      double dt = (t - 0.70) / 0.10;
      return 1.15 - dt * 0.15; // Settle back to 1.0
    }
    return 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _controller.value;
    final shake = _getShake(t);
    final nailDepth = _getNailDepth(t);
    final hammerAngle = _getHammerAngle(t);
    final hammerOpacity = _getHammerOpacity(t);
    final logoOpacity = _getLogoOpacity(t);
    final logoScale = _getLogoScale(t);

    return Scaffold(
      backgroundColor: const Color(
        0xFF1A1C1E,
      ), // Premium dark theme matching sidebar
      body: Stack(
        children: [
          // Background subtle ambient grid/lines
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: GridPaper(
                color: Colors.white,
                divisions: 1,
                subdivisions: 1,
                interval: 40,
              ),
            ),
          ),

          // Hammer, nail and sparks area
          if (hammerOpacity > 0.0)
            Positioned.fill(
              child: Transform.translate(
                offset: Offset(0, shake),
                child: Opacity(
                  opacity: hammerOpacity,
                  child: CustomPaint(
                    painter: ConstructionAnimationPainter(
                      nailDepth: nailDepth,
                      hammerAngle: hammerAngle,
                      sparks: _sparks,
                    ),
                  ),
                ),
              ),
            ),

          // Logo Zoom In Screen
          if (logoOpacity > 0.0)
            Center(
              child: Opacity(
                opacity: logoOpacity,
                child: Transform.scale(
                  scale: logoScale,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo background glow
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFE31E24,
                              ).withValues(alpha: 0.15),
                              blurRadius: 50,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.asset(
                            logoPath,
                            width: 180,
                            height: 180,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback if image has issues loading
                              return Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE31E24),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.construction,
                                  color: Colors.white,
                                  size: 80,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Text branding
                      Text(
                        'NEO PROJECT S.R.L',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              offset: const Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'SISTEMA DE GESTIÓN INTEGRAL',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ConstructionAnimationPainter extends CustomPainter {
  final double nailDepth; // 0.0 to 60.0
  final double hammerAngle; // in radians
  final List<Spark> sparks;

  ConstructionAnimationPainter({
    required this.nailDepth,
    required this.hammerAngle,
    required this.sparks,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Color definitions
    const woodColor1 = Color(0xFF8B5A2B); // Brown wood
    const woodColor2 = Color(0xFF6E4720); // Dark wood shadow
    const nailColor = Color(0xFFBDBDBD); // Light silver
    const shadowColor = Color(0x33000000); // Soft shadow

    // 1. Draw the wood block (the surface)
    // Wood block surface starts at center.dy + 10px
    final woodSurfaceY = center.dy + 10;
    final woodRect = Rect.fromLTRB(
      center.dx - 120,
      woodSurfaceY,
      center.dx + 120,
      woodSurfaceY + 80,
    );

    // Draw wood block shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        woodRect.shift(const Offset(5, 5)),
        const Radius.circular(8),
      ),
      Paint()..color = shadowColor,
    );

    // Draw wood gradient block
    final woodPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [woodColor1, woodColor2],
      ).createShader(woodRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(woodRect, const Radius.circular(8)),
      woodPaint,
    );

    // Draw a small line representing the wood table top texture line
    final linePaint = Paint()
      ..color = const Color(0xFF553311)
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(center.dx - 120, woodSurfaceY + 2),
      Offset(center.dx + 120, woodSurfaceY + 2),
      linePaint,
    );

    // Draw wood grain lines
    final grainPaint = Paint()
      ..color = const Color(0x22FFFFFF)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(center.dx - 110, woodSurfaceY + 25)
        ..quadraticBezierTo(
          center.dx - 20,
          woodSurfaceY + 20,
          center.dx + 110,
          woodSurfaceY + 27,
        )
        ..moveTo(center.dx - 100, woodSurfaceY + 45)
        ..quadraticBezierTo(
          center.dx + 10,
          woodSurfaceY + 50,
          center.dx + 100,
          woodSurfaceY + 43,
        ),
      grainPaint,
    );

    // 2. Draw the nail
    // Nail position is fixed at center.dx horizontally.
    // Vertically, its head starts at woodSurfaceY - 60px (protruding 60px).
    // As nailDepth goes from 0.0 to 60.0, the head sinks down to woodSurfaceY.
    final nailHeadY = woodSurfaceY - 60.0 + nailDepth;
    final nailHeadRect = Rect.fromLTRB(
      center.dx - 10,
      nailHeadY,
      center.dx + 10,
      nailHeadY + 5,
    );

    // Draw nail head
    canvas.drawRect(nailHeadRect, Paint()..color = nailColor);
    // Draw nail head shadow line
    canvas.drawLine(
      Offset(center.dx - 10, nailHeadY + 5),
      Offset(center.dx + 10, nailHeadY + 5),
      Paint()
        ..color = const Color(0xFF757575)
        ..strokeWidth = 1.0,
    );

    // Draw nail shank (only the visible part above the wood)
    final nailShankBottomY = woodSurfaceY;
    if (nailHeadY + 5 < nailShankBottomY) {
      final nailShankRect = Rect.fromLTRB(
        center.dx - 3,
        nailHeadY + 5,
        center.dx + 3,
        nailShankBottomY,
      );
      canvas.drawRect(nailShankRect, Paint()..color = nailColor);
    }

    // 3. Draw the hammer
    // The hammer rotates about a pivot.
    // At rotation 0.0, the hammer head face is exactly at (center.dx, nailHeadY).
    // The pivot point P is defined relative to the nail head: Offset(-80, 80)
    // So the pivot coordinates are (center.dx - 80, nailHeadY + 80).
    final pivot = Offset(center.dx - 80, nailHeadY + 80);

    canvas.save();

    // Rotate canvas around the pivot
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(hammerAngle);
    // Translate back relative coordinates
    canvas.translate(-pivot.dx, -pivot.dy);

    // Draw Hammer shadow first
    final shadowOffset = const Offset(4, 4);
    _drawHammerEntity(
      canvas,
      center,
      nailHeadY,
      pivot,
      Paint()..color = shadowColor,
      shadowOffset,
    );

    // Draw actual Hammer entity
    _drawHammerEntity(canvas, center, nailHeadY, pivot, null, Offset.zero);

    canvas.restore();

    // 4. Draw Sparks
    final sparkPaint = Paint()..style = PaintingStyle.fill;
    for (final spark in sparks) {
      sparkPaint.color = spark.color.withValues(alpha: spark.opacity);
      canvas.drawCircle(spark.position, spark.size, sparkPaint);
    }
  }

  void _drawHammerEntity(
    Canvas canvas,
    Offset center,
    double nailHeadY,
    Offset pivot,
    Paint? customPaint,
    Offset offset,
  ) {
    // Metal head points relative to nail head position (center.dx, nailHeadY)
    final headCenter = Offset(center.dx, nailHeadY) + offset;
    final relativePivot = pivot + offset;

    if (customPaint != null) {
      // Drawing shadow
      // Draw Shadow Handle
      canvas.drawLine(
        Offset(headCenter.dx - 22, headCenter.dy + 5),
        relativePivot,
        Paint()
          ..color = customPaint.color
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round,
      );
      // Draw Shadow Head (rotated to be perpendicular to handle)
      canvas.save();
      canvas.translate(headCenter.dx - 20, headCenter.dy);
      canvas.rotate(0.55);
      canvas.translate(-(headCenter.dx - 20), -headCenter.dy);

      final shadowHeadPath = Path()
        ..moveTo(headCenter.dx, headCenter.dy - 9)
        ..lineTo(headCenter.dx, headCenter.dy + 9)
        ..lineTo(headCenter.dx - 20, headCenter.dy + 8)
        ..lineTo(headCenter.dx - 35, headCenter.dy + 12)
        ..quadraticBezierTo(
          headCenter.dx - 45,
          headCenter.dy + 16,
          headCenter.dx - 65,
          headCenter.dy + 20,
        )
        ..lineTo(headCenter.dx - 66, headCenter.dy + 17)
        ..quadraticBezierTo(
          headCenter.dx - 45,
          headCenter.dy - 6,
          headCenter.dx - 35,
          headCenter.dy - 12,
        )
        ..lineTo(headCenter.dx - 20, headCenter.dy - 8)
        ..close();
      canvas.drawPath(shadowHeadPath, customPaint);
      canvas.restore();
      return;
    }

    // Drawing actual colored elements
    final handlePaint = Paint()
      ..color =
          const Color(0xFFCD853F) // Peruvian Brown Handle
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final gripPaint = Paint()
      ..color =
          const Color(0xFF212121) // Black grip
      ..strokeWidth = 13.5
      ..strokeCap = StrokeCap.round;

    // Draw wood handle
    canvas.drawLine(
      Offset(headCenter.dx - 20, headCenter.dy + 5),
      relativePivot,
      handlePaint,
    );

    // Draw rubber grip at the lower half of the handle
    final gripStart = Offset(
      headCenter.dx - 20 + (relativePivot.dx - (headCenter.dx - 20)) * 0.5,
      headCenter.dy + 5 + (relativePivot.dy - (headCenter.dy + 5)) * 0.5,
    );
    canvas.drawLine(gripStart, relativePivot, gripPaint);

    // Draw metal head (rotated to be perpendicular to handle)
    canvas.save();
    canvas.translate(headCenter.dx - 20, headCenter.dy);
    canvas.rotate(0.55);
    canvas.translate(-(headCenter.dx - 20), -headCenter.dy);

    final headPaint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFFB0BEC5), const Color(0xFF37474F)],
          ).createShader(
            Rect.fromLTRB(
              headCenter.dx - 70,
              headCenter.dy - 15,
              headCenter.dx,
              headCenter.dy + 25,
            ),
          );

    final headPath = Path()
      ..moveTo(headCenter.dx, headCenter.dy - 9)
      ..lineTo(headCenter.dx, headCenter.dy + 9)
      ..lineTo(headCenter.dx - 20, headCenter.dy + 8)
      ..lineTo(headCenter.dx - 35, headCenter.dy + 12)
      ..quadraticBezierTo(
        headCenter.dx - 45,
        headCenter.dy + 16,
        headCenter.dx - 65,
        headCenter.dy + 20,
      )
      ..lineTo(headCenter.dx - 66, headCenter.dy + 17)
      ..quadraticBezierTo(
        headCenter.dx - 45,
        headCenter.dy - 6,
        headCenter.dx - 35,
        headCenter.dy - 12,
      )
      ..lineTo(headCenter.dx - 20, headCenter.dy - 8)
      ..close();

    canvas.drawPath(headPath, headPaint);

    // Draw metal wedge highlights/details on the head
    final detailPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(headCenter.dx - 10, headCenter.dy - 8),
      Offset(headCenter.dx - 10, headCenter.dy + 8),
      detailPaint,
    );
    canvas.drawLine(
      Offset(headCenter.dx - 25, headCenter.dy - 10),
      Offset(headCenter.dx - 25, headCenter.dy + 11),
      detailPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ConstructionAnimationPainter oldDelegate) {
    return oldDelegate.nailDepth != nailDepth ||
        oldDelegate.hammerAngle != hammerAngle ||
        oldDelegate.sparks != sparks;
  }
}
