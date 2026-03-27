import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'parentEmptyDashboardScreen.dart';
import 'parentMainDashboardScreen.dart';
import 'main.dart';

import 'dart:async';
import 'dart:math';

class ParentDashboardRouter extends StatelessWidget {
  const ParentDashboardRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
          body: Center(child: Text("Hata: Kullanıcı bulunamadı.")));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(
                  child: CircularProgressIndicator(color: Colors.cyanAccent)));
        }

        String parentName = "Kahraman";
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          Map<String, dynamic> userData =
              userSnapshot.data!.data() as Map<String, dynamic>;
          parentName = userData['ad_soyad'] ?? "Kahraman";
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('parents')
              .doc(currentUser.uid)
              .collection('children')
              .snapshots(),
          builder: (context, childrenSnapshot) {
            if (childrenSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                body: Stack(
                  children: [
                    const AnimatedMeshBackground(),
                    const Center(
                        child: CircularProgressIndicator(
                            color: Colors.cyanAccent)),
                  ],
                ),
              );
            }

            if (!childrenSnapshot.hasData ||
                childrenSnapshot.data!.docs.isEmpty) {
              return ParentEmptyDashboardScreen(parentName: parentName);
            } else {
              return ParentMainDashboardScreen(parentName: parentName);
            }
          },
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
