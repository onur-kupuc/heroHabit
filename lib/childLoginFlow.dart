import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'glass_toast.dart';
import 'parentLoginScreen.dart';

class HeroModel {
  final String id;
  final String name;
  final String avatarUrl;
  final Color themeColor;
  final String pinCode;

  HeroModel({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.themeColor,
    required this.pinCode,
  });

  factory HeroModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String colorHex = data['colorTheme'] ?? 'ff00e5ff';
    return HeroModel(
      id: doc.id,
      name: data['name'] ?? 'Kahraman',
      avatarUrl: data['avatarUrl'] ?? 'assets/images/1.png',
      themeColor: Color(int.parse(colorHex, radix: 16)),
      pinCode: data['pinCode'] ?? '0000',
    );
  }
}

class ChildLoginRouter extends StatefulWidget {
  const ChildLoginRouter({super.key});

  @override
  State<ChildLoginRouter> createState() => _ChildLoginRouterState();
}

class _ChildLoginRouterState extends State<ChildLoginRouter> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isLoading = true;
  String? _pairedParentUid;

  @override
  void initState() {
    super.initState();
    _checkDevicePairing();
  }

  Future<void> _checkDevicePairing() async {
    try {
      _pairedParentUid = await _storage.read(key: 'paired_parent_uid');
    } catch (e) {
      debugPrint("Storage okuma hatası: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF050914),
        body:
            Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
      );
    }

    if (_pairedParentUid == null || _pairedParentUid!.isEmpty) {
      return const DeviceNotPairedScreen();
    }

    return ChildSelectionScreen(parentUid: _pairedParentUid!);
  }
}

class ChildSelectionScreen extends StatefulWidget {
  final String parentUid;
  const ChildSelectionScreen({super.key, required this.parentUid});

  @override
  State<ChildSelectionScreen> createState() => _ChildSelectionScreenState();
}

