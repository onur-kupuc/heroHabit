import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'glass_toast.dart';

class HeroModel {
  final String id;
  final String name;
  final String avatarUrl;
  final Color themeColor;

  HeroModel({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.themeColor,
  });

  factory HeroModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String colorHex = data['colorTheme'] ?? 'ff00e5ff';
    Color parsedColor = Color(int.parse(colorHex, radix: 16));

    return HeroModel(
      id: doc.id,
      name: data['name'] ?? 'İsimsiz Kahraman',
      avatarUrl: data['avatarUrl'] ?? 'assets/images/1.png',
      themeColor: parsedColor,
    );
  }
}

class RemoveQuestScreen extends StatefulWidget {
  const RemoveQuestScreen({super.key});

  @override
  State<RemoveQuestScreen> createState() => _RemoveQuestScreenState();
}

class _RemoveQuestScreenState extends State<RemoveQuestScreen>
    with TickerProviderStateMixin {
  late Stream<QuerySnapshot> _heroesStream;

  int _selectedHeroIndex = 0;

  late AnimationController _headerAnimController;
  late AnimationController _listAnimController;
  late Animation<Offset> _headerSlide;
  late Animation<double> _headerFade;

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

    _headerAnimController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));

    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _headerAnimController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));

    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _headerAnimController,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic)));

    _listAnimController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));

    _headerAnimController.forward();
    _listAnimController.forward();
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    _listAnimController.dispose();
    super.dispose();
  }

  void _onHeroChanged(int index) {
    if (_selectedHeroIndex != index) {
      setState(() => _selectedHeroIndex = index);
      _listAnimController.forward(from: 0.0);
    }
  }

  Future<void> _deleteQuest(String heroId, String questId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('parents')
          .doc(user.uid)
          .collection('children')
          .doc(heroId)
          .collection('quests')
          .doc(questId)
          .delete();

      if (!mounted) return;
      showGlassToast(context, "Görev başarıyla silindi!", isError: false);
    } catch (e) {
      showGlassToast(context, "Bir hata oluştu: ${e.toString()}",
          isError: true);
    }
  }

  void _showDeleteConfirmationDialog(
      String heroId, String questId, String questTitle, Color themeColor) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = Curves.easeOutBack.transform(anim1.value);
        return Transform.scale(
          scale: curve,
          child: Opacity(
            opacity: anim1.value,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withOpacity(0.7),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                          color: const Color(0xFFFF1744).withOpacity(0.5),
                          width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF1744).withOpacity(0.2),
                          blurRadius: 40,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF1744).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.delete_forever_rounded,
                              color: Color(0xFFFF1744), size: 40),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Görevi Sil",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 12),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                                height: 1.5),
                            children: [
                              TextSpan(
                                  text: '"$questTitle"',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                              const TextSpan(
                                  text:
                                      " adlı görevi kalıcı olarak silmek istediğine emin misin? Bu işlem geri alınamaz."),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Center(
                                    child: Text("İptal",
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  _deleteQuest(heroId, questId);
                                },
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFF5252),
                                        Color(0xFFFF1744)
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                          color: const Color(0xFFFF1744)
                                              .withOpacity(0.4),
                                          blurRadius: 15,
                                          offset: const Offset(0, 4)),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Text("Evet, Sil",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text("Görevleri Yönet",
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: Colors.white)),
          centerTitle: true,
        ),
      ),
      body: Stack(
        children: [
          const AnimatedMeshBackground(),
          Container(color: const Color(0xFF050914).withOpacity(0.85)),
          StreamBuilder<QuerySnapshot>(
            stream: _heroesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.cyanAccent));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text("Yönetilecek bir kahraman bulunamadı.",
                      style: TextStyle(color: Colors.white70)),
                );
              }

              List<HeroModel> heroes = snapshot.data!.docs
                  .map((doc) => HeroModel.fromFirestore(doc))
                  .toList();
              if (_selectedHeroIndex >= heroes.length) _selectedHeroIndex = 0;
              final selectedHero = heroes[_selectedHeroIndex];

              return SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    FadeTransition(
                      opacity: _headerFade,
                      child: SlideTransition(
                        position: _headerSlide,
                        child: _buildHeroSelector(heroes),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('parents')
                            .doc(FirebaseAuth.instance.currentUser!.uid)
                            .collection('children')
                            .doc(selectedHero.id)
                            .collection('quests')
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, questSnapshot) {
                          if (questSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                                child: CircularProgressIndicator(
                                    color: selectedHero.themeColor));
                          }

                          final quests = questSnapshot.data?.docs ?? [];

                          if (quests.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inventory_2_outlined,
                                      color: selectedHero.themeColor
                                          .withOpacity(0.5),
                                      size: 60),
                                  const SizedBox(height: 16),
                                  Text(
                                      "${selectedHero.name} için atanmış görev yok.",
                                      style: TextStyle(
                                          color: Colors.white.withOpacity(0.6),
                                          fontSize: 16)),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(
                                left: 20, right: 20, bottom: 40, top: 10),
                            itemCount: quests.length,
                            itemBuilder: (context, index) {
                              final questDoc = quests[index];
                              final questData =
                                  questDoc.data() as Map<String, dynamic>;

                              final double start =
                                  (index * 0.1).clamp(0.0, 0.8);
                              final double end = (start + 0.2).clamp(0.0, 1.0);

                              Animation<double> itemFade = CurvedAnimation(
                                parent: _listAnimController,
                                curve:
                                    Interval(start, end, curve: Curves.easeOut),
                              );
                              Animation<Offset> itemSlide = Tween<Offset>(
                                      begin: const Offset(0, 0.3),
                                      end: Offset.zero)
                                  .animate(
                                CurvedAnimation(
                                    parent: _listAnimController,
                                    curve: Interval(start, end,
                                        curve: Curves.easeOutBack)),
                              );

                              return FadeTransition(
                                opacity: itemFade,
                                child: SlideTransition(
                                  position: itemSlide,
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 16.0),
                                    child: _buildDeletableQuestCard(
                                      heroId: selectedHero.id,
                                      questId: questDoc.id,
                                      title:
                                          questData['title'] ?? 'İsimsiz Görev',
                                      xp: questData['xpReward'] ?? 0,
                                      frequency: questData['frequency'] ??
                                          'Belirtilmedi',
                                      themeColor: selectedHero.themeColor,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSelector(List<HeroModel> heroes) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: heroes.length,
        itemBuilder: (context, index) {
          final hero = heroes[index];
          final isSelected = _selectedHeroIndex == index;

          return GestureDetector(
            onTap: () => _onHeroChanged(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.elasticOut,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              transform: Matrix4.identity()..scale(isSelected ? 1.1 : 0.85),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isSelected ? 1.0 : 0.4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 75,
                      height: 75,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                        border: Border.all(
                          color:
                              isSelected ? hero.themeColor : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                    color: hero.themeColor.withOpacity(0.6),
                                    blurRadius: 20,
                                    spreadRadius: 2)
                              ]
                            : [],
                      ),
                      child: ClipOval(child: _buildSmartImage(hero.avatarUrl)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hero.name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight:
                            isSelected ? FontWeight.w900 : FontWeight.normal,
                        fontSize: 13,
                        shadows: isSelected
                            ? [Shadow(color: hero.themeColor, blurRadius: 10)]
                            : [],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDeletableQuestCard({
    required String heroId,
    required String questId,
    required String title,
    required int xp,
    required String frequency,
    required Color themeColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20)],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: themeColor.withOpacity(0.5)),
                ),
                child: Icon(Icons.star_rounded, color: themeColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFC400).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text("$xp XP",
                              style: const TextStyle(
                                  color: Color(0xFFFFC400),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900)),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.loop_rounded,
                            color: Colors.white.withOpacity(0.5), size: 12),
                        const SizedBox(width: 4),
                        Text(frequency,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _showDeleteConfirmationDialog(
                    heroId, questId, title, themeColor),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF1744).withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFFFF1744).withOpacity(0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF1744).withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: -2,
                      )
                    ],
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: Color(0xFFFF1744), size: 24),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmartImage(String url) {
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent));
        },
        errorBuilder: (c, e, s) =>
            const Icon(Icons.person, color: Colors.white),
      );
    } else {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => const Icon(
            Icons.face_retouching_natural_rounded,
            color: Colors.white54,
            size: 30),
      );
    }
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
