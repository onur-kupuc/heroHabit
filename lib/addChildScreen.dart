import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'parentDashboardRouter.dart';

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen>
    with TickerProviderStateMixin {
  late AnimationController _staggeredController;
  late AnimationController _avatarRotateController;

  late Animation<Offset> _appBarSlide;
  late Animation<Offset> _avatarSlide;
  late Animation<Offset> _nameSlide;
  late Animation<Offset> _dateSlide;
  late Animation<Offset> _genderSlide;
  late Animation<Offset> _colorSlide;
  late Animation<Offset> _pinSlide;
  late Animation<Offset> _buttonSlide;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();

  String _selectedGender = '';
  int _selectedColorIndex = 0;

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

  final List<String> _quickAvatars = [
    'assets/images/1.png',
    'assets/images/2.png',
    'assets/images/3.png',
    'assets/images/4.png',
    'assets/images/5.png',
    'assets/images/6.png',
    'assets/images/7.png',
    'assets/images/8.png',
    'assets/images/9.png',
    'assets/images/10.png',
    'assets/images/11.png',
    'assets/images/12.png',
    'assets/images/13.png',
    'assets/images/14.png',
    'assets/images/15.png',
  ];

  @override
  void initState() {
    super.initState();
    _staggeredController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800));

    _appBarSlide = Tween<Offset>(begin: const Offset(0, -1.0), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _staggeredController,
            curve: const Interval(0.0, 0.3, curve: Curves.easeOutCubic)));
    _avatarSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _staggeredController,
            curve: const Interval(0.1, 0.5, curve: Curves.elasticOut)));
    _nameSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _staggeredController,
            curve: const Interval(0.2, 0.6, curve: Curves.elasticOut)));
    _dateSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _staggeredController,
            curve: const Interval(0.3, 0.7, curve: Curves.elasticOut)));
    _genderSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _staggeredController,
            curve: const Interval(0.4, 0.8, curve: Curves.elasticOut)));
    _colorSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _staggeredController,
            curve: const Interval(0.5, 0.9, curve: Curves.elasticOut)));
    _pinSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _staggeredController,
            curve: const Interval(0.6, 1.0, curve: Curves.elasticOut)));
    _buttonSlide = Tween<Offset>(begin: const Offset(0, 0.8), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _staggeredController,
            curve: const Interval(0.7, 1.0, curve: Curves.elasticOut)));

    _avatarRotateController =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();

    for (var node in _pinFocusNodes) {
      node.addListener(() {
        if (mounted) setState(() {});
      });
    }
    _nameFocus.addListener(() {
      if (mounted) setState(() {});
    });

    _staggeredController.forward();
  }

  @override
  void dispose() {
    _staggeredController.dispose();
    _avatarRotateController.dispose();
    _nameController.dispose();
    _dateController.dispose();
    _nameFocus.dispose();
    for (var c in _pinControllers) {
      c.dispose();
    }
    for (var n in _pinFocusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
          _selectedAvatarAsset = null;
        });
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Görsel seçme hatası: $e");
    }
  }

  void _selectQuickAvatar(String assetPath) {
    setState(() {
      _selectedAvatarAsset = assetPath;
      _selectedImageFile = null;
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<String?> _uploadAvatarToStorage(String userId, File imageFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('avatars')
          .child(userId)
          .child(fileName);

      final uploadTask = await storageRef.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Resim yükleme hatası: $e");
      return null;
    }
  }

  Future<void> _saveChildAndShowPairing() async {
    FocusScope.of(context).unfocus();

    final String name = _nameController.text.trim();
    final String dateStr = _dateController.text;
    final String pin = _pinControllers.map((c) => c.text).join();

    if (name.isEmpty ||
        dateStr.isEmpty ||
        _selectedGender.isEmpty ||
        pin.length < 4) {
      _showGlassSnackbar("Lütfen tüm alanları doldurun ve avatar seçin!");
      return;
    }
    if (_selectedImageFile == null && _selectedAvatarAsset == null) {
      _showGlassSnackbar("Lütfen bir kahraman yüzü (avatar) seçin!");
      return;
    }

    List<String> dateParts = dateStr.split('/');
    DateTime birthDate = DateTime(int.parse(dateParts[2]),
        int.parse(dateParts[1]), int.parse(dateParts[0]));

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => const PremiumLoadingOverlay(),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null)
        throw Exception("Oturum bulunamadı. Lütfen giriş yapın.");

      String finalAvatarPath = "";

      if (_selectedImageFile != null) {
        final uploadedUrl =
            await _uploadAvatarToStorage(user.uid, _selectedImageFile!);
        if (uploadedUrl != null) {
          finalAvatarPath = uploadedUrl;
        } else {
          throw Exception("Fotoğraf yüklenemedi.");
        }
      } else {
        finalAvatarPath = _selectedAvatarAsset!;
      }

      String colorHex =
          _heroColors[_selectedColorIndex].value.toRadixString(16);

      await FirebaseFirestore.instance
          .collection('parents')
          .doc(user.uid)
          .collection('children')
          .add({
        'name': name,
        'birthDate': Timestamp.fromDate(birthDate),
        'gender': _selectedGender,
        'avatarUrl': finalAvatarPath,
        'colorTheme': colorHex,
        'pinCode': pin,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      if (!mounted) return;
      Navigator.of(context).pop();
      showSuccessAndPairingDialog(context, name);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      _showGlassSnackbar("Hata oluştu: ${e.toString()}");
    }
  }

  void _showGlassSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
              ),
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                SlideTransition(
                    position: _appBarSlide, child: _buildGlassAppBar()),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 20.0),
                    child: Column(
                      children: [
                        SlideTransition(
                            position: _avatarSlide,
                            child: _buildAvatarCreator()),
                        const SizedBox(height: 30),
                        SlideTransition(
                            position: _nameSlide, child: _buildNameField()),
                        const SizedBox(height: 20),
                        SlideTransition(
                            position: _dateSlide, child: _buildDateField()),
                        const SizedBox(height: 24),
                        SlideTransition(
                            position: _genderSlide,
                            child: _buildGenderSelector()),
                        const SizedBox(height: 24),
                        SlideTransition(
                            position: _colorSlide,
                            child: _buildThemeColorSelector()),
                        const SizedBox(height: 30),
                        SlideTransition(
                            position: _pinSlide, child: _buildSecurityPIN()),
                        const SizedBox(height: 40),
                        SlideTransition(
                            position: _buttonSlide,
                            child: _buildCreateButton()),
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
            color: Colors.white.withOpacity(0.1),
            border: Border(
                bottom: BorderSide(
                    color: Colors.white.withOpacity(0.2), width: 1.5)),
            boxShadow: [
              BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 2)
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                    border: Border.all(color: Colors.white.withOpacity(0.5)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              const Expanded(
                child: Text(
                  "Yeni Kahraman Ekle",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.2),
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarCreator() {
    return GestureDetector(
      onTap: _showBreathtakingBottomSheet,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RotationTransition(
            turns: _avatarRotateController,
            child: SizedBox(
              width: 140,
              height: 140,
              child: CustomPaint(
                  painter: DashedGlowPainter(
                      color: _heroColors[_selectedColorIndex])),
            ),
          ),
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _heroColors[_selectedColorIndex].withOpacity(0.2),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.6), width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: -2)
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child)),
                  child: _selectedImageFile != null
                      ? Image.file(_selectedImageFile!,
                          key: const ValueKey('file_img'),
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover)
                      : _selectedAvatarAsset != null
                          ? Image.asset(_selectedAvatarAsset!,
                              key: const ValueKey('asset_img'),
                              width: 110,
                              height: 110,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => const Icon(
                                  Icons.cruelty_free_rounded,
                                  color: Colors.white,
                                  size: 50))
                          : Column(
                              key: const ValueKey('empty_img'),
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_rounded,
                                    color: _heroColors[_selectedColorIndex],
                                    size: 35),
                                const SizedBox(height: 4),
                                const Text("Seç",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
          hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontWeight: FontWeight.w600),
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
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() => _dateController.text =
              "${picked.day}/${picked.month}/${picked.year}");
        }
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
              hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontWeight: FontWeight.w600),
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
        curve: Curves.elasticOut,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? _heroColors[_selectedColorIndex].withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? _heroColors[_selectedColorIndex]
                : Colors.white.withOpacity(0.3),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: _heroColors[_selectedColorIndex].withOpacity(0.4),
                      blurRadius: 15)
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color:
                    isSelected ? Colors.white : Colors.white.withOpacity(0.6)),
            const SizedBox(width: 8),
            Text(title,
                style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.6),
                    fontSize: 16,
                    fontWeight:
                        isSelected ? FontWeight.w900 : FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeColorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Kahramanlık Rengi",
            style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
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
                curve: Curves.elasticOut,
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
                                blurRadius: 15,
                                spreadRadius: 2)
                          ]
                        : [],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 24)
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
        Text("Gizli Giriş Şifresi (PIN)",
            style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(4, (index) => _buildPinBox(index)),
        ),
        const SizedBox(height: 8),
        Text("Kardeşlerin profilleri karıştırmaması için 4 haneli şifre.",
            style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
                fontStyle: FontStyle.italic)),
      ],
    );
  }

  Widget _buildPinBox(int index) {
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
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocused || hasData
              ? activeColor
              : Colors.white.withOpacity(0.3),
          width: isFocused ? 2.5 : 1.5,
        ),
        boxShadow: isFocused
            ? [BoxShadow(color: activeColor.withOpacity(0.4), blurRadius: 15)]
            : [],
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
              color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
          decoration:
              const InputDecoration(border: InputBorder.none, counterText: ""),
          obscureText: true,
          obscuringCharacter: '★',
          onChanged: (value) {
            if (value.isNotEmpty && index < 3) {
              _pinFocusNodes[index + 1].requestFocus();
            } else if (value.isEmpty && index > 0) {
              _pinFocusNodes[index - 1].requestFocus();
            }
          },
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return GestureDetector(
      onTapDown: (_) => setState(() {}),
      onTap: _saveChildAndShowPairing,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 65,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(colors: [
            _heroColors[_selectedColorIndex],
            const Color(0xFF1A237E)
          ], begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [
            BoxShadow(
                color: _heroColors[_selectedColorIndex].withOpacity(0.6),
                blurRadius: 25,
                spreadRadius: 2,
                offset: const Offset(0, 8)),
          ],
        ),
        child: const Center(
          child: Text("KAHRAMANI YARAT",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2)),
        ),
      ),
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
                ? Colors.white.withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isFocused
                    ? Colors.cyanAccent
                    : Colors.white.withOpacity(0.3),
                width: 1.5),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.2),
                        blurRadius: 15)
                  ]
                : [],
          ),
          child: child,
        ),
      ),
    );
  }

  void _showBreathtakingBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                padding: const EdgeInsets.only(
                    top: 16, left: 24, right: 24, bottom: 40),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withOpacity(0.6),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(40)),
                  border: Border(
                      top: BorderSide(
                          color: Colors.cyanAccent.withOpacity(0.4),
                          width: 1.5)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.1),
                        blurRadius: 40,
                        spreadRadius: -5)
                  ],
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
                    const SizedBox(height: 30),
                    const Text("Kahramanın Yüzünü Seç",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                            child: LiquidActionCard(
                                title: "Kamera",
                                icon: Icons.camera_rounded,
                                color: const Color(0xFF00E5FF),
                                onTap: () => _pickImage(ImageSource.camera))),
                        const SizedBox(width: 16),
                        Expanded(
                            child: LiquidActionCard(
                                title: "Galeri",
                                icon: Icons.photo_library_rounded,
                                color: const Color(0xFFFF4081),
                                onTap: () => _pickImage(ImageSource.gallery))),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        Expanded(
                            child: Container(
                                height: 1,
                                color: Colors.white.withOpacity(0.1))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text("Veya Hızlı Bir Kahraman Seç",
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                            child: Container(
                                height: 1,
                                color: Colors.white.withOpacity(0.1))),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 90,
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        scrollDirection: Axis.horizontal,
                        itemCount: _quickAvatars.length,
                        itemBuilder: (context, index) {
                          bool isSelected =
                              _selectedAvatarAsset == _quickAvatars[index];
                          return GestureDetector(
                            onTap: () {
                              setModalState(() =>
                                  _selectedAvatarAsset = _quickAvatars[index]);
                              _selectQuickAvatar(_quickAvatars[index]);
                            },
                            child: AnimatedScale(
                              scale: isSelected ? 1.15 : 1.0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.elasticOut,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.only(right: 16),
                                width: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? Colors.cyanAccent.withOpacity(0.2)
                                      : Colors.white.withOpacity(0.05),
                                  border: Border.all(
                                      color: isSelected
                                          ? Colors.cyanAccent
                                          : Colors.white.withOpacity(0.2),
                                      width: isSelected ? 3 : 1),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                              color: Colors.cyanAccent
                                                  .withOpacity(0.5),
                                              blurRadius: 15)
                                        ]
                                      : [],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    _quickAvatars[index],
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Icon(
                                        Icons.face_retouching_natural_rounded,
                                        color: Colors.white.withOpacity(0.5),
                                        size: 40),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }
}

class LiquidActionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const LiquidActionCard(
      {super.key,
      required this.title,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  State<LiquidActionCard> createState() => _LiquidActionCardState();
}

class _LiquidActionCardState extends State<LiquidActionCard> {
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
        scale: _isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
            border:
                Border.all(color: widget.color.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: widget.color.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: -5)
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: widget.color, size: 35),
              const SizedBox(height: 12),
              Text(widget.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
            ],
          ),
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

    const double dashWidth = 0.15;
    const double dashSpace = 0.15;
    double startAngle = 0.0;

    while (startAngle < 2 * pi) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          startAngle, dashWidth, false, glowPaint);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          startAngle, dashWidth, false, dashPaint);
      startAngle += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant DashedGlowPainter oldDelegate) =>
      color != oldDelegate.color;
}

class PremiumLoadingOverlay extends StatelessWidget {
  const PremiumLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.8, end: 1.2),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          final scale =
              1.0 + (0.1 * sin(DateTime.now().millisecondsSinceEpoch / 200));
          return Transform.scale(
            scale: scale,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D2FF).withOpacity(0.5),
                    blurRadius: 40 * scale,
                    spreadRadius: 10 * scale,
                  ),
                ],
              ),
              child:
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 60),
            ),
          );
        },
      ),
    );
  }
}

