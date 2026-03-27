import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:super_habit/firebase_options.dart';
import 'package:super_habit/parentSignUpScreen.dart';
import 'package:super_habit/glass_toast.dart';
import 'package:super_habit/parentDashboardRouter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const HeroHabitProApp());
}

class HeroHabitProApp extends StatelessWidget {
  const HeroHabitProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HeroHabit',
      theme: ThemeData(fontFamily: 'sans-serif'),
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
        vsync: this, duration: const Duration(milliseconds: 1800));
    _sloganOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.3, 0.7, curve: Curves.easeIn)));
    _sloganSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic)));
    _cardsSlide = Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.5, 1.0, curve: Curves.elasticOut)));
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
        child: _buildGlowingGlassAppBar("SUPERHERO", Colors.cyanAccent),
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
                      child: const Text("Eğlen, Öğren, Kazan!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1A237E),
                              letterSpacing: 1.5)),
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
                                onTap: () => debugPrint("Çocuk Girişi"))),
                        const SizedBox(width: 20),
                        Expanded(
                          child: LiquidSpringCard(
                            title: "Ebeveyn\nGirişi",
                            cardColor: const Color(0xFF5C6BC0),
                            imagePath: 'assets/images/parentLogin.png',
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ParentLoginScreen())),
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

  Widget _buildGlowingGlassAppBar(String text, Color glowColor) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            border: Border(
                bottom: BorderSide(
                    color: Colors.white.withOpacity(0.2), width: 1.5)),
            boxShadow: [
              BoxShadow(
                  color: glowColor.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 5)
            ],
          ),
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.only(bottom: 16),
          child: ShimmerText(text: text),
        ),
      ),
    );
  }
}

class ParentLoginScreen extends StatefulWidget {
  const ParentLoginScreen({super.key});

  @override
  State<ParentLoginScreen> createState() => _ParentLoginScreenState();
}

class _ParentLoginScreenState extends State<ParentLoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _staggeredAnimationController;
  late Animation<Offset> _avatarSlide,
      _emailSlide,
      _passwordSlide,
      _loginButtonSlide,
      _linksSlide;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _isLoading = false;

  Future<void> _handleLogin() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showGlassToast(context, "Lütfen tüm alanları doldur.", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!userCredential.user!.emailVerified) {
        showGlassToast(context, "Lütfen önce e-postanı doğrula!",
            isError: true);
        await FirebaseAuth.instance.signOut();
        setState(() => _isLoading = false);
        return;
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ParentDashboardRouter()),
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("GİRİŞ HATASI: ${e.code}");
      String errorMessage = "Giriş yapılamadı.";
      if (e.code == 'user-not-found' ||
          e.code == 'invalid-credential' ||
          e.code == 'wrong-password') {
        errorMessage = "E-posta veya şifre hatalı.";
      }
      showGlassToast(context, errorMessage, isError: true);
    } catch (e) {
      showGlassToast(context, "Beklenmeyen bir hata oluştu.", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _staggeredAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _avatarSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _staggeredAnimationController,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic)));
    _emailSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _staggeredAnimationController,
            curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic)));
    _passwordSlide =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _staggeredAnimationController,
                curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic)));
    _loginButtonSlide =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _staggeredAnimationController,
                curve: const Interval(0.4, 0.9, curve: Curves.elasticOut)));
    _linksSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _staggeredAnimationController,
            curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic)));
    _staggeredAnimationController.forward();
  }

  @override
  void dispose() {
    _staggeredAnimationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: _buildParentAppBar(),
      ),
      body: Stack(
        children: [
          const AnimatedMeshBackground(),
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 130),
                  SlideTransition(
                      position: _avatarSlide,
                      child: const ParentAvatarWithGlow()),
                  const SizedBox(height: 50),
                  SlideTransition(
                    position: _emailSlide,
                    child: GlassmorphismTextField(
                      hintText: 'E-posta Adresi',
                      icon: Icons.email_rounded,
                      controller: _emailController,
                      focusNode: _emailFocus,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SlideTransition(
                    position: _passwordSlide,
                    child: GlassmorphismTextField(
                      hintText: 'Şifre',
                      icon: Icons.lock_rounded,
                      isPassword: true,
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SlideTransition(
                    position: _linksSlide,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: Text('Şifremi Unuttum?',
                            style: TextStyle(
                                color: const Color(0xFF1A237E),
                                fontWeight: FontWeight.w800,
                                shadows: [
                                  Shadow(
                                      color: Colors.white.withOpacity(0.5),
                                      blurRadius: 10)
                                ])),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SlideTransition(
                      position: _loginButtonSlide,
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.cyanAccent)
                          : GlowingNeonButton(
                              text: 'Giriş Yap',
                              onTap: _handleLogin,
                              buttonColor: const Color(0xFF5C6BC0))),
                  const SizedBox(height: 30),
                  SlideTransition(
                    position: _linksSlide,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20)),
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ParentSignUpScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Hesabın yok mu? Üye Ol',
                          style: TextStyle(
                              color: Color(0xFF1A237E),
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParentAppBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              border: Border(
                  bottom: BorderSide(
                      color: Colors.white.withOpacity(0.2), width: 1.5)),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF5C6BC0).withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5)
              ]),
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.only(bottom: 16),
          child: const ShimmerText(text: "EBEVEYN GİRİŞİ"),
        ),
      ),
    );
  }
}

