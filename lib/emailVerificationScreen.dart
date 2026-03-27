import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'main.dart';
import 'parentLoginScreen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String name;
  final String email;

  const EmailVerificationScreen(
      {super.key, required this.name, required this.email});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _authTimer;
  bool _isVerified = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _startVerificationTimer();
  }

  void _startVerificationTimer() {
    _authTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _checkEmailVerificationStatus();
    });
  }

  Future<void> _checkEmailVerificationStatus() async {
    if (_isProcessing) return;

    try {
      User? user = FirebaseAuth.instance.currentUser;
      await user?.reload();

      if (user != null && user.emailVerified) {
        _isProcessing = true;
        _authTimer?.cancel();

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'ad_soyad': widget.name,
          'eposta': widget.email,
          'rol': 'parent',
          'kayit_tarihi': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          setState(() {
            _isVerified = true;
          });

          await FirebaseAuth.instance.signOut();

          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const ParentLoginScreen()),
                (route) => false,
              );
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Hata: $e");
    }
  }

  @override
  void dispose() {
    _authTimer?.cancel();
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
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) =>
                      Transform.scale(scale: value, child: child),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: _isVerified
                                ? Colors.greenAccent.withOpacity(0.6)
                                : Colors.cyanAccent.withOpacity(0.4),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                                color: _isVerified
                                    ? Colors.greenAccent.withOpacity(0.2)
                                    : Colors.cyanAccent.withOpacity(0.1),
                                blurRadius: 30,
                                spreadRadius: 10)
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 600),
                              transitionBuilder: (child, animation) =>
                                  ScaleTransition(
                                      scale: CurvedAnimation(
                                          parent: animation,
                                          curve: Curves.elasticOut),
                                      child: FadeTransition(
                                          opacity: animation, child: child)),
                              child: _isVerified
                                  ? _buildSuccessIcon()
                                  : _buildPulsingMailIcon(),
                            ),
                            const SizedBox(height: 32),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              child: _isVerified
                                  ? const Text(
                                      "Kayıt Başarılı,\nAilemize Hoş Geldin!",
                                      key: ValueKey('Success'),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          height: 1.3))
                                  : Column(
                                      key: const ValueKey('Wait'),
                                      children: [
                                        const Text(
                                            "Kahramanlık yolculuğunun\nbaşlaması için son bir adım!",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                                height: 1.3)),
                                        const SizedBox(height: 16),
                                        RichText(
                                          textAlign: TextAlign.center,
                                          text: TextSpan(
                                            style: TextStyle(
                                                fontSize: 15,
                                                color: Colors.white
                                                    .withOpacity(0.8),
                                                height: 1.5),
                                            children: [
                                              const TextSpan(text: "Lütfen "),
                                              TextSpan(
                                                  text: widget.email,
                                                  style: const TextStyle(
                                                      color: Colors.cyanAccent,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              const TextSpan(
                                                  text:
                                                      " adresine gönderdiğimiz sihirli bağlantıya tıkla."),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulsingMailIcon() {
    return AnimatedBuilder(
      key: const ValueKey('MailIcon'),
      animation: _pulseController,
      builder: (context, child) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF1A237E).withOpacity(0.6),
          boxShadow: [
            BoxShadow(
                color: Colors.cyanAccent
                    .withOpacity(0.2 + (_pulseController.value * 0.4)),
                blurRadius: 20 + (_pulseController.value * 20),
                spreadRadius: 5 + (_pulseController.value * 10))
          ],
          border:
              Border.all(color: Colors.cyanAccent.withOpacity(0.8), width: 2),
        ),
        child: const Icon(Icons.mark_email_unread_rounded,
            color: Colors.cyanAccent, size: 55),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      key: const ValueKey('CheckIcon'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.greenAccent.withOpacity(0.2),
        boxShadow: [
          BoxShadow(
              color: Colors.greenAccent.withOpacity(0.6),
              blurRadius: 30,
              spreadRadius: 10)
        ],
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: const Icon(Icons.check_rounded, color: Colors.white, size: 55),
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
