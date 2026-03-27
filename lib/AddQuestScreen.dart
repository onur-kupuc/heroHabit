import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:super_habit/glass_toast.dart';

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

class AddQuestScreen extends StatefulWidget {
  const AddQuestScreen({super.key});

  @override
  State<AddQuestScreen> createState() => _AddQuestScreenState();
}

class _AddQuestScreenState extends State<AddQuestScreen>
    with TickerProviderStateMixin {
  late Stream<QuerySnapshot> _heroesStream;

  int _selectedHeroIndex = 0;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String _selectedFrequency = "Her Gün";
  final List<String> _frequencies = [
    "Her Gün",
    "Hafta İçi",
    "Hafta Sonu",
    "Belirli Günler"
  ];

  DateTime _currentMonthView =
      DateTime(DateTime.now().year, DateTime.now().month);
  List<DateTime> _selectedCustomDates = [];

  TimeOfDay? _deadlineTime;
  double _xpPoints = 50.0;
  bool _requirePhotoProof = false;
  bool _isLoading = false;

  late AnimationController _staggeredController;
  late AnimationController _pulseEdgeController;

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
        vsync: this, duration: const Duration(milliseconds: 2200));

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

    _pulseEdgeController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);

    _staggeredController.forward();
  }

  @override
  void dispose() {
    _staggeredController.dispose();
    _pulseEdgeController.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context, Color themeColor) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _deadlineTime ?? const TimeOfDay(hour: 20, minute: 0),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: themeColor,
              surface: const Color(0xFF121B2B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _deadlineTime = picked);
    }
  }

  Future<void> _saveQuestToFirestore(HeroModel selectedHero) async {
    FocusScope.of(context).unfocus();
    final String title = _titleController.text.trim();

    if (title.isEmpty) {
      showGlassToast(context, "Lütfen göreve bir isim verin!", isError: true);
      return;
    }

    if (_selectedFrequency == "Belirli Günler" &&
        _selectedCustomDates.isEmpty) {
      showGlassToast(context, "Lütfen takvimden en az bir tarih seçin!",
          isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Oturum bulunamadı!");

      String? formattedTime;
      if (_deadlineTime != null) {
        final String hour = _deadlineTime!.hour.toString().padLeft(2, '0');
        final String minute = _deadlineTime!.minute.toString().padLeft(2, '0');
        formattedTime = "$hour:$minute";
      }

      List<String> formattedDates = _selectedCustomDates.map((d) {
        return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
      }).toList();

      await FirebaseFirestore.instance
          .collection('parents')
          .doc(user.uid)
          .collection('children')
          .doc(selectedHero.id)
          .collection('quests')
          .add({
        'title': title,
        'description': _descController.text.trim(),
        'frequency': _selectedFrequency,
        'customDates':
            _selectedFrequency == "Belirli Günler" ? formattedDates : [],
        'deadline': formattedTime,
        'xpReward': _xpPoints.toInt(),
        'requirePhotoProof': _requirePhotoProof,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      showGlassToast(context, "Görev başarıyla eklendi!", isError: false);

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      showGlassToast(context, "Bir hata oluştu: ${e.toString()}",
          isError: true);
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
          title: const Text("Yeni Görev",
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: Colors.white)),
          centerTitle: true,
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _heroesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text("Görev atamak için önce bir kahraman eklemelisin.",
                    style: TextStyle(color: Colors.white)));
          }

          List<HeroModel> heroes = snapshot.data!.docs
              .map((doc) => HeroModel.fromFirestore(doc))
              .toList();
          if (_selectedHeroIndex >= heroes.length) _selectedHeroIndex = 0;
          final activeColor = heroes[_selectedHeroIndex].themeColor;

          return Stack(
            children: [
              AnimatedBuilder(
                animation: _pulseEdgeController,
                builder: (context, child) {
                  final double pulse = _pulseEdgeController.value;
                  return Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: activeColor.withOpacity(0.1 + (pulse * 0.15)),
                          blurRadius: 100 + (pulse * 50),
                          spreadRadius: -20,
                          blurStyle: BlurStyle.normal,
                        )
                      ],
                    ),
                  );
                },
              ),
              Opacity(
                opacity: 0.3,
                child: Image.asset("assets/images/noise.png",
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (c, e, s) => const SizedBox()),
              ),
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                          position: _headerSlide,
                          child: _buildHeroSelector(heroes)),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 600),
                        switchInCurve: Curves.easeOutBack,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                                scale: Tween<double>(begin: 0.95, end: 1.0)
                                    .animate(animation),
                                child: child),
                          );
                        },
                        child: _buildScrollableForm(heroes[_selectedHeroIndex],
                            key: ValueKey(heroes[_selectedHeroIndex].id)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
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
                      child: ClipOval(
                        child: _buildSmartImage(hero.avatarUrl),
                      ),
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

  Widget _buildScrollableForm(HeroModel selectedHero, {required Key key}) {
    final activeColor = selectedHero.themeColor;

    return SingleChildScrollView(
      key: key,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 40, top: 10),
      child: Column(
        children: [
          SlideTransition(
            position: _card1Slide,
            child: VisionGlassCard(
              glowColor: activeColor,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.2), width: 1.5),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_rounded,
                              color: activeColor, size: 32),
                          const SizedBox(height: 4),
                          Text("İsteğe Bağlı",
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _titleController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2),
                    decoration: InputDecoration(
                      hintText: "Görev Adı",
                      hintStyle:
                          TextStyle(color: Colors.white.withOpacity(0.3)),
                      border: InputBorder.none,
                    ),
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
                      hintText: "Görev Açıklaması (İsteğe Bağlı)",
                      hintStyle:
                          TextStyle(color: Colors.white.withOpacity(0.3)),
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SlideTransition(
            position: _card2Slide,
            child: VisionGlassCard(
              glowColor: activeColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("GÖREV SIKLIĞI",
                      style: TextStyle(
                          color: activeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _frequencies.map((freq) {
                        bool isSel = _selectedFrequency == freq;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedFrequency = freq),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? activeColor.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: isSel
                                      ? activeColor
                                      : Colors.white.withOpacity(0.2)),
                            ),
                            child: Text(freq,
                                style: TextStyle(
                                    color:
                                        isSel ? Colors.white : Colors.white70,
                                    fontWeight: FontWeight.bold)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOutBack,
                    child: _selectedFrequency == "Belirli Günler"
                        ? Container(
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(16),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                          Icons.chevron_left_rounded,
                                          color: Colors.white),
                                      onPressed: () => setState(() {
                                        _currentMonthView = DateTime(
                                            _currentMonthView.year,
                                            _currentMonthView.month - 1);
                                      }),
                                    ),
                                    Text(
                                      _getMonthName(_currentMonthView.month) +
                                          " " +
                                          _currentMonthView.year.toString(),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                          Icons.chevron_right_rounded,
                                          color: Colors.white),
                                      onPressed: () => setState(() {
                                        _currentMonthView = DateTime(
                                            _currentMonthView.year,
                                            _currentMonthView.month + 1);
                                      }),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    "Pzt",
                                    "Sal",
                                    "Çar",
                                    "Per",
                                    "Cum",
                                    "Cmt",
                                    "Paz"
                                  ].map((day) {
                                    return SizedBox(
                                      width: 30,
                                      child: Center(
                                          child: Text(day,
                                              style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.4),
                                                  fontSize: 12,
                                                  fontWeight:
                                                      FontWeight.bold))),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 10),
                                _buildCalendarGrid(activeColor),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),
                  Divider(color: Colors.white.withOpacity(0.1)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("BİTİŞ SAATİ",
                          style: TextStyle(
                              color: activeColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5)),
                      GestureDetector(
                        onTap: () => _selectTime(context, activeColor),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(CupertinoIcons.clock,
                                  color: activeColor, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                _deadlineTime != null
                                    ? _deadlineTime!.format(context)
                                    : "Saat Seç",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SlideTransition(
            position: _card3Slide,
            child: VisionGlassCard(
              glowColor: _requirePhotoProof ? activeColor : Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("XP ÖDÜLÜ",
                          style: TextStyle(
                              color: activeColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC400).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFFFFC400).withOpacity(0.5)),
                        ),
                        child: Text("${_xpPoints.toInt()} XP",
                            style: const TextStyle(
                                color: Color(0xFFFFC400),
                                fontWeight: FontWeight.w900)),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: const Color(0xFFFFC400),
                      inactiveTrackColor: Colors.white.withOpacity(0.1),
                      thumbColor: Colors.white,
                      overlayColor: const Color(0xFFFFC400).withOpacity(0.2),
                      trackHeight: 6,
                    ),
                    child: Slider(
                      value: _xpPoints,
                      min: 10,
                      max: 200,
                      divisions: 19,
                      onChanged: (val) => setState(() => _xpPoints = val),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(color: Colors.white.withOpacity(0.1)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.camera_alt_rounded,
                              color: Colors.white.withOpacity(0.6), size: 20),
                          const SizedBox(width: 8),
                          const Text("Fotoğraflı Kanıt Zorunlu",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      CupertinoSwitch(
                        value: _requirePhotoProof,
                        activeColor: activeColor,
                        onChanged: (val) =>
                            setState(() => _requirePhotoProof = val),
                      ),
                    ],
                  )
                ],
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

  String _getMonthName(int month) {
    const months = [
      "Ocak",
      "Şubat",
      "Mart",
      "Nisan",
      "Mayıs",
      "Haziran",
      "Temmuz",
      "Ağustos",
      "Eylül",
      "Ekim",
      "Kasım",
      "Aralık"
    ];
    return months[month - 1];
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Widget _buildCalendarGrid(Color activeColor) {
    int daysInMonth =
        DateTime(_currentMonthView.year, _currentMonthView.month + 1, 0).day;
    int firstWeekday =
        DateTime(_currentMonthView.year, _currentMonthView.month, 1).weekday;

    int totalCells = daysInMonth + firstWeekday - 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        if (index < firstWeekday - 1) {
          return const SizedBox.shrink();
        }

        int day = index - (firstWeekday - 1) + 1;
        DateTime cellDate =
            DateTime(_currentMonthView.year, _currentMonthView.month, day);

        bool isSelected =
            _selectedCustomDates.any((d) => _isSameDay(d, cellDate));
        bool isToday = _isSameDay(cellDate, DateTime.now());

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedCustomDates
                    .removeWhere((d) => _isSameDay(d, cellDate));
              } else {
                _selectedCustomDates.add(cellDate);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? activeColor.withOpacity(0.8)
                  : Colors.white.withOpacity(0.05),
              border: Border.all(
                color: isSelected
                    ? Colors.white
                    : (isToday ? activeColor : Colors.white.withOpacity(0.1)),
                width: isSelected ? 1.5 : (isToday ? 1.0 : 0.5),
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: activeColor.withOpacity(0.6), blurRadius: 10)
                    ]
                  : [],
            ),
            child: Center(
              child: Text(
                "$day",
                style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isToday ? activeColor : Colors.white70),
                    fontWeight: isSelected || isToday
                        ? FontWeight.w900
                        : FontWeight.w500,
                    fontSize: 13),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLiquidActionButton(HeroModel hero) {
    return GestureDetector(
      onTapDown: (_) => setState(() {}),
      onTap: () => _isLoading ? null : _saveQuestToFirestore(hero),
      child: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: 65,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: [hero.themeColor, hero.themeColor.withOpacity(0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                  color: hero.themeColor.withOpacity(0.4),
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
                : const Text("GÖREVİ BAŞLAT",
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
              width: 1,
            ),
            boxShadow: glowColor != Colors.transparent
                ? [
                    BoxShadow(
                        color: glowColor.withOpacity(0.1),
                        blurRadius: 30,
                        spreadRadius: 2)
                  ]
                : [],
          ),
          child: child,
        ),
      ),
    );
  }
}