class _ChildSelectionScreenState extends State<ChildSelectionScreen>
    with TickerProviderStateMixin {
  late Stream<QuerySnapshot> _heroesStream;
  late AnimationController _floatController;
  late AnimationController _staggeredController;

  @override
  void initState() {
    super.initState();
    _heroesStream = FirebaseFirestore.instance
        .collection('parents')
        .doc(widget.parentUid)
        .collection('children')
        .snapshots();

    _floatController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat();

    _staggeredController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _staggeredController.forward();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _staggeredController.dispose();
    super.dispose();
  }

  void _showPinDialog(HeroModel hero) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "PIN",
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, a1, a2) => const SizedBox.shrink(),
      transitionBuilder: (context, a1, a2, child) {
        final curve = Curves.easeOutBack.transform(a1.value);
        return Transform.scale(
          scale: curve,
          child: Opacity(
            opacity: a1.value,
            child: ChildPinBottomSheet(hero: hero),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF050914),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text("HANGİ KAHRAMANSIN?",
            style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2)),
        actions: [
          IconButton(
            icon: Icon(Icons.admin_panel_settings_rounded,
                color: Colors.white.withOpacity(0.2)),
            onPressed: () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const ParentLoginScreen()));
            },
          )
        ],
      ),
      body: Stack(
        children: [
          const AnimatedMeshBackground(),
          Container(color: const Color(0xFF050914).withOpacity(0.6)),
          SafeArea(
            child: StreamBuilder<QuerySnapshot>(
              stream: _heroesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: Colors.cyanAccent));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("Kahraman bulunamadı.",
                          style: TextStyle(color: Colors.white70)));
                }

                List<HeroModel> heroes = snapshot.data!.docs
                    .map((d) => HeroModel.fromFirestore(d))
                    .toList();

                return Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 30,
                      runSpacing: 40,
                      children: List.generate(heroes.length, (index) {
                        final hero = heroes[index];

                        final start = (index * 0.15).clamp(0.0, 0.8);
                        final end = (start + 0.2).clamp(0.0, 1.0);
                        final slideAnim = Tween<Offset>(
                                begin: const Offset(0, 0.5), end: Offset.zero)
                            .animate(CurvedAnimation(
                                parent: _staggeredController,
                                curve: Interval(start, end,
                                    curve: Curves.easeOutBack)));
                        final fadeAnim = Tween<double>(begin: 0.0, end: 1.0)
                            .animate(CurvedAnimation(
                                parent: _staggeredController,
                                curve: Interval(start, end,
                                    curve: Curves.easeIn)));

                        return FadeTransition(
                          opacity: fadeAnim,
                          child: SlideTransition(
                            position: slideAnim,
                            child: AnimatedBuilder(
                              animation: _floatController,
                              builder: (context, child) {
                                final double yOffset = sin(
                                        (_floatController.value * 2 * pi) +
                                            index) *
                                    10;
                                return Transform.translate(
                                  offset: Offset(0, yOffset),
                                  child: child,
                                );
                              },
                              child: GestureDetector(
                                onTap: () => _showPinDialog(hero),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 160,
                                      height: 160,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.05),
                                        border: Border.all(
                                            color: hero.themeColor, width: 4),
                                        boxShadow: [
                                          BoxShadow(
                                              color: hero.themeColor
                                                  .withOpacity(0.4),
                                              blurRadius: 40,
                                              spreadRadius: 5),
                                          BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.5),
                                              blurRadius: 20,
                                              offset: const Offset(0, 10)),
                                        ],
                                      ),
                                      child: ClipOval(
                                          child:
                                              _buildSmartImage(hero.avatarUrl)),
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.4),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.1)),
                                      ),
                                      child: Text(
                                        hero.name.toUpperCase(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 2,
                                          shadows: [
                                            Shadow(
                                                color: hero.themeColor,
                                                blurRadius: 10)
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartImage(String url) {
    if (url.startsWith('http')) {
      return Image.network(url,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) =>
              const Icon(Icons.person, color: Colors.white, size: 60));
    } else {
      return Image.asset(url,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => const Icon(
              Icons.face_retouching_natural_rounded,
              color: Colors.white54,
              size: 60));
    }
  }
}

class ChildPinBottomSheet extends StatefulWidget {
  final HeroModel hero;
  const ChildPinBottomSheet({super.key, required this.hero});

  @override
  State<ChildPinBottomSheet> createState() => _ChildPinBottomSheetState();
}

class _ChildPinBottomSheetState extends State<ChildPinBottomSheet>
    with SingleTickerProviderStateMixin {
  String _enteredPin = "";
  bool _isError = false;
  bool _isSuccess = false;

  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onKeyPress(String value) {
    if (_isError || _isSuccess) return;

    HapticFeedback.lightImpact();

    setState(() {
      if (value == "DEL") {
        if (_enteredPin.isNotEmpty) {
          _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        }
      } else {
        if (_enteredPin.length < 4) {
          _enteredPin += value;
        }
      }
    });

    if (_enteredPin.length == 4) {
      _verifyPin();
    }
  }

  Future<void> _verifyPin() async {
    if (_enteredPin == widget.hero.pinCode) {
      HapticFeedback.heavyImpact();
      setState(() => _isSuccess = true);

      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          Navigator.pop(context);
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => const ChildDashboardPlaceholder()));
        }
      });
    } else {
      HapticFeedback.vibrate();
      setState(() => _isError = true);

      _shakeController.forward(from: 0.0).then((_) {
        setState(() {
          _enteredPin = "";
          _isError = false;
        });
      });
      showGlassToast(context, "Hatalı Şifre!", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) {
          final double offset = sin(_shakeController.value * pi * 5) * 15;
          return Transform.translate(
            offset: Offset(offset, 0),
            child: child,
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 340,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: _isSuccess
                    ? const Color(0xFF00E676).withOpacity(0.2)
                    : (_isError
                        ? const Color(0xFFFF1744).withOpacity(0.2)
                        : Colors.white.withOpacity(0.05)),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                    color: _isSuccess
                        ? const Color(0xFF00E676)
                        : (_isError
                            ? const Color(0xFFFF1744)
                            : Colors.white.withOpacity(0.2)),
                    width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _isSuccess
                        ? const Color(0xFF00E676).withOpacity(0.3)
                        : (_isError
                            ? const Color(0xFFFF1744).withOpacity(0.3)
                            : Colors.black26),
                    blurRadius: 40,
                    spreadRadius: 10,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: widget.hero.themeColor.withOpacity(0.2),
                    backgroundImage: widget.hero.avatarUrl.startsWith('http')
                        ? NetworkImage(widget.hero.avatarUrl)
                        : AssetImage(widget.hero.avatarUrl) as ImageProvider,
                  ),
                  const SizedBox(height: 16),
                  const Text("GİZLİ ŞİFRENİ GİR",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      bool isFilled = index < _enteredPin.length;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          isFilled
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: isFilled
                              ? (_isError
                                  ? const Color(0xFFFF1744)
                                  : widget.hero.themeColor)
                              : Colors.white.withOpacity(0.2),
                          size: 40,
                          shadows: isFilled
                              ? [
                                  Shadow(
                                      color: widget.hero.themeColor,
                                      blurRadius: 15)
                                ]
                              : [],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 320,
                    child: GridView.count(
                      crossAxisCount: 3,
                      childAspectRatio: 1.2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildNumKey("1"),
                        _buildNumKey("2"),
                        _buildNumKey("3"),
                        _buildNumKey("4"),
                        _buildNumKey("5"),
                        _buildNumKey("6"),
                        _buildNumKey("7"),
                        _buildNumKey("8"),
                        _buildNumKey("9"),
                        const SizedBox.shrink(),
                        _buildNumKey("0"),
                        _buildNumKey("DEL", icon: Icons.backspace_rounded),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumKey(String value, {IconData? icon}) {
    return _LiquidNumKey(
      value: value,
      icon: icon,
      themeColor: widget.hero.themeColor,
      onTap: () => _onKeyPress(value),
    );
  }
}

class _LiquidNumKey extends StatefulWidget {
  final String value;
  final IconData? icon;
  final Color themeColor;
  final VoidCallback onTap;

  const _LiquidNumKey(
      {required this.value,
      this.icon,
      required this.themeColor,
      required this.onTap});

  @override
  State<_LiquidNumKey> createState() => _LiquidNumKeyState();
}

class _LiquidNumKeyState extends State<_LiquidNumKey> {
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
        scale: _isPressed ? 0.85 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: Container(
          decoration: BoxDecoration(
            color: _isPressed
                ? widget.themeColor.withOpacity(0.3)
                : Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
            border: Border.all(
                color: _isPressed
                    ? widget.themeColor
                    : Colors.white.withOpacity(0.1)),
            boxShadow: _isPressed
                ? [
                    BoxShadow(
                        color: widget.themeColor.withOpacity(0.4),
                        blurRadius: 15)
                  ]
                : [],
          ),
          child: Center(
            child: widget.icon != null
                ? Icon(widget.icon, color: Colors.white, size: 28)
                : Text(widget.value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900)),
          ),
        ),
      ),
    );
  }
}

class DeviceNotPairedScreen extends StatelessWidget {
  const DeviceNotPairedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050914),
      body: Stack(
        children: [
          const AnimatedMeshBackground(),
          Container(color: Colors.black.withOpacity(0.6)),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.link_off_rounded,
                            color: Colors.cyanAccent, size: 80),
                        const SizedBox(height: 24),
                        const Text("BAĞLANTI YOK",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2)),
                        const SizedBox(height: 16),
                        const Text(
                          "Bu cihaz henüz bir ebeveyn komuta merkezine bağlanmamış. Lütfen ebeveyn uygulamasından 'Cihaz Eşleştir' kodunu okut.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white70, fontSize: 16, height: 1.5),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyanAccent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 16),
                          ),
                          child: const Text("GERİ DÖN",
                              style: TextStyle(
                                  color: Color(0xFF050914),
                                  fontWeight: FontWeight.w900)),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class ChildDashboardPlaceholder extends StatelessWidget {
  const ChildDashboardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050914),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.rocket_launch_rounded,
                color: Colors.greenAccent, size: 100),
            const SizedBox(height: 20),
            const Text("ÇOCUK PANELE HOŞGELDİN",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 40),
            ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Çıkış Yap"))
          ],
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