class ParentAvatarWithGlow extends StatefulWidget {
  const ParentAvatarWithGlow({super.key});

  @override
  State<ParentAvatarWithGlow> createState() => _ParentAvatarWithGlowState();
}

class _ParentAvatarWithGlowState extends State<ParentAvatarWithGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          RotationTransition(
            turns: _rotationController,
            child: Container(
              width: 135,
              height: 135,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    Colors.pinkAccent.withOpacity(0.1),
                    Colors.cyanAccent,
                    Colors.yellowAccent,
                    Colors.pinkAccent,
                    Colors.pinkAccent.withOpacity(0.1),
                  ],
                  stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  )
                ],
              ),
            ),
          ),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF5C6BC0).withOpacity(0.8),
              shape: BoxShape.circle,
              border:
                  Border.all(color: Colors.white.withOpacity(0.9), width: 3),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2)
              ],
            ),
            child:
                const Icon(Icons.person_rounded, size: 70, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class GlassmorphismTextField extends StatefulWidget {
  final String hintText;
  final IconData icon;
  final bool isPassword;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  const GlassmorphismTextField({
    super.key,
    required this.hintText,
    required this.icon,
    this.isPassword = false,
    this.controller,
    this.focusNode,
  });

  @override
  State<GlassmorphismTextField> createState() => _GlassmorphismTextFieldState();
}

class _GlassmorphismTextFieldState extends State<GlassmorphismTextField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focus) => setState(() => _isFocused = focus),
      focusNode: widget.focusNode,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: _isFocused
                  ? Colors.white.withOpacity(0.35)
                  : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _isFocused
                      ? const Color(0xFF5C6BC0)
                      : Colors.white.withOpacity(0.4),
                  width: 2),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                          color: const Color(0xFF5C6BC0).withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2)
                    ]
                  : [],
            ),
            child: TextField(
              controller: widget.controller,
              obscureText: widget.isPassword,
              style: const TextStyle(
                  color: Color(0xFF1A237E),
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle:
                    TextStyle(color: const Color(0xFF1A237E).withOpacity(0.5)),
                prefixIcon: Icon(widget.icon, color: const Color(0xFF5C6BC0)),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlowingNeonButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final Color buttonColor;
  const GlowingNeonButton(
      {super.key,
      required this.text,
      required this.onTap,
      required this.buttonColor});
  @override
  State<GlowingNeonButton> createState() => _GlowingNeonButtonState();
}

class _GlowingNeonButtonState extends State<GlowingNeonButton> {
  bool _isPressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
                colors: [widget.buttonColor, widget.buttonColor.withBlue(255)]),
            boxShadow: [
              BoxShadow(
                  color: widget.buttonColor.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10))
            ],
          ),
          child: Center(
              child: Text(widget.text,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2))),
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
          shaderCallback: (bounds) => LinearGradient(
            colors: const [
              Color(0xFF1A237E),
              Colors.cyanAccent,
              Color(0xFF1A237E)
            ],
            stops: const [0.0, 0.5, 1.0],
            begin: Alignment(-1.0 + (_controller.value * 2), 0),
            end: Alignment(0.0 + (_controller.value * 2), 0),
          ).createShader(bounds),
          child: Text(widget.text,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2.0)),
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
  late AnimationController _pulse, _rot;
  @override
  void initState() {
    super.initState();
    _pulse =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _rot =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _rot.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.95, end: 1.05).animate(
          CurvedAnimation(parent: _pulse, curve: Curves.easeInOutSine)),
      child: Stack(alignment: Alignment.center, children: [
        RotationTransition(
            turns: _rot,
            child: Container(
                width: 150,
                height: 150,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(colors: [
                      Colors.cyanAccent,
                      Colors.pinkAccent,
                      Colors.yellowAccent,
                      Colors.cyanAccent
                    ], stops: [
                      0.0,
                      0.4,
                      0.6,
                      1.0
                    ])))),
        Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85), shape: BoxShape.circle),
            child: const Center(
                child: Icon(Icons.star_rounded,
                    size: 72, color: Color(0xFFFFB300)))),
      ]),
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

class LiquidSpringCard extends StatefulWidget {
  final String title;
  final Color cardColor;
  final String imagePath;
  final VoidCallback onTap;
  const LiquidSpringCard(
      {super.key,
      required this.title,
      required this.cardColor,
      required this.imagePath,
      required this.onTap});
  @override
  State<LiquidSpringCard> createState() => _LiquidSpringCardState();
}

class _LiquidSpringCardState extends State<LiquidSpringCard> {
  bool _isP = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isP = true),
      onTapUp: (_) {
        setState(() => _isP = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isP = false),
      child: AnimatedScale(
        scale: _isP ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.elasticOut,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: widget.cardColor,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                    color: widget.cardColor.withOpacity(0.5),
                    blurRadius: _isP ? 10 : 25,
                    offset: Offset(0, _isP ? 4 : 15))
              ]),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AspectRatio(
                aspectRatio: 1,
                child: Container(
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(24)),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.asset(widget.imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const Center(
                                child: Text("Resim\nBekleniyor",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10))))))),
            const SizedBox(height: 16),
            Text(widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
    );
  }
}
