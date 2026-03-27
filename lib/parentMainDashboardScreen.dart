import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:super_habit/removeQuestScreen.dart';

import 'addQuestScreen.dart';
import 'settingScreen.dart';
import 'addRewardScreen.dart';

class HeroModel {
  final String id;
  final String name;
  final String avatarUrl;
  final Color themeColor;
  final bool isPaired;

  HeroModel({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.themeColor,
    required this.isPaired,
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
      isPaired: data['isPaired'] ?? false,
    );
  }
}

class ParentMainDashboardScreen extends StatefulWidget {
  final String parentName;

  const ParentMainDashboardScreen({super.key, this.parentName = "Kahraman"});

  @override
  State<ParentMainDashboardScreen> createState() =>
      _ParentMainDashboardScreenState();
}

class _ParentMainDashboardScreenState extends State<ParentMainDashboardScreen>
    with TickerProviderStateMixin {
  late Stream<QuerySnapshot> _heroesStream;

  final ScrollController _timelineScrollController = ScrollController();

  int _selectedHeroIndex = 0;
  int _selectedNavIndex = 2;
  DateTime _selectedTimelineDate = DateTime.now();

  bool _isDarkMode = true;

  Color get primaryText => _isDarkMode ? Colors.white : const Color(0xFF171A21);
  Color get secondaryText => _isDarkMode
      ? Colors.white.withOpacity(0.6)
      : const Color(0xFF171A21).withOpacity(0.6);
  Color get glassBg => _isDarkMode
      ? Colors.white.withOpacity(0.04)
      : Colors.white.withOpacity(0.4);
  Color get glassBorder => _isDarkMode
      ? Colors.white.withOpacity(0.15)
      : Colors.black.withOpacity(0.1);
  Color get navBg => _isDarkMode
      ? Colors.white.withOpacity(0.05)
      : Colors.white.withOpacity(0.5);

  late AnimationController _staggeredController;
  late AnimationController _cyberpunkPulseController;
  late Animation<Offset> _headerSlide;
  late Animation<Offset> _contentSlide;
  late Animation<Offset> _navBarSlide;

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
    _headerSlide = Tween<Offset>(begin: const Offset(0, -1.0), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _staggeredController,
            curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic)));
    _contentSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _staggeredController,
            curve: const Interval(0.2, 0.7, curve: Curves.easeOutBack)));
    _navBarSlide = Tween<Offset>(begin: const Offset(0, 1.5), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _staggeredController,
            curve: const Interval(0.4, 1.0, curve: Curves.elasticOut)));

    _cyberpunkPulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);

    _staggeredController.forward();
  }

  @override
  void dispose() {
    _timelineScrollController.dispose();
    _staggeredController.dispose();
    _cyberpunkPulseController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  String _formatDate(DateTime d) {
    return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          const AnimatedMeshBackground(),
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            color: _isDarkMode
                ? const Color(0xFF050914).withOpacity(0.85)
                : Colors.white.withOpacity(0.7),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _heroesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                    child: CircularProgressIndicator(
                        color: _isDarkMode
                            ? Colors.cyanAccent
                            : const Color(0xFF171A21)));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                    child: Text("Henüz kahraman eklenmemiş.",
                        style: TextStyle(color: primaryText)));
              }

              List<HeroModel> heroes = snapshot.data!.docs
                  .map((doc) => HeroModel.fromFirestore(doc))
                  .toList();

              if (_selectedHeroIndex >= heroes.length) _selectedHeroIndex = 0;
              final activeHero = heroes[_selectedHeroIndex];

              return SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    SlideTransition(
                        position: _headerSlide, child: _buildTopHeader(heroes)),
                    const SizedBox(height: 15),
                    Expanded(
                      child: SlideTransition(
                        position: _contentSlide,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 600),
                            switchInCurve: Curves.easeOutBack,
                            switchOutCurve: Curves.easeIn,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(
                                      scale:
                                          Tween<double>(begin: 0.95, end: 1.0)
                                              .animate(animation),
                                      child: child));
                            },
                            child: _buildVisionOSMainContainer(activeHero,
                                key: ValueKey(activeHero.id)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 110),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: SlideTransition(
                position: _navBarSlide, child: _buildVisionOSBottomNav()),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader(List<HeroModel> heroes) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("MERHABA, ${widget.parentName.toUpperCase()}",
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode
                              ? Colors.cyanAccent.withOpacity(0.8)
                              : const Color(0xFF171A21).withOpacity(0.6),
                          letterSpacing: 2)),
                  const SizedBox(height: 4),
                  Text("KAHRAMANLAR",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: primaryText,
                          letterSpacing: 1.5)),
                ],
              ),
              GestureDetector(
                onTap: () {
                  setState(() => _isDarkMode = !_isDarkMode);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: glassBg,
                      border: Border.all(color: glassBorder)),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) => RotationTransition(
                        turns: anim,
                        child: FadeTransition(opacity: anim, child: child)),
                    child: Icon(
                      _isDarkMode
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      key: ValueKey(_isDarkMode),
                      color: _isDarkMode
                          ? Colors.amberAccent
                          : const Color(0xFF171A21),
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 90,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: heroes.length,
            itemBuilder: (context, index) {
              final hero = heroes[index];
              final isSelected = _selectedHeroIndex == index;

              return GestureDetector(
                onTap: () => setState(() => _selectedHeroIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutBack,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  transform: Matrix4.identity()
                    ..scale(isSelected ? 1.05 : 0.85),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: isSelected ? 1.0 : 0.5,
                    child: Column(
                      children: [
                        Container(
                          width: 65,
                          height: 65,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: glassBg,
                            border: Border.all(
                                color: isSelected
                                    ? hero.themeColor
                                    : Colors.transparent,
                                width: 2.5),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                        color: hero.themeColor.withOpacity(0.5),
                                        blurRadius: 15)
                                  ]
                                : [],
                          ),
                          child:
                              ClipOval(child: _buildSmartImage(hero.avatarUrl)),
                        ),
                        const SizedBox(height: 6),
                        Text(hero.name,
                            style: TextStyle(
                                color: isSelected ? primaryText : secondaryText,
                                fontWeight: isSelected
                                    ? FontWeight.w900
                                    : FontWeight.bold,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVisionOSMainContainer(HeroModel hero, {required Key key}) {
    final user = FirebaseAuth.instance.currentUser;

    return ClipRRect(
      key: key,
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: glassBg,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: glassBorder, width: 1.0),
            boxShadow: [
              BoxShadow(
                  color: _isDarkMode ? Colors.black26 : Colors.black12,
                  blurRadius: 40,
                  spreadRadius: -10)
            ],
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('parents')
                .doc(user!.uid)
                .collection('children')
                .doc(hero.id)
                .collection('quests')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                    child: CircularProgressIndicator(color: hero.themeColor));
              }

              final questDocs = snapshot.data?.docs ?? [];

              int totalXP = 0;
              List<Map<String, dynamic>> filteredQuests = [];

              for (var doc in questDocs) {
                final data = doc.data() as Map<String, dynamic>;

                if (data['status'] == 'completed') {
                  totalXP += (data['xpReward'] ?? 0) as int;
                }

                String freq = data['frequency'] ?? 'Her Gün';
                bool isVisibleToday = false;

                if (freq == 'Her Gün') {
                  isVisibleToday = true;
                } else if (freq == 'Hafta İçi' &&
                    _selectedTimelineDate.weekday <= 5) {
                  isVisibleToday = true;
                } else if (freq == 'Hafta Sonu' &&
                    _selectedTimelineDate.weekday >= 6) {
                  isVisibleToday = true;
                } else if (freq == 'Belirli Günler') {
                  List<dynamic> cDates = data['customDates'] ?? [];
                  if (cDates.contains(_formatDate(_selectedTimelineDate))) {
                    isVisibleToday = true;
                  }
                } else if (freq == 'Bir Kez') {
                  Timestamp? createdAt = data['createdAt'];
                  if (createdAt != null &&
                      _isSameDay(createdAt.toDate(), _selectedTimelineDate)) {
                    isVisibleToday = true;
                  }
                }

                if (isVisibleToday) {
                  filteredQuests.add(data);
                }
              }

              return Column(
                children: [
                  _buildHolographicScoreboard(hero, totalXP),
                  const SizedBox(height: 20),
                  _buildLiquidTimeline(hero.themeColor),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "GÜNLÜK GÖREVLER",
                      style: TextStyle(
                          color: secondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: filteredQuests.isEmpty
                        ? Center(
                            child: Text(
                              "Bu gün için atanmış görev yok.\nHadi yeni bir tane ekleyelim!",
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: secondaryText, fontSize: 14),
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 20),
                            itemCount: filteredQuests.length,
                            itemBuilder: (context, index) {
                              final data = filteredQuests[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: _buildRPGQuestCard(
                                  title: data['title'] ?? 'İsimsiz Görev',
                                  time: data['deadline'] != null
                                      ? "${data['deadline']}'a kadar"
                                      : "Tüm Gün",
                                  xp: data['xpReward'] ?? 0,
                                  status: data['status'] ?? 'pending',
                                  themeColor: hero.themeColor,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHolographicScoreboard(HeroModel hero, int totalXP) {
    int level = (totalXP ~/ 500) + 1;
    double progress = (totalXP % 500) / 500.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: glassBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: glassBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFFFC400).withOpacity(0.15),
              blurRadius: 40,
              spreadRadius: -10),
          BoxShadow(
              color: _isDarkMode ? Colors.black12 : Colors.transparent,
              blurRadius: 20)
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: hero.themeColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: hero.themeColor.withOpacity(0.5),
                          blurRadius: 15)
                    ],
                  ),
                  child: ClipOval(child: _buildSmartImage(hero.avatarUrl)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Seviye $level",
                          style: TextStyle(
                              color: hero.themeColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 1.2)),
                      const SizedBox(height: 2),
                      Text("Kahraman",
                          style: TextStyle(
                              color: secondaryText,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("$totalXP XP",
                  style: TextStyle(
                      color: _isDarkMode
                          ? const Color(0xFFFFC400)
                          : const Color(0xFFF57F17),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      shadows: _isDarkMode
                          ? [
                              const Shadow(
                                  color: Color(0xFFFFC400), blurRadius: 15)
                            ]
                          : [])),
              const SizedBox(height: 8),
              Container(
                width: 80,
                height: 6,
                decoration: BoxDecoration(
                    color: primaryText.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress == 0 ? 0.05 : progress,
                  child: Container(
                      decoration: BoxDecoration(
                          color: const Color(0xFFFFC400),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                        BoxShadow(
                            color: const Color(0xFFFFC400).withOpacity(0.8),
                            blurRadius: 8)
                      ])),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiquidTimeline(Color themeColor) {
    final today = DateTime.now();
    final List<DateTime> weekDays =
        List.generate(15, (index) => today.add(Duration(days: index - 2)));

    String getDayName(int weekday) {
      const days = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"];
      return days[weekday - 1];
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 70,
            child: ListView.builder(
              controller: _timelineScrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: weekDays.length,
              itemBuilder: (context, index) {
                DateTime date = weekDays[index];

                bool isSelected = _isSameDay(date, _selectedTimelineDate);
                bool isRealToday = _isSameDay(date, today);

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedTimelineDate = date);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 50,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? themeColor.withOpacity(0.85) : glassBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Colors.white
                            : (isRealToday ? themeColor : glassBorder),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                  color: themeColor.withOpacity(0.5),
                                  blurRadius: 15,
                                  spreadRadius: 2)
                            ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          getDayName(date.weekday),
                          style: TextStyle(
                              color: isSelected ? Colors.white : secondaryText,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${date.day}",
                          style: TextStyle(
                              color: isSelected ? Colors.white : primaryText,
                              fontSize: 16,
                              fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Container(
          width: 50,
          height: 70,
          margin: const EdgeInsets.only(left: 4),
          decoration: BoxDecoration(
              color: glassBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: glassBorder)),
          child: Center(
              child: Icon(Icons.calendar_month_rounded,
                  color: primaryText, size: 22)),
        ),
      ],
    );
  }

  Widget _buildRPGQuestCard(
      {required String title,
      required String time,
      required int xp,
      required String status,
      required Color themeColor}) {
    bool isCompleted = status == "completed";
    bool isProofWaiting = status == "proof_waiting";

    Color cardBgColor = glassBg;
    Color cardBorderColor = glassBorder;
    List<BoxShadow> cardShadows = [
      BoxShadow(
          color: _isDarkMode ? Colors.black12 : Colors.transparent,
          blurRadius: 15)
    ];
    double cardOpacity = isCompleted ? 0.5 : 1.0;

    if (isProofWaiting) {
      cardBorderColor = const Color(0xFFFF9100).withOpacity(0.8);
      cardShadows = [
        BoxShadow(
            color: const Color(0xFFFF9100).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2)
      ];
    }
    if (isCompleted) {
      cardBorderColor = const Color(0xFF00E676).withOpacity(0.5);
      cardShadows = [
        BoxShadow(
            color: const Color(0xFF00E676).withOpacity(0.1), blurRadius: 15)
      ];
    }

    return Opacity(
      opacity: cardOpacity,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: cardBorderColor, width: isProofWaiting ? 1.5 : 1.0),
          boxShadow: cardShadows,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF00E676).withOpacity(0.2)
                      : themeColor.withOpacity(0.15),
                  shape: BoxShape.circle),
              child: Center(
                  child: Icon(
                      isCompleted ? Icons.check_rounded : Icons.star_rounded,
                      color: isCompleted ? const Color(0xFF00E676) : themeColor,
                      size: 20)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: primaryText,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          decorationColor: primaryText.withOpacity(0.5))),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          color: secondaryText, size: 12),
                      const SizedBox(width: 4),
                      Text(time,
                          style: TextStyle(
                              color: secondaryText,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                      if (isProofWaiting) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: const Color(0xFFFF9100).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6)),
                          child: const Text("ONAY BEKLİYOR",
                              style: TextStyle(
                                  color: Color(0xFFFF9100),
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900)),
                        )
                      ]
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text("+$xp XP",
                style: TextStyle(
                    color: isCompleted
                        ? secondaryText
                        : (_isDarkMode
                            ? const Color(0xFFFFC400)
                            : const Color(0xFFF57F17)),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    shadows: isCompleted
                        ? []
                        : [
                            Shadow(
                                color: _isDarkMode
                                    ? const Color(0xFFFFC400)
                                    : Colors.transparent,
                                blurRadius: 10)
                          ])),
          ],
        ),
      ),
    );
  }

  Widget _buildVisionOSBottomNav() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
              color: navBg,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: glassBorder, width: 0.5),
              boxShadow: [
                BoxShadow(
                    color: _isDarkMode ? Colors.black45 : Colors.black12,
                    blurRadius: 30,
                    offset: const Offset(0, 10))
              ]),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(0, Icons.add_task_rounded, "Ekle"),
              _buildNavItem(1, Icons.playlist_remove_rounded, "Çıkar"),
              _buildNavItem(2, Icons.home_rounded, "Merkez"),
              _buildNavItem(3, Icons.emoji_events_rounded, "Ödül"),
              _buildNavItem(4, Icons.settings_rounded, "Ayar"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isActive = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 0) {
          Navigator.push(
              context,
              PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const AddQuestScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 400)));
        } else if (index == 1) {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const RemoveQuestScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        } else if (index == 3) {
          Navigator.push(
              context,
              PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const AddRewardScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 400)));
        } else if (index == 4) {
          Navigator.push(
              context,
              PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const ParentSettingsScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 400)));
        } else {
          setState(() => _selectedNavIndex = index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        width: isActive ? 80 : 50,
        transform: Matrix4.identity()..translate(0.0, isActive ? -10.0 : 0.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.all(isActive ? 14 : 10),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? Colors.cyanAccent.withOpacity(0.15)
                      : Colors.transparent,
                  border: Border.all(
                      color: isActive
                          ? Colors.cyanAccent.withOpacity(0.8)
                          : Colors.transparent,
                      width: 1.5),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                              color: Colors.cyanAccent.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 2)
                        ]
                      : []),
              child: Icon(icon,
                  color: isActive ? Colors.cyanAccent : secondaryText,
                  size: isActive ? 26 : 24),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: isActive
                  ? Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(label,
                          style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)))
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildSmartImage(String url) {
  if (url.startsWith('http')) {
    return Image.network(url,
        fit: BoxFit.cover,
        loadingBuilder: (c, child, progress) {
          if (progress == null) return child;
          return const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent));
        },
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
