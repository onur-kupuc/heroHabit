import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'glass_toast.dart';

void showPairingHeroSelector(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const _PairingHeroSelectorSheet(),
  );
}

class _PairingHeroSelectorSheet extends StatefulWidget {
  const _PairingHeroSelectorSheet();

  @override
  State<_PairingHeroSelectorSheet> createState() =>
      _PairingHeroSelectorSheetState();
}

class _PairingHeroSelectorSheetState extends State<_PairingHeroSelectorSheet> {
  late Stream<QuerySnapshot> _heroesStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _heroesStream = FirebaseFirestore.instance
          .collection('parents')
          .doc(user.uid)
          .collection('children')
          .orderBy('createdAt')
          .snapshots();
    } else {
      _heroesStream = const Stream<QuerySnapshot>.empty();
    }
  }

  void _handleHeroSelection(
      String heroId, String heroName, Color themeColor, bool isPaired) {
    if (isPaired) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF0F172A).withOpacity(0.9),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: themeColor.withOpacity(0.5))),
          title: const Text("Yeniden Eşleştir?",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text(
            "Bu kahraman zaten bir cihaza bağlı. Yeni bir eşleştirme yaparsan eski cihazın bağlantısı koparılacak. Emin misin?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text("İptal", style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
                _navigateToPairing(heroId, heroName, themeColor);
              },
              child: const Text("Evet, Devam Et",
                  style: TextStyle(
                      color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
      _navigateToPairing(heroId, heroName, themeColor);
    }
  }

  void _navigateToPairing(String childId, String childName, Color themeColor) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ParentPairingScreen(
          childId: childId,
          childName: childName,
          themeColor: themeColor,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF050914).withOpacity(0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            border: Border(
                top: BorderSide(
                    color: Colors.cyanAccent.withOpacity(0.3), width: 1.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 24),
              const Text("Hangi Kahramanı Bağlıyoruz?",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 24),
              StreamBuilder<QuerySnapshot>(
                stream: _heroesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                            color: Colors.cyanAccent));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text("Önce bir kahraman eklemelisin.",
                            style: TextStyle(color: Colors.white70)));
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final bool isPaired = data['isPaired'] ?? false;
                      final String heroName = data['name'] ?? 'İsimsiz';
                      final Color tColor = Color(int.parse(
                          data['colorTheme'] ?? 'ff00e5ff',
                          radix: 16));

                      return GestureDetector(
                        onTap: () => _handleHeroSelection(
                            doc.id, heroName, tColor, isPaired),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                      backgroundColor: tColor.withOpacity(0.2),
                                      child: Icon(Icons.person, color: tColor)),
                                  const SizedBox(width: 16),
                                  Text(heroName,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              isPaired
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: const Color(0xFF00E676)
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      child: const Text("Bağlı",
                                          style: TextStyle(
                                              color: Color(0xFF00E676),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12)),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                          color: Colors.cyanAccent
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color: Colors.cyanAccent)),
                                      child: const Text("Eşleştir",
                                          style: TextStyle(
                                              color: Colors.cyanAccent,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 12)),
                                    ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class ParentPairingScreen extends StatefulWidget {
  final String childId;
  final String childName;
  final Color themeColor;

  const ParentPairingScreen({
    super.key,
    required this.childId,
    required this.childName,
    required this.themeColor,
  });

  @override
  State<ParentPairingScreen> createState() => _ParentPairingScreenState();
}

