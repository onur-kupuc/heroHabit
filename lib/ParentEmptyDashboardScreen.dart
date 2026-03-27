import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:super_habit/addChildScreen.dart';

class ParentEmptyDashboardScreen extends StatefulWidget {
  final String parentName;

  const ParentEmptyDashboardScreen({super.key, this.parentName = "Onur"});

  @override
  State<ParentEmptyDashboardScreen> createState() =>
      _ParentEmptyDashboardScreenState();
}

class _ParentEmptyDashboardScreenState extends State<ParentEmptyDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _staggeredController;
  late AnimationController _floatingController;
  late AnimationController _pulseController;

  late Animation<Offset> _headerSlide;
  late Animation<double> _centerFade;
  late Animation<double> _centerScale;
  late Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();

    _staggeredController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -1.0), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _staggeredController,
          curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic)),
    );

    _centerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _staggeredController,
          curve: const Interval(0.3, 0.7, curve: Curves.easeOut)),
    );
    _centerScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
          parent: _staggeredController,
          curve: const Interval(0.3, 0.8, curve: Curves.elasticOut)),
    );

    _fabScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _staggeredController,
          curve: const Interval(0.6, 1.0, curve: Curves.elasticOut)),
    );

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _staggeredController.forward();
  }

  @override
  void dispose() {
    _staggeredController.dispose();
    _floatingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const AnimatedMeshBackground(),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                SlideTransition(
                  position: _headerSlide,
                  child: _buildDynamicGlassHeader(),
                ),
                Expanded(
                  child: FadeTransition(
                    opacity: _centerFade,
                    child: ScaleTransition(
                      scale: _centerScale,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildFloatingHologram(),
                          const SizedBox(height: 40),
                          _buildStoryPlate(),
                        ],
                      ),
                    ),
                  ),
                ),
                ScaleTransition(
                  scale: _fabScale,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 60.0),
                    child: _buildPulseRadarButton(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicGlassHeader() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            border: Border(
              bottom:
                  BorderSide(color: Colors.white.withOpacity(0.3), width: 1.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.15),
                blurRadius: 30,
                spreadRadius: 5,
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Merhaba,",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A237E).withOpacity(0.7),
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    widget.parentName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A237E),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.3),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.5), width: 2),
                ),
                child: const Icon(Icons.settings_rounded,
                    color: Color(0xFF1A237E)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingHologram() {
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        final double yOffset = sin(_floatingController.value * 2 * pi) * 15;

        return Transform.translate(
          offset: Offset(0, yOffset),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.4),
                      blurRadius: 50,
                      spreadRadius: 10,
                    )
                  ],
                ),
              ),
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5C6BC0), Color(0xFF1A237E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                      color: Colors.cyanAccent.withOpacity(0.8), width: 3),
                ),
                child: const Center(
                  child: Icon(
                    Icons.shield_moon_rounded,
                    size: 70,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStoryPlate() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(24),
              border:
                  Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)
              ],
            ),
            child: Column(
              children: [
                const Text(
                  "Macera Başlamak Üzere!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A237E),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Henüz HeroHabit evrenine kayıtlı bir kahraman bulunmuyor. Çocuğunu ve cihazını ekleyerek bu serüveni başlat.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A237E).withOpacity(0.7),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPulseRadarButton() {
    return Stack(
      alignment: Alignment.center,
      children: [
        _buildRippleRing(0.0),
        _buildRippleRing(0.5),
        const PremiumPulseButton(),
      ],
    );
  }

  Widget _buildRippleRing(double delay) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final double progress = (_pulseController.value + delay) % 1.0;

        return Transform.scale(
          scale: 1.0 + (progress * 1.5),
          child: Opacity(
            opacity: 1.0 - progress,
            child: Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.cyanAccent.withOpacity(0.8),
                  width: 3,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class PremiumPulseButton extends StatefulWidget {
  const PremiumPulseButton({super.key});

  @override
  State<PremiumPulseButton> createState() => _PremiumPulseButtonState();
}

class _PremiumPulseButtonState extends State<PremiumPulseButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);

        Future.delayed(const Duration(milliseconds: 150), () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddChildScreen(),
            ),
          );
        });
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.85 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.elasticOut,
        child: Container(
          width: 85,
          height: 85,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF5C6BC0), Color(0xFF1A237E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: _isPressed
                ? [
                    BoxShadow(
                      color: const Color(0xFF1A237E).withOpacity(0.8),
                      blurRadius: 10,
                      spreadRadius: -2,
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.5),
                      blurRadius: 25,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    )
                  ],
          ),
          child: const Center(
            child: Icon(
              Icons.person_add_alt_1_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
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
  late AnimationController _pc;
  List<Color> colors = [
    const Color(0xFFE0F7FA),
    const Color(0xFFFFF9C4),
    const Color(0xFFF1F8E9),
    const Color(0xFFFFE0B2)
  ];
  int idx = 0;

  @override
  void initState() {
    super.initState();
    _pc =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();
    Timer.periodic(const Duration(seconds: 4), (t) {
      if (mounted) setState(() => idx = (idx + 1) % colors.length);
    });
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      AnimatedContainer(
          duration: const Duration(seconds: 4),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colors[idx], colors[(idx + 1) % colors.length]]))),
      AnimatedBuilder(
          animation: _pc,
          builder: (c, ch) => CustomPaint(
              painter: ParticlePainter(_pc.value), child: Container())),
    ]);
  }
}

class ParticlePainter extends CustomPainter {
  final double p;
  ParticlePainter(this.p);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.3);
    final r = Random(42);
    for (int i = 0; i < 20; i++) {
      double x = r.nextDouble() * size.width;
      double y = size.height -
          ((r.nextDouble() * size.height + (p * size.height * 0.5)) %
              size.height);
      canvas.drawCircle(Offset(x, y), r.nextDouble() * 6 + 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
