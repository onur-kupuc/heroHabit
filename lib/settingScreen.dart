import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:super_habit/editChildScreen.dart';
import 'dart:async';

import 'addChildScreen.dart';
import 'parentPairingScreen.dart';

class ParentSettingsScreen extends StatefulWidget {
  const ParentSettingsScreen({super.key});

  @override
  State<ParentSettingsScreen> createState() => _ParentSettingsScreenState();
}

class _ParentSettingsScreenState extends State<ParentSettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _avatarPulseController;

  bool _isParentLockEnabled = true;
  bool _isVacationModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _avatarPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _avatarPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF050914),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            "KOMUTA MERKEZİ",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              fontSize: 16,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Stack(
        children: [
          const AnimatedMeshBackground(),
          Container(color: const Color(0xFF050914).withOpacity(0.85)),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.only(
                  left: 20, right: 20, top: 10, bottom: 50),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 35),
                  _buildSectionTitle("AİLE VE KAHRAMANLAR"),
                  VisionGlassGroup(
                    children: [
                      _buildSettingsRow(
                        icon: Icons.person_add_alt_1_rounded,
                        iconColor: Colors.cyanAccent,
                        title: "Yeni Kahraman Ekle",
                        subtitle: "Ailene yeni bir üye katıl",
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      const AddChildScreen(),
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                return FadeTransition(
                                    opacity: animation, child: child);
                              },
                              transitionDuration:
                                  const Duration(milliseconds: 400),
                            ),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildSettingsRow(
                        icon: Icons.edit_note_rounded,
                        iconColor: const Color(0xFFB388FF),
                        title: "Kahramanları Düzenle",
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      const EditChildScreen(),
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                return FadeTransition(
                                    opacity: animation, child: child);
                              },
                              transitionDuration:
                                  const Duration(milliseconds: 400),
                            ),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildSettingsRow(
                        icon: Icons.qr_code_scanner_rounded,
                        iconColor: const Color(0xFF00E676),
                        title: "Cihaz Eşleştirme",
                        subtitle: "Çocuğun tabletini bağla",
                        onTap: () {
                          showPairingHeroSelector(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _buildSectionTitle("GÜVENLİK"),
                  VisionGlassGroup(
                    children: [
                      _buildSettingsRow(
                        icon: Icons.face_retouching_natural_rounded,
                        iconColor: const Color(0xFF2979FF),
                        title: "Ebeveyn Kilidi",
                        subtitle: "Ayarları FaceID/PIN ile koru",
                        trailing: CupertinoSwitch(
                          value: _isParentLockEnabled,
                          activeColor: const Color(0xFF2979FF),
                          onChanged: (val) =>
                              setState(() => _isParentLockEnabled = val),
                        ),
                        onTap: () => setState(
                            () => _isParentLockEnabled = !_isParentLockEnabled),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _buildSectionTitle("SİSTEM & OYUNLAŞTIRMA"),
                  VisionGlassGroup(
                    children: [
                      _buildSettingsRow(
                        icon: Icons.access_alarm_rounded,
                        iconColor: const Color(0xFFFF4081),
                        title: "Hatırlatıcılar",
                        onTap: () {},
                      ),
                      _buildDivider(),
                      _buildSettingsRow(
                        icon: Icons.ac_unit_rounded,
                        iconColor: _isVacationModeEnabled
                            ? const Color(0xFF00E5FF)
                            : Colors.white54,
                        title: "Tatil Modu",
                        subtitle: "Görev serileri (streak) bozulmaz",
                        trailing: CupertinoSwitch(
                          value: _isVacationModeEnabled,
                          activeColor: const Color(0xFF00E5FF),
                          onChanged: (val) =>
                              setState(() => _isVacationModeEnabled = val),
                        ),
                        onTap: () => setState(() =>
                            _isVacationModeEnabled = !_isVacationModeEnabled),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _buildSectionTitle("HESAP"),
                  VisionGlassGroup(
                    children: [
                      _buildSettingsRow(
                        icon: Icons.help_outline_rounded,
                        iconColor: Colors.white70,
                        title: "Yardım ve SSS",
                        onTap: () {},
                      ),
                      _buildDivider(),
                      _buildSettingsRow(
                        icon: Icons.logout_rounded,
                        iconColor: const Color(0xFFFF1744),
                        title: "Oturumu Kapat",
                        titleColor: const Color(0xFFFF1744),
                        hideChevron: true,
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 35),
                  TactileButtonWrapper(
                    onTap: () {},
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF1744).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFFFF1744).withOpacity(0.3),
                            width: 1.5),
                      ),
                      child: const Center(
                        child: Text(
                          "HESABI SİL",
                          style: TextStyle(
                              color: Color(0xFFFF1744),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withOpacity(0.1),
      height: 1,
      thickness: 1,
      indent: 60,
      endIndent: 0,
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            AnimatedBuilder(
              animation: _avatarPulseController,
              builder: (context, child) {
                return Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(
                            0.2 + (_avatarPulseController.value * 0.3)),
                        blurRadius: 20 + (_avatarPulseController.value * 20),
                        spreadRadius: 2,
                      )
                    ],
                    border: Border.all(
                        color: Colors.cyanAccent.withOpacity(0.5), width: 3),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/parent_avatar.png',
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: Colors.white.withOpacity(0.1),
                        child: const Icon(Icons.person,
                            color: Colors.white54, size: 50),
                      ),
                    ),
                  ),
                );
              },
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 10)
                ],
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  color: Colors.white, size: 14),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          "Onur Küpüç",
          style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2),
        ),
        const SizedBox(height: 4),
        Text(
          "onur@herohabit.com",
          style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Color? titleColor,
    Widget? trailing,
    bool hideChevron = false,
    required VoidCallback onTap,
  }) {
    return TactileButtonWrapper(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: iconColor.withOpacity(0.3), width: 1),
                boxShadow: [
                  BoxShadow(color: iconColor.withOpacity(0.2), blurRadius: 10)
                ],
              ),
              child: Center(child: Icon(icon, color: iconColor, size: 20)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor ?? Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ]
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else if (!hideChevron)
              Icon(Icons.chevron_right_rounded,
                  color: Colors.white.withOpacity(0.3), size: 24),
          ],
        ),
      ),
    );
  }
}

class VisionGlassGroup extends StatelessWidget {
  final List<Widget> children;

  const VisionGlassGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

class TactileButtonWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const TactileButtonWrapper(
      {super.key, required this.child, required this.onTap});

  @override
  State<TactileButtonWrapper> createState() => _TactileButtonWrapperState();
}

class _TactileButtonWrapperState extends State<TactileButtonWrapper> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: widget.child,
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