class _ParentPairingScreenState extends State<ParentPairingScreen>
    with TickerProviderStateMixin {
  String _pairingCode = "";

  bool _isLoading = true;
  bool _isSuccess = false;
  bool _isExpired = false;

  static const int _timeoutSeconds = 180;
  int _secondsLeft = _timeoutSeconds;
  Timer? _timer;
  StreamSubscription<DocumentSnapshot>? _dbSubscription;

  late AnimationController _glowController;
  late AnimationController _successController;
  late Animation<double> _successScale;

  @override
  void initState() {
    super.initState();
    _glowController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _successController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _successScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _successController, curve: Curves.elasticOut));

    _startPairingProcess();
  }

  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    String randomPart = String.fromCharCodes(Iterable.generate(
        4, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
    return 'HRHB-$randomPart';
  }

  Future<void> _startPairingProcess() async {
    setState(() {
      _isLoading = true;
      _isExpired = false;
      _isSuccess = false;
      _secondsLeft = _timeoutSeconds;
      _pairingCode = _generateRandomCode();
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Oturum hatası");

      await FirebaseFirestore.instance
          .collection('pairing_codes')
          .doc(_pairingCode)
          .set({
        'code': _pairingCode,
        'parent_uid': user.uid,
        'child_id': widget.childId,
        'expires_at': FieldValue.serverTimestamp(),
        'is_paired': false,
      });

      if (!mounted) return;
      setState(() => _isLoading = false);

      _startTimer();

      _dbSubscription = FirebaseFirestore.instance
          .collection('pairing_codes')
          .doc(_pairingCode)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          if (data['is_paired'] == true) {
            _handleSuccess();
          }
        }
      });
    } catch (e) {
      showGlassToast(context, "Kod üretilemedi: $e", isError: true);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        _handleTimeout();
      }
    });
  }

  Future<void> _handleSuccess() async {
    _timer?.cancel();
    _dbSubscription?.cancel();

    setState(() {
      _isSuccess = true;
    });
    _successController.forward();

    try {
      await FirebaseFirestore.instance
          .collection('parents')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('children')
          .doc(widget.childId)
          .update({'isPaired': true});

      await FirebaseFirestore.instance
          .collection('pairing_codes')
          .doc(_pairingCode)
          .delete();

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      debugPrint("Başarı sonrası temizlik hatası: $e");
    }
  }

  Future<void> _handleTimeout() async {
    _timer?.cancel();
    _dbSubscription?.cancel();
    setState(() {
      _isExpired = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('pairing_codes')
          .doc(_pairingCode)
          .delete();
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _dbSubscription?.cancel();
    _glowController.dispose();
    _successController.dispose();

    if (!_isSuccess && _pairingCode.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('pairing_codes')
          .doc(_pairingCode)
          .delete()
          .catchError((_) {});
    }
    super.dispose();
  }

  String get _formattedTime {
    int m = _secondsLeft ~/ 60;
    int s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF050914),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          const AnimatedMeshBackground(),
          Container(color: const Color(0xFF050914).withOpacity(0.85)),
          SafeArea(
            child: Center(
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.cyanAccent)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("CİHAZ EŞLEŞTİRME",
                            style: TextStyle(
                                color: widget.themeColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2)),
                        const SizedBox(height: 8),
                        Text(widget.childName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 40),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 260,
                              height: 260,
                              child: CircularProgressIndicator(
                                value: _secondsLeft / _timeoutSeconds,
                                strokeWidth: 4,
                                backgroundColor: Colors.white.withOpacity(0.05),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    _isExpired
                                        ? const Color(0xFFFF1744)
                                        : widget.themeColor),
                              ),
                            ),
                            Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.themeColor.withOpacity(0.1),
                                boxShadow: [
                                  BoxShadow(
                                      color: widget.themeColor.withOpacity(0.2),
                                      blurRadius: 40,
                                      spreadRadius: 10)
                                ],
                              ),
                            ),
                            _buildCenterContent(),
                          ],
                        ),
                        const SizedBox(height: 30),
                        Text(
                          _isExpired
                              ? "Süre Doldu!"
                              : _isSuccess
                                  ? "Eşleşti!"
                                  : _formattedTime,
                          style: TextStyle(
                            color: _isExpired
                                ? const Color(0xFFFF1744)
                                : (_isSuccess
                                    ? const Color(0xFF00E676)
                                    : Colors.white),
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 40),
                        if (_isExpired)
                          GestureDetector(
                            onTap: _startPairingProcess,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 16),
                              decoration: BoxDecoration(
                                color: widget.themeColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: widget.themeColor),
                              ),
                              child: const Text("KODU YENİLE",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5)),
                            ),
                          )
                        else if (!_isSuccess)
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 40.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.1)),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text("VEYA TABLETE BU KODU GİRİN",
                                          style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1)),
                                      const SizedBox(height: 12),
                                      Text(
                                        _pairingCode,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 32,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 5),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterContent() {
    if (_isSuccess) {
      return ScaleTransition(
        scale: _successScale,
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: const Color(0xFF00E676).withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF00E676), width: 4),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF00E676).withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 10)
            ],
          ),
          child: const Icon(Icons.check_rounded,
              color: Color(0xFF00E676), size: 80),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: _isExpired
                ? []
                : [
                    BoxShadow(
                        color: widget.themeColor
                            .withOpacity(0.3 + (_glowController.value * 0.3)),
                        blurRadius: 20,
                        spreadRadius: 5)
                  ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              QrImageView(
                data: _pairingCode,
                version: QrVersions.auto,
                size: 160.0,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square, color: Color(0xFF050914)),
                dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF050914)),
              ),
              if (_isExpired)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      width: 160,
                      height: 160,
                      color: Colors.white.withOpacity(0.5),
                      child: const Center(
                        child: Icon(Icons.timer_off_rounded,
                            color: Color(0xFFFF1744), size: 60),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
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
