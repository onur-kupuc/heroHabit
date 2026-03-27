import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'glass_toast.dart';

class HeroModel {
  final String id;
  final String name;
  final String avatarUrl;
  final Color themeColor;

  HeroModel(
      {required this.id,
      required this.name,
      required this.avatarUrl,
      required this.themeColor});

  factory HeroModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return HeroModel(
      id: doc.id,
      name: data['name'] ?? 'Kahraman',
      avatarUrl: data['avatarUrl'] ?? 'assets/images/1.png',
      themeColor: Color(int.parse(data['colorTheme'] ?? 'ff00e5ff', radix: 16)),
    );
  }
}

class AddRewardScreen extends StatefulWidget {
  const AddRewardScreen({super.key});

  @override
  State<AddRewardScreen> createState() => _AddRewardScreenState();
}

class _AddRewardScreenState extends State<AddRewardScreen>
    with TickerProviderStateMixin {
  late Stream<QuerySnapshot> _heroesStream;

  int _selectedHeroIndex = 0;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _customStockController = TextEditingController();

  double _xpCost = 500.0;

  final List<IconData> _rewardIcons = [
    Icons.card_giftcard_rounded,
    Icons.videogame_asset_rounded,
    Icons.fastfood_rounded,
    Icons.movie_filter_rounded,
    Icons.monetization_on_rounded,
    Icons.pedal_bike_rounded,
    Icons.devices_rounded,
  ];
  int _selectedIconIndex = 0;

  String _selectedStock = "Sınırsız";
  final List<String> _stockOptions = [
    "Sınırsız",
    "Sadece 1 Kez",
    "Günde 1 Kez",
    "Özel Limit"
  ];

  bool _isMysteryBox = false;
  bool _isLoading = false;

  late AnimationController _staggeredController;
  late AnimationController _bgPulseController;

  late Animation<Offset> _headerSlide,
      _card1Slide,
      _card2Slide,
      _card3Slide,
      _btnSlide;
  late Animation<double> _fadeAnim;

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

    _staggeredController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400));

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _staggeredController, curve: const Interval(0.0, 0.4)));
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _staggeredController,
            curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic)));
    _card1Slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _staggeredController,
            curve: const Interval(0.2, 0.6, curve: Curves.easeOutBack)));
    _card2Slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _staggeredController,
            curve: const Interval(0.3, 0.7, curve: Curves.easeOutBack)));
    _card3Slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _staggeredController,
            curve: const Interval(0.4, 0.8, curve: Curves.easeOutBack)));
    _btnSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _staggeredController,
            curve: const Interval(0.5, 1.0, curve: Curves.elasticOut)));

    _bgPulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat(reverse: true);

    _staggeredController.forward();
  }

  @override
  void dispose() {
    _staggeredController.dispose();
    _bgPulseController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _customStockController.dispose();
    super.dispose();
  }

  Future<void> _saveRewardToFirestore(HeroModel hero) async {
    FocusScope.of(context).unfocus();

    final String title = _titleController.text.trim();
    if (title.isEmpty) {
      showGlassToast(context, "Lütfen ödüle bir isim verin!", isError: true);
      return;
    }

    int stockCount = -1;
    if (_selectedStock == "Sadece 1 Kez" || _selectedStock == "Günde 1 Kez") {
      stockCount = 1;
    } else if (_selectedStock == "Özel Limit") {
      if (_customStockController.text.trim().isEmpty) {
        showGlassToast(context, "Lütfen özel stok miktarını girin!",
            isError: true);
        return;
      }
      stockCount = int.tryParse(_customStockController.text) ?? 1;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Oturum bulunamadı!");

      await FirebaseFirestore.instance
          .collection('parents')
          .doc(user.uid)
          .collection('children')
          .doc(hero.id)
          .collection('rewards')
          .add({
        'title': title,
        'description': _descController.text.trim(),
        'xpCost': _xpCost.toInt(),
        'stockType': _selectedStock,
        'stockCount': stockCount,
        'isMysteryBox': _isMysteryBox,
        'iconCode': _rewardIcons[_selectedIconIndex].codePoint,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      showGlassToast(context, "Ödül başarıyla eklendi!", isError: false);

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      showGlassToast(context, "Hata: ${e.toString()}", isError: true);
      setState(() => _isLoading = false);
    }
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
          title: const Text("Sihirli Ödül Yarat",
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: Colors.white)),
          centerTitle: true,
        ),
      ),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bgPulseController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: -100,
                    left: -100,
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF9C27B0).withOpacity(
                              0.15 + (_bgPulseController.value * 0.1)),
                          backgroundBlendMode: BlendMode.screen),
                      child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                          child: const SizedBox()),
                    ),
                  ),
                  Positioned(
                    bottom: -50,
                    right: -50,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFC400).withOpacity(
                              0.1 + (_bgPulseController.value * 0.1)),
                          backgroundBlendMode: BlendMode.screen),
                      child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                          child: const SizedBox()),
                    ),
                  ),
                ],
              );
            },
          ),
          Opacity(
              opacity: 0.2,
              child: Image.asset("assets/images/noise.png",
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (c, e, s) => const SizedBox())),
          StreamBuilder<QuerySnapshot>(
            stream: _heroesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFFC400)));

              List<HeroModel> heroes = snapshot.hasData
                  ? snapshot.data!.docs
                      .map((doc) => HeroModel.fromFirestore(doc))
                      .toList()
                  : [];
              if (_selectedHeroIndex >= heroes.length && heroes.isNotEmpty)
                _selectedHeroIndex = 0;

              return SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                            position: _headerSlide,
                            child: _buildHeroSelector(heroes))),
                    const SizedBox(height: 10),
                    Expanded(
                      child: heroes.isEmpty
                          ? const Center(
                              child: Text("Önce kahraman eklemelisin.",
                                  style: TextStyle(color: Colors.white)))
                          : AnimatedSwitcher(
                              duration: const Duration(milliseconds: 600),
                              child: _buildScrollableForm(
                                  heroes[_selectedHeroIndex],
                                  key: ValueKey(heroes[_selectedHeroIndex].id)),
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
            onTap: () {
              FocusScope.of(context).unfocus();
              setState(() => _selectedHeroIndex = index);
            },
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
                              color: isSelected
                                  ? hero.themeColor
                                  : Colors.transparent,
                              width: 3),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                      color: hero.themeColor.withOpacity(0.6),
                                      blurRadius: 20,
                                      spreadRadius: 2)
                                ]
                              : []),
                      child: ClipOval(child: _buildSmartImage(hero.avatarUrl)),
                    ),
                    const SizedBox(height: 8),
                    Text(hero.name,
                        style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected
                                ? FontWeight.w900
                                : FontWeight.normal,
                            fontSize: 13)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScrollableForm(HeroModel selectedHero, {required Key key}) {
    return SingleChildScrollView(
      key: key,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 40, top: 10),
      child: Column(
        children: [
          SlideTransition(
            position: _card1Slide,
            child: VisionGlassCard(
              glowColor: selectedHero.themeColor,
              child: Column(
                children: [
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _rewardIcons.length,
                      itemBuilder: (context, index) {
                        bool isSel = _selectedIconIndex == index;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedIconIndex = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 12),
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: isSel
                                  ? selectedHero.themeColor.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.05),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: isSel
                                      ? selectedHero.themeColor
                                      : Colors.transparent,
                                  width: 2),
                              boxShadow: isSel
                                  ? [
                                      BoxShadow(
                                          color: selectedHero.themeColor
                                              .withOpacity(0.5),
                                          blurRadius: 15)
                                    ]
                                  : [],
                            ),
                            child: Center(
                                child: Icon(_rewardIcons[index],
                                    color: isSel
                                        ? selectedHero.themeColor
                                        : Colors.white54,
                                    size: 28)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _titleController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2),
                    decoration: InputDecoration(
                        hintText: "Ödül Adı (Örn: Sinema)",
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.3)),
                        border: InputBorder.none),
                  ),
                  Divider(color: Colors.white.withOpacity(0.1)),
                  TextField(
                    controller: _descController,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                        hintText: "Bu ödül ne işe yarıyor? (İsteğe Bağlı)",
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.3)),
                        border: InputBorder.none),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SlideTransition(
            position: _card2Slide,
            child: VisionGlassCard(
              glowColor: const Color(0xFFFFC400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text("ÖDÜLÜN DEĞERİ",
                      style: TextStyle(
                          color: const Color(0xFFFFC400).withOpacity(0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2)),
                  const SizedBox(height: 10),
                  Text(
                    "${_xpCost.toInt()} XP",
                    style: const TextStyle(
                        color: Color(0xFFFFC400),
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(color: Color(0xFFFFC400), blurRadius: 20)
                        ]),
                  ),
                  const SizedBox(height: 16),
                  SliderTheme(
                    data: SliderThemeData(
                        activeTrackColor: const Color(0xFFFFC400),
                        inactiveTrackColor: Colors.white.withOpacity(0.1),
                        thumbColor: Colors.white,
                        overlayColor: const Color(0xFFFFC400).withOpacity(0.2),
                        trackHeight: 8,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 12)),
                    child: Slider(
                        value: _xpCost,
                        min: 50,
                        max: 5000,
                        divisions: 99,
                        onChanged: (val) => setState(() => _xpCost = val)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SlideTransition(
            position: _card3Slide,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: _isMysteryBox
                    ? const Color(0xFF9C27B0).withOpacity(0.15)
                    : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                    color: _isMysteryBox
                        ? const Color(0xFF9C27B0).withOpacity(0.6)
                        : Colors.white.withOpacity(0.15),
                    width: 1.5),
                boxShadow: _isMysteryBox
                    ? [
                        BoxShadow(
                            color: const Color(0xFF9C27B0).withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 2)
                      ]
                    : [const BoxShadow(color: Colors.black12, blurRadius: 20)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("STOK LİMİTİ",
                            style: TextStyle(
                                color: _isMysteryBox
                                    ? const Color(0xFFE1BEE7)
                                    : Colors.white54,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5)),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _stockOptions.map((opt) {
                            bool isSel = _selectedStock == opt;
                            return GestureDetector(
                              onTap: () => setState(() {
                                _selectedStock = opt;
                                if (opt != "Özel Limit")
                                  _customStockController.clear();
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? (_isMysteryBox
                                          ? const Color(0xFF9C27B0)
                                          : selectedHero.themeColor)
                                      : Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: isSel
                                          ? Colors.transparent
                                          : Colors.white.withOpacity(0.2)),
                                  boxShadow: isSel
                                      ? [
                                          BoxShadow(
                                              color: (_isMysteryBox
                                                      ? const Color(0xFF9C27B0)
                                                      : selectedHero.themeColor)
                                                  .withOpacity(0.5),
                                              blurRadius: 10)
                                        ]
                                      : [],
                                ),
                                child: Text(opt,
                                    style: TextStyle(
                                        color: isSel
                                            ? Colors.white
                                            : Colors.white70,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)),
                              ),
                            );
                          }).toList(),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutBack,
                          child: _selectedStock == "Özel Limit"
                              ? Container(
                                  margin: const EdgeInsets.only(top: 16),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: selectedHero.themeColor
                                            .withOpacity(0.5)),
                                  ),
                                  child: TextField(
                                    controller: _customStockController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                    decoration: InputDecoration(
                                      icon: Icon(Icons.inventory_2_rounded,
                                          color: selectedHero.themeColor),
                                      hintText: "Miktar girin (Örn: 5)",
                                      hintStyle: TextStyle(
                                          color: Colors.white.withOpacity(0.3)),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 24),
                        Divider(color: Colors.white.withOpacity(0.1)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.auto_awesome_rounded,
                                          color: _isMysteryBox
                                              ? const Color(0xFFE040FB)
                                              : Colors.white54,
                                          size: 20),
                                      const SizedBox(width: 8),
                                      Text("Gizemli Sandık",
                                          style: TextStyle(
                                              color: _isMysteryBox
                                                  ? Colors.white
                                                  : Colors.white70,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                      "Çocuk alana kadar ödülün ne olduğunu göremez (Sürpriz Kutu).",
                                      style: TextStyle(
                                          color: Colors.white.withOpacity(0.5),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            CupertinoSwitch(
                              value: _isMysteryBox,
                              activeColor: const Color(0xFFD500F9),
                              onChanged: (val) =>
                                  setState(() => _isMysteryBox = val),
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
          const SizedBox(height: 35),
          SlideTransition(
            position: _btnSlide,
            child: _buildLiquidActionButton(selectedHero),
          ),
        ],
      ),
    );
  }

  Widget _buildLiquidActionButton(HeroModel hero) {
    return GestureDetector(
      onTapDown: (_) => setState(() {}),
      onTap: () => _isLoading ? null : _saveRewardToFirestore(hero),
      child: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: 65,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
                colors: [Color(0xFFFFB300), Color(0xFFFF6D00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFFFF6D00).withOpacity(0.5),
                  blurRadius: 25,
                  offset: const Offset(0, 8)),
              BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 5,
                  offset: const Offset(0, -2))
            ],
          ),
          child: Center(
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("ÖDÜLÜ YARAT",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2)),
          ),
        ),
      ),
    );
  }

  Widget _buildSmartImage(String url) {
    if (url.startsWith('http')) {
      return Image.network(url,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) =>
              const Icon(Icons.person, color: Colors.white));
    } else {
      return Image.asset(url,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => const Icon(
              Icons.face_retouching_natural_rounded,
              color: Colors.white54,
              size: 30));
    }
  }
}

class VisionGlassCard extends StatelessWidget {
  final Widget child;
  final Color glowColor;

  const VisionGlassCard(
      {super.key, required this.child, this.glowColor = Colors.transparent});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
                color: glowColor != Colors.transparent
                    ? glowColor.withOpacity(0.5)
                    : Colors.white.withOpacity(0.15),
                width: 1.5),
            boxShadow: glowColor != Colors.transparent
                ? [
                    BoxShadow(
                        color: glowColor.withOpacity(0.15),
                        blurRadius: 30,
                        spreadRadius: 2)
                  ]
                : [const BoxShadow(color: Colors.black12, blurRadius: 20)],
          ),
          child: child,
        ),
      ),
    );
  }
}