void showSuccessAndPairingDialog(BuildContext context, String childName) {
  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: "Success",
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 700),
    pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
    transitionBuilder: (context, anim1, anim2, child) {
      final curve = Curves.easeOutBack.transform(anim1.value);
      final fade = Curves.easeIn.transform(anim1.value);

      return Stack(
        children: [
          Opacity(
            opacity: fade,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: const Color(0xFF050B14).withOpacity(0.6)),
            ),
          ),
          Transform.scale(
            scale: curve,
            child: Opacity(
              opacity: fade,
              child: SuccessDialogContent(childName: childName),
            ),
          ),
        ],
      );
    },
  );
}

class SuccessDialogContent extends StatelessWidget {
  final String childName;
  const SuccessDialogContent({super.key, required this.childName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 0.85,
              margin: const EdgeInsets.only(top: 50),
              padding: const EdgeInsets.fromLTRB(28, 65, 28, 28),
              decoration: BoxDecoration(
                color: const Color(0xFF121B2B).withOpacity(0.85),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                    color: Colors.white.withOpacity(0.1), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D2FF).withOpacity(0.12),
                    blurRadius: 80,
                    spreadRadius: -10,
                  ),
                  const BoxShadow(
                    color: Colors.black54,
                    blurRadius: 30,
                    offset: Offset(0, 15),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Kahraman Sahneye Çıktı!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "$childName artık maceraya hazır. Görevlerini kendi cihazından takip edebilmesi için hemen şimdi tabletiyle eşleştirmek ister misin?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.65),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 36),
                  _buildPrimaryButton(context),
                  const SizedBox(height: 12),
                  _buildGhostButton(context),
                ],
              ),
            ),
            Positioned(
              top: 0,
              child: _buildFloatingIcon(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF00D2FF), Color(0xFF007BFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00D2FF).withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.35), width: 1.5),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 24),
            SizedBox(width: 10),
            Text(
              "ŞİMDİ EŞLEŞTİR",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGhostButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);

        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const ParentDashboardRouter(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
          (Route<dynamic> route) => false,
        );
      },
      child: Container(
        height: 50,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withOpacity(0.04),
        ),
        child: Text(
          "Daha Sonra",
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingIcon() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF050B14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D2FF).withOpacity(0.15),
            blurRadius: 30,
            spreadRadius: 10,
          )
        ],
      ),
      child: Center(
        child: Container(
          width: 75,
          height: 75,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF00D2FF), Color(0xFF007BFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00D2FF).withOpacity(0.5),
                blurRadius: 15,
              )
            ],
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
      ),
    );
  }
}
