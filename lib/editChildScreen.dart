import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'glass_toast.dart';

class HeroModel {
  final String id;
  final String name;
  final String avatarUrl;
  final Color themeColor;
  final String gender;
  final String pinCode;
  final DateTime? birthDate;

  HeroModel({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.themeColor,
    required this.gender,
    required this.pinCode,
    this.birthDate,
  });

  factory HeroModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String colorHex = data['colorTheme'] ?? 'ff00e5ff';
    Color parsedColor = Color(int.parse(colorHex, radix: 16));

    DateTime? bDate;
    if (data['birthDate'] != null) {
      bDate = (data['birthDate'] as Timestamp).toDate();
    }

    return HeroModel(
      id: doc.id,
      name: data['name'] ?? 'İsimsiz Kahraman',
      avatarUrl: data['avatarUrl'] ?? 'assets/images/1.png',
      themeColor: parsedColor,
      gender: data['gender'] ?? 'Kız',
      pinCode: data['pinCode'] ?? '0000',
      birthDate: bDate,
    );
  }
}

class EditChildScreen extends StatefulWidget {
  const EditChildScreen({super.key});

  @override
  State<EditChildScreen> createState() => _EditChildScreenState();
}

class _EditChildScreenState extends State<EditChildScreen>
    with TickerProviderStateMixin {
  late AnimationController _staggeredController;
  late AnimationController _avatarRotateController;

  late Animation<Offset> _appBarSlide;
  late Animation<Offset> _avatarSlide;
  late Animation<Offset> _formSlide;
  late Animation<Offset> _actionSlide;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();

  String _selectedGender = 'Kız';
  int _selectedColorIndex = 0;
  String _currentHeroId = '';

  final List<TextEditingController> _pinControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _pinFocusNodes = List.generate(4, (_) => FocusNode());

  final List<Color> _heroColors = [
    const Color(0xFF00E5FF),
    const Color(0xFFFF4081),
    const Color(0xFFFFC400),
    const Color(0xFF00E676),
    const Color(0xFF651FFF),
  ];

  File? _selectedImageFile;
  String? _selectedAvatarAsset;
  final ImagePicker _picker = ImagePicker();

  late Stream<QuerySnapshot> _heroesStream;
  bool _isLoading = false;

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

    _appBarSlide = Tween<Offset>(begin: const Offset(0, -1.0), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _staggeredController,
            curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic)));
    _avatarSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _staggeredController,
            curve: const Interval(0.2, 0.6, curve: Curves.elasticOut)));
    _formSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _staggeredController,
            curve: const Interval(0.4, 0.8, curve: Curves.easeOutBack)));
    _actionSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _staggeredController,
            curve: const Interval(0.6, 1.0, curve: Curves.elasticOut)));

    _avatarRotateController =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();

    _nameFocus.addListener(() {
      if (mounted) setState(() {});
    });
    for (var node in _pinFocusNodes) {
      node.addListener(() {
        if (mounted) setState(() {});
      });
    }

    _staggeredController.forward();
  }

  @override
  void dispose() {
    _staggeredController.dispose();
    _avatarRotateController.dispose();
    _nameController.dispose();
    _dateController.dispose();
    _nameFocus.dispose();
    for (var c in _pinControllers) c.dispose();
    for (var n in _pinFocusNodes) n.dispose();
    super.dispose();
  }

  void _populateForm(HeroModel hero) {
    if (_currentHeroId == hero.id) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _currentHeroId = hero.id;
        _nameController.text = hero.name;
        _selectedGender = hero.gender;

        int cIdx =
            _heroColors.indexWhere((c) => c.value == hero.themeColor.value);
        _selectedColorIndex = cIdx != -1 ? cIdx : 0;

        String pin = hero.pinCode.padRight(4, '0');
        for (int i = 0; i < 4; i++) {
          _pinControllers[i].text = pin[i];
        }

        if (hero.birthDate != null) {
          _dateController.text =
              "${hero.birthDate!.day}/${hero.birthDate!.month}/${hero.birthDate!.year}";
        }

        _selectedImageFile = null;
        if (hero.avatarUrl.startsWith('http')) {
          _selectedAvatarAsset = hero.avatarUrl;
        } else {
          _selectedAvatarAsset = hero.avatarUrl;
        }
      });
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("Görsel seçme hatası: $e");
    }
  }

  Future<void> _updateHero() async {
    FocusScope.of(context).unfocus();
    if (_currentHeroId.isEmpty) return;

    final String name = _nameController.text.trim();
    final String pin = _pinControllers.map((c) => c.text).join();

    if (name.isEmpty || pin.length < 4 || _dateController.text.isEmpty) {
      showGlassToast(context, "Lütfen tüm alanları eksiksiz doldurun!",
          isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Oturum bulunamadı!");

      String finalAvatarUrl = _selectedAvatarAsset ?? 'assets/images/1.png';

      if (_selectedImageFile != null) {
        final storageRef = FirebaseStorage.instance.ref().child(
            'avatars/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await storageRef.putFile(_selectedImageFile!);
        finalAvatarUrl = await storageRef.getDownloadURL();
      }

      String colorHex =
          _heroColors[_selectedColorIndex].value.toRadixString(16);
      List<String> dateParts = _dateController.text.split('/');
      DateTime birthDate = DateTime(int.parse(dateParts[2]),
          int.parse(dateParts[1]), int.parse(dateParts[0]));

      await FirebaseFirestore.instance
          .collection('parents')
          .doc(user.uid)
          .collection('children')
          .doc(_currentHeroId)
          .update({
        'name': name,
        'birthDate': Timestamp.fromDate(birthDate),
        'gender': _selectedGender,
        'avatarUrl': finalAvatarUrl,
        'colorTheme': colorHex,
        'pinCode': pin,
      });

      if (mounted) {
        showGlassToast(context, "Kahraman başarıyla güncellendi!",
            isError: false);
      }
    } catch (e) {
      if (mounted)
        showGlassToast(context, "Hata: ${e.toString()}", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDeleteConfirmation() {
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
                            spreadRadius: 5)
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Color(0xFFFF1744), size: 60),
                        const SizedBox(height: 20),
                        const Text("Kahramanı Sil",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 12),
                        Text(
                          "Bu kahramanı silersen tüm görevleri, ödülleri ve XP puanları sonsuza dek yok olur. Emin misin?",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                              height: 1.5),
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
                                      borderRadius: BorderRadius.circular(16)),
                                  child: const Center(
                                      child: Text("İptal",
                                          style: TextStyle(
                                              color: Colors.white70,
                                              fontWeight: FontWeight.bold))),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  Navigator.pop(context);
                                  _deleteHero();
                                },
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [
                                      Color(0xFFFF5252),
                                      Color(0xFFFF1744)
                                    ]),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                          color: const Color(0xFFFF1744)
                                              .withOpacity(0.4),
                                          blurRadius: 15,
                                          offset: const Offset(0, 4))
                                    ],
                                  ),
                                  child: const Center(
                                      child: Text("Evet, Sil",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900))),
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

  Future<void> _deleteHero() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || _currentHeroId.isEmpty) return;

      await FirebaseFirestore.instance
          .collection('parents')
          .doc(user.uid)
          .collection('children')
          .doc(_currentHeroId)
          .delete();

      if (mounted) {
        showGlassToast(context, "Kahraman başarıyla silindi.", isError: false);
        setState(() {
          _currentHeroId = '';
        });
      }
    } catch (e) {
      if (mounted)
        showGlassToast(context, "Hata: ${e.toString()}", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const AnimatedMeshBackground(),
          Container(color: const Color(0xFF050914).withOpacity(0.85)),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                SlideTransition(
                    position: _appBarSlide, child: _buildGlassAppBar()),
                StreamBuilder<QuerySnapshot>(
                  stream: _heroesStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                          height: 110,
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: Colors.cyanAccent)));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const SizedBox(
                          height: 110,
                          child: Center(
                              child: Text("Düzenlenecek kahraman yok.",
                                  style: TextStyle(color: Colors.white))));
                    }

                    List<HeroModel> heroes = snapshot.data!.docs
                        .map((doc) => HeroModel.fromFirestore(doc))
                        .toList();

                    if (_currentHeroId.isEmpty && heroes.isNotEmpty) {
                      _populateForm(heroes.first);
                    }

                    return SlideTransition(
                      position: _appBarSlide,
                      child: SizedBox(
                        height: 110,
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: heroes.length,
                          itemBuilder: (context, index) {
                            final hero = heroes[index];
                            final isSelected = _currentHeroId == hero.id;

                            return GestureDetector(
                              onTap: () => _populateForm(hero),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.elasticOut,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                transform: Matrix4.identity()
                                  ..scale(isSelected ? 1.1 : 0.85),
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
                                                      color: hero.themeColor
                                                          .withOpacity(0.6),
                                                      blurRadius: 20,
                                                      spreadRadius: 2)
                                                ]
                                              : [],
                                        ),
                                        child: ClipOval(
                                            child: _buildSmartImage(
                                                hero.avatarUrl)),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(hero.name,
                                          style: TextStyle(
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.white70,
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
                      ),
                    );
                  },
                ),
                Expanded(
                  child: _currentHeroId.isEmpty
                      ? const SizedBox()
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24.0, vertical: 20.0),
                          child: Column(
                            children: [
                              SlideTransition(
                                  position: _avatarSlide,
                                  child: _buildAvatarEditor()),
                              const SizedBox(height: 30),
                              SlideTransition(
                                  position: _formSlide,
                                  child: _buildNameField()),
                              const SizedBox(height: 20),
                              SlideTransition(
                                  position: _formSlide,
                                  child: _buildDateField()),
                              const SizedBox(height: 24),
                              SlideTransition(
                                  position: _formSlide,
                                  child: _buildGenderSelector()),
                              const SizedBox(height: 24),
                              SlideTransition(
                                  position: _formSlide,
                                  child: _buildThemeColorSelector()),
                              const SizedBox(height: 30),
                              SlideTransition(
                                  position: _formSlide,
                                  child: _buildSecurityPIN()),
                              const SizedBox(height: 40),
                              SlideTransition(
                                  position: _actionSlide,
                                  child: _buildUpdateButton()),
                              const SizedBox(height: 16),
                              SlideTransition(
                                  position: _actionSlide,
                                  child: _buildDeleteButton()),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassAppBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            border: Border(
                bottom:
                    BorderSide(color: Colors.white.withOpacity(0.1), width: 1)),
          ),
          child: Row(
            children: [
              IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white),
                  onPressed: () => Navigator.pop(context)),
              const Expanded(
                child: Text("Kahramanları Düzenle",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.2)),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarEditor() {
    Color activeColor = _heroColors[_selectedColorIndex];
    return GestureDetector(
      onTap: () => _pickImage(ImageSource.gallery),
      child: Stack(
        alignment: Alignment.center,
        children: [
          RotationTransition(
            turns: _avatarRotateController,
            child: SizedBox(
              width: 140,
              height: 140,
              child:
                  CustomPaint(painter: DashedGlowPainter(color: activeColor)),
            ),
          ),
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: activeColor.withOpacity(0.2),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.6), width: 2),
                ),
                child: _selectedImageFile != null
                    ? Image.file(_selectedImageFile!, fit: BoxFit.cover)
                    : (_selectedAvatarAsset != null
                        ? _buildSmartImage(_selectedAvatarAsset!)
                        : Icon(Icons.add_a_photo_rounded,
                            color: activeColor, size: 35)),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2)),
              child:
                  const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
            ),
          )
        ],
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
          errorBuilder: (c, e, s) =>
              const Icon(Icons.person, color: Colors.white));
    }
  }

  Widget _buildNameField() {
    return _buildGlassContainer(
      isFocused: _nameFocus.hasFocus,
      child: TextField(
        controller: _nameController,
        focusNode: _nameFocus,
        style: const TextStyle(
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          hintText: "Kahramanın Adı",
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon:
              const Icon(Icons.person_rounded, color: Colors.cyanAccent),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: () async {
        FocusScope.of(context).unfocus();
        DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime.now());
        if (picked != null)
          setState(() => _dateController.text =
              "${picked.day}/${picked.month}/${picked.year}");
      },
      child: _buildGlassContainer(
        isFocused: false,
        child: AbsorbPointer(
          child: TextField(
            controller: _dateController,
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: "Doğum Tarihi",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              prefixIcon: const Icon(Icons.calendar_month_rounded,
                  color: Colors.cyanAccent),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Row(
      children: [
        Expanded(child: _buildGenderOption("Kız", Icons.face_3_rounded)),
        const SizedBox(width: 16),
        Expanded(child: _buildGenderOption("Erkek", Icons.face_6_rounded)),
      ],
    );
  }

  Widget _buildGenderOption(String title, IconData icon) {
    bool isSelected = _selectedGender == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? _heroColors[_selectedColorIndex].withOpacity(0.3)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected
                  ? _heroColors[_selectedColorIndex]
                  : Colors.white.withOpacity(0.2),
              width: isSelected ? 2 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.white54),
            const SizedBox(width: 8),
            Text(title,
                style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white54,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeColorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Tema Rengi",
            style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_heroColors.length, (index) {
            bool isSelected = _selectedColorIndex == index;
            return GestureDetector(
              onTap: () => setState(() => _selectedColorIndex = index),
              child: AnimatedScale(
                scale: isSelected ? 1.2 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: _heroColors[index],
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white, width: isSelected ? 3 : 0),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                                color: _heroColors[index].withOpacity(0.8),
                                blurRadius: 15)
                          ]
                        : [],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded, color: Colors.white)
                      : null,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSecurityPIN() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Cihaz Giriş Şifresi (PIN)",
            style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(4, (index) {
            bool isFocused = _pinFocusNodes[index].hasFocus;
            bool hasData = _pinControllers[index].text.isNotEmpty;
            Color activeColor = _heroColors[_selectedColorIndex];

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 65,
              height: 75,
              decoration: BoxDecoration(
                color: isFocused
                    ? activeColor.withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isFocused || hasData
                        ? activeColor
                        : Colors.white.withOpacity(0.2),
                    width: 2),
              ),
              child: Center(
                child: TextField(
                  controller: _pinControllers[index],
                  focusNode: _pinFocusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(1)
                  ],
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900),
                  decoration: const InputDecoration(
                      border: InputBorder.none, counterText: ""),
                  onChanged: (val) {
                    if (val.isNotEmpty && index < 3)
                      _pinFocusNodes[index + 1].requestFocus();
                    else if (val.isEmpty && index > 0)
                      _pinFocusNodes[index - 1].requestFocus();
                  },
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildGlassContainer(
      {required Widget child, required bool isFocused}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: isFocused
                ? Colors.white.withOpacity(0.15)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isFocused
                    ? Colors.cyanAccent
                    : Colors.white.withOpacity(0.2),
                width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildUpdateButton() {
    Color activeColor = _heroColors[_selectedColorIndex];
    return GestureDetector(
      onTap: _isLoading ? null : _updateHero,
      child: Container(
        height: 65,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient:
              LinearGradient(colors: [activeColor, const Color(0xFF1A237E)]),
          boxShadow: [
            BoxShadow(
                color: activeColor.withOpacity(0.6),
                blurRadius: 25,
                offset: const Offset(0, 8))
          ],
        ),
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("DEĞİŞİKLİKLERİ KAYDET",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5)),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return GestureDetector(
      onTap: _showDeleteConfirmation,
      child: Container(
        height: 60,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFF1744).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFF1744).withOpacity(0.5)),
        ),
        child: const Center(
          child: Text("Kahramanı Sil",
              style: TextStyle(
                  color: Color(0xFFFF1744),
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class DashedGlowPainter extends CustomPainter {
  final Color color;
  DashedGlowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    final Paint glowPaint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final Paint dashPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    double startAngle = 0.0;
    while (startAngle < 2 * pi) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          startAngle, 0.15, false, glowPaint);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          startAngle, 0.15, false, dashPaint);
      startAngle += 0.30;
    }
  }

  @override
  bool shouldRepaint(covariant DashedGlowPainter oldDelegate) =>
      color != oldDelegate.color;
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
