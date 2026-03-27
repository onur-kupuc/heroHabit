import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:super_habit/parentLoginScreen.dart';
import 'package:super_habit/childLoginFlow.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(const HeroHabitProApp());
}

class HeroHabitProApp extends StatelessWidget {
  const HeroHabitProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HeroHabit',
      theme: ThemeData(
        fontFamily: 'sans-serif',
      ),
      home: const HeroHabitUltraScreen(),
    );
  }
}

class HeroHabitUltraScreen extends StatefulWidget {
  const HeroHabitUltraScreen({super.key});

  @override
  State<HeroHabitUltraScreen> createState() => _HeroHabitUltraScreenState();
}

class _HeroHabitUltraScreenState extends State<HeroHabitUltraScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _sloganOpacity;
  late Animation<Offset> _sloganSlide;
  late Animation<Offset> _cardsSlide;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _sloganOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.3, 0.7, curve: Curves.easeIn)),
    );

    _sloganSlide =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic)),
    );

    _cardsSlide =
        Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.5, 1.0, curve: Curves.elasticOut)),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: _buildGlowingGlassAppBar(),
      ),
      body: Stack(
        children: [
          const AnimatedMeshBackground(),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),
                  const PulsingNeonLogo(),
                  const SizedBox(height: 32),
                  SlideTransition(
                    position: _sloganSlide,
                    child: FadeTransition(
                      opacity: _sloganOpacity,
                      child: const Text(
                        "Eğlen, Öğren, Kazan!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A237E),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                  SlideTransition(
                    position: _cardsSlide,
                    child: Row(
                      children: [
                        Expanded(
                          child: LiquidSpringCard(
                              title: "Çocuk\nGirişi",
                              cardColor: const Color(0xFFFF8A65),
                              imagePath: 'assets/images/childLogin.png',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const ChildLoginRouter()),
                                );
                              }),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: LiquidSpringCard(
                            title: "Ebeveyn\nGirişi",
                            cardColor: const Color(0xFF5C6BC0),
                            imagePath: 'assets/images/parentLogin.png',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ParentLoginScreen()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowingGlassAppBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            border: Border(
              bottom:
                  BorderSide(color: Colors.white.withOpacity(0.2), width: 1.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.1),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.only(bottom: 16),
          child: const ShimmerText(text: "HEROHABİT"),
        ),
      ),
    );
  }
}

class ShimmerText extends StatefulWidget {
  final String text;
  const ShimmerText({super.key, required this.text});

  @override
  State<ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: const [
                Color(0xFF1A237E),
                Colors.cyanAccent,
                Color(0xFF1A237E)
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-1.0 + (_controller.value * 2), 0),
              end: Alignment(0.0 + (_controller.value * 2), 0),
            ).createShader(bounds);
          },
          child: Text(
            widget.text,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 3.0,
            ),
          ),
        );
      },
    );
  }
}

class PulsingNeonLogo extends StatefulWidget {
  const PulsingNeonLogo({super.key});

  @override
  State<PulsingNeonLogo> createState() => _PulsingNeonLogoState();
}

class _PulsingNeonLogoState extends State<PulsingNeonLogo>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _pulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _rotationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          RotationTransition(
            turns: _rotationController,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    Colors.cyanAccent.withOpacity(0.0),
                    Colors.pinkAccent,
                    Colors.yellowAccent,
                    Colors.cyanAccent.withOpacity(0.0),
                  ],
                  stops: const [0.0, 0.4, 0.6, 1.0],
                ),
              ),
            ),
          ),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.white.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5),
              ],
            ),
            child: const Center(
              child:
                  Icon(Icons.star_rounded, size: 72, color: Color(0xFFFFB300)),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedMeshBackground extends StatefulWidget {
  const AnimatedMeshBackground({super.key});

  @override
  State<AnimatedMeshBackground> createState() => _AnimatedMeshBackgroundState();
}

class _AnimatedMeshBackgroundState extends State<AnimatedMeshBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _particleController;
  List<Color> colorList = [
    const Color(0xFFE0F7FA),
    const Color(0xFFFFF9C4),
    const Color(0xFFF1F8E9),
    const Color(0xFFFFE0B2)
  ];
  int index = 0;
  Color bottomColor = const Color(0xFFE0F7FA);
  Color topColor = const Color(0xFFFFF9C4);

  @override
  void initState() {
    super.initState();
    _particleController =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();
    Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          index = (index + 1) % colorList.length;
          bottomColor = colorList[index];
          topColor = colorList[(index + 1) % colorList.length];
        });
      }
    });
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(seconds: 4),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [topColor, bottomColor],
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _particleController,
          builder: (context, child) {
            return CustomPaint(
              painter: ParticlePainter(_particleController.value),
              child: Container(),
            );
          },
        ),
      ],
    );
  }
}

class ParticlePainter extends CustomPainter {
  final double progress;
  ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    final random = Random(42);

    for (int i = 0; i < 20; i++) {
      double x = random.nextDouble() * size.width;
      double y = size.height -
          ((random.nextDouble() * size.height +
                  (progress * size.height * 0.5)) %
              size.height);
      double radius = random.nextDouble() * 6 + 2;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class LiquidSpringCard extends StatefulWidget {
  final String title;
  final Color cardColor;
  final String imagePath;
  final VoidCallback onTap;

  const LiquidSpringCard({
    super.key,
    required this.title,
    required this.cardColor,
    required this.imagePath,
    required this.onTap,
  });

  @override
  State<LiquidSpringCard> createState() => _LiquidSpringCardState();
}

class _LiquidSpringCardState extends State<LiquidSpringCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        Future.delayed(const Duration(milliseconds: 100), widget.onTap);
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.elasticOut,
        child: Container(
          decoration: BoxDecoration(
            color: widget.cardColor,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: widget.cardColor.withOpacity(0.5),
                blurRadius: _isPressed ? 10 : 25,
                offset: Offset(0, _isPressed ? 4 : 15),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: -2,
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.5), width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset(
                        widget.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              'Resim\nBekleniyor',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
