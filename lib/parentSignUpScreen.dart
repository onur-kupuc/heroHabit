import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:super_habit/glass_toast.dart';
import 'package:super_habit/emailVerificationScreen.dart';

class ParentSignUpScreen extends StatefulWidget {
  const ParentSignUpScreen({super.key});

  @override
  State<ParentSignUpScreen> createState() => _ParentSignUpScreenState();
}

class _ParentSignUpScreenState extends State<ParentSignUpScreen>
    with TickerProviderStateMixin {
  late AnimationController _staggeredController;
  late AnimationController _headerPulseController;

  late Animation<Offset> _headerSlide;
  late Animation<double> _headerFade;

  late Animation<Offset> _nameSlide;
  late Animation<Offset> _emailSlide;
  late Animation<Offset> _passSlide;
  late Animation<Offset> _confirmPassSlide;
  late Animation<Offset> _checkboxSlide;
  late Animation<Offset> _actionSlide;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPassFocus = FocusNode();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isTermsAccepted = false;

  bool _isLoading = false;

  Future<void> _handleSignUp() async {
    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String confirmPass = _confirmPassController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      showGlassToast(context, "Lütfen tüm sihirli alanları doldur.",
          isError: true);
      return;
    }
    if (password != confirmPass) {
      showGlassToast(context, "Şifreler eşleşmiyor, lütfen kontrol et.",
          isError: true);
      return;
    }
    if (!_isTermsAccepted) {
      showGlassToast(context, "Devam etmek için kuralları kabul etmelisin.",
          isError: true);
      return;
    }

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.sendEmailVerification();

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(name: name, email: email),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Bir hata oluştu.";
      if (e.code == 'weak-password') {
        errorMessage = "Şifren çok zayıf. Daha güçlü bir kalkan yarat!";
      } else if (e.code == 'email-already-in-use') {
        errorMessage = "Bu e-posta zaten kahraman ailemizde kayıtlı!";
      } else if (e.code == 'invalid-email') {
        errorMessage = "Geçersiz bir e-posta formatı girdin.";
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

    _staggeredController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _staggeredController,
          curve: const Interval(0.0, 0.3, curve: Curves.easeOut)),
    );
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _staggeredController,
          curve: const Interval(0.0, 0.4, curve: Curves.elasticOut)),
    );

    _nameSlide =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _staggeredController,
          curve: const Interval(0.1, 0.5, curve: Curves.easeOutBack)),
    );
    _emailSlide =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _staggeredController,
          curve: const Interval(0.2, 0.6, curve: Curves.easeOutBack)),
    );
    _passSlide =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _staggeredController,
          curve: const Interval(0.3, 0.7, curve: Curves.easeOutBack)),
    );
    _confirmPassSlide =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _staggeredController,
          curve: const Interval(0.4, 0.8, curve: Curves.easeOutBack)),
    );
    _checkboxSlide =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _staggeredController,
          curve: const Interval(0.5, 0.9, curve: Curves.easeOutBack)),
    );
    _actionSlide =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _staggeredController,
          curve: const Interval(0.6, 1.0, curve: Curves.elasticOut)),
    );

    _headerPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _staggeredController.forward();
  }

  @override
  void dispose() {
    _staggeredController.dispose();
    _headerPulseController.dispose();

    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPassController.dispose();

    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPassFocus.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Stack(
        children: [
          AnimatedMeshBackground(),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
              child: Column(
                children: [
                  FadeTransition(
                    opacity: _headerFade,
                    child: SlideTransition(
                      position: _headerSlide,
                      child: const HeroFamilyHeader(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SlideTransition(
                    position: _nameSlide,
                    child: PremiumGlassTextField(
                      hintText: "Ad Soyad",
                      icon: Icons.person_rounded,
                      controller: _nameController,
                      focusNode: _nameFocus,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SlideTransition(
                    position: _emailSlide,
                    child: PremiumGlassTextField(
                      hintText: "E-posta Adresi",
                      icon: Icons.alternate_email_rounded,
                      controller: _emailController,
                      focusNode: _emailFocus,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SlideTransition(
                    position: _passSlide,
                    child: PremiumGlassTextField(
                      hintText: "Şifre",
                      icon: Icons.lock_outline_rounded,
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      isPassword: true,
                      isPasswordVisible: _isPasswordVisible,
                      onVisibilityToggle: () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SlideTransition(
                    position: _confirmPassSlide,
                    child: PremiumGlassTextField(
                      hintText: "Şifre Tekrar",
                      icon: Icons.lock_reset_rounded,
                      controller: _confirmPassController,
                      focusNode: _confirmPassFocus,
                      isPassword: true,
                      isPasswordVisible: _isConfirmPasswordVisible,
                      onVisibilityToggle: () => setState(() =>
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SlideTransition(
                    position: _checkboxSlide,
                    child: PremiumGlassCheckbox(
                      value: _isTermsAccepted,
                      onChanged: (val) =>
                          setState(() => _isTermsAccepted = val),
                    ),
                  ),
                  const SizedBox(height: 35),
                  SlideTransition(
                    position: _actionSlide,
                    child: Column(
                      children: [
                        _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.cyanAccent))
                            : PremiumLiquidButton(
                                text: "AİLEMİZİ KUR",
                                onTap: _handleSignUp,
                              ),
                        const SizedBox(height: 24),
                        const PremiumGlassFooterAction(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HeroFamilyHeader extends StatefulWidget {
  const HeroFamilyHeader({super.key});

  @override
  State<HeroFamilyHeader> createState() => _HeroFamilyHeaderState();
}

class _HeroFamilyHeaderState extends State<HeroFamilyHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, child) {
              return Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5C6BC0), Color(0xFF1A237E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent
                          .withOpacity(0.3 + (_pulseCtrl.value * 0.4)),
                      blurRadius: 25,
                      spreadRadius: 5 + (_pulseCtrl.value * 5),
                    )
                  ],
                  border: Border.all(
                      color: Colors.white.withOpacity(0.8), width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.volunteer_activism_rounded,
                      color: Colors.white, size: 45),
                ),
              );
            }),
        const SizedBox(height: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.white.withOpacity(0.5), width: 1.5),
              ),
              child: const Text(
                "HeroHabit Ailesine Katıl",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A237E),
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PremiumGlassCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const PremiumGlassCheckbox(
      {super.key, required this.value, required this.onChanged});

  @override
  State<PremiumGlassCheckbox> createState() => _PremiumGlassCheckboxState();
}

class _PremiumGlassCheckboxState extends State<PremiumGlassCheckbox> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onChanged(!widget.value);
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: widget.value
                    ? const Color(0xFF1A237E)
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.value
                      ? Colors.cyanAccent
                      : Colors.white.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: widget.value
                    ? [
                        BoxShadow(
                            color: Colors.cyanAccent.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 1)
                      ]
                    : [],
              ),
              child: Center(
                child: AnimatedOpacity(
                  opacity: widget.value ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: AnimatedScale(
                    scale: widget.value ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.elasticOut,
                    child: const Icon(Icons.check_rounded,
                        color: Colors.cyanAccent, size: 20),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A237E).withOpacity(0.8),
                    height: 1.3,
                  ),
                  children: const [
                    TextSpan(
                        text: "Kullanım Koşulları",
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A237E),
                            decoration: TextDecoration.underline)),
                    TextSpan(text: " ve "),
                    TextSpan(
                        text: "Gizlilik Politikası",
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A237E),
                            decoration: TextDecoration.underline)),
                    TextSpan(text: "'nı okudum, kabul ediyorum."),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PremiumGlassFooterAction extends StatelessWidget {
  const PremiumGlassFooterAction({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Zaten bir kahraman mısın?",
                  style: TextStyle(
                    color: const Color(0xFF1A237E).withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  "Giriş Yap",
                  style: TextStyle(
                    color: Color(0xFF1A237E),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PremiumGlassTextField extends StatefulWidget {
  final String hintText;
  final IconData icon;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isPassword;
  final bool isPasswordVisible;
  final VoidCallback? onVisibilityToggle;

  const PremiumGlassTextField({
    super.key,
    required this.hintText,
    required this.icon,
    required this.controller,
    required this.focusNode,
    this.isPassword = false,
    this.isPasswordVisible = false,
    this.onVisibilityToggle,
  });

  @override
  State<PremiumGlassTextField> createState() => _PremiumGlassTextFieldState();
}

class _PremiumGlassTextFieldState extends State<PremiumGlassTextField> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      setState(() => _isFocused = widget.focusNode.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                    color: const Color(0xFF5C6BC0).withOpacity(0.4),
                    blurRadius: 25,
                    spreadRadius: 2,
                    offset: const Offset(0, 8))
              ]
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 4))
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            decoration: BoxDecoration(
              color: _isFocused
                  ? Colors.white.withOpacity(0.3)
                  : Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: _isFocused
                      ? Colors.cyanAccent.withOpacity(0.8)
                      : Colors.white.withOpacity(0.4),
                  width: 1.5),
            ),
            child: Row(
              children: [
                Icon(widget.icon,
                    color: _isFocused
                        ? const Color(0xFF1A237E)
                        : const Color(0xFF5C6BC0),
                    size: 26),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    obscureText: widget.isPassword && !widget.isPasswordVisible,
                    style: const TextStyle(
                        color: Color(0xFF1A237E),
                        fontSize: 18,
                        fontWeight: FontWeight.w700),
                    cursorColor: const Color(0xFF1A237E),
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: TextStyle(
                          color: const Color(0xFF1A237E).withOpacity(0.5),
                          fontWeight: FontWeight.w600),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (widget.isPassword)
                  IconButton(
                    icon: Icon(
                        widget.isPasswordVisible
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        color: _isFocused
                            ? const Color(0xFF1A237E)
                            : const Color(0xFF5C6BC0)),
                    onPressed: widget.onVisibilityToggle,
                    splashRadius: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PremiumLiquidButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  const PremiumLiquidButton(
      {super.key, required this.text, required this.onTap});

  @override
  State<PremiumLiquidButton> createState() => _PremiumLiquidButtonState();
}

class _PremiumLiquidButtonState extends State<PremiumLiquidButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        Future.delayed(const Duration(milliseconds: 150), widget.onTap);
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 65,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
                colors: [Color(0xFF5C6BC0), Color(0xFF1A237E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            boxShadow: _isPressed
                ? [
                    BoxShadow(
                        color: const Color(0xFF1A237E).withOpacity(0.8),
                        blurRadius: 10,
                        spreadRadius: -2,
                        offset: const Offset(0, 2))
                  ]
                : [
                    BoxShadow(
                        color: const Color(0xFF5C6BC0).withOpacity(0.6),
                        blurRadius: 25,
                        spreadRadius: 4,
                        offset: const Offset(0, 10)),
                    BoxShadow(
                        color: Colors.white.withOpacity(0.2),
                        blurRadius: 5,
                        offset: const Offset(0, -2))
                  ],
          ),
          child: Center(
            child: Text(widget.text,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5)),
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
