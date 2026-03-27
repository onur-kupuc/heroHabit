import 'dart:ui';
import 'package:flutter/material.dart';

void showGlassToast(BuildContext context, String message,
    {bool isError = true}) {
  final overlay = Overlay.of(context);
  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 24,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, -50 * (1 - value)),
              child: Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isError
                      ? Colors.redAccent.withOpacity(0.15)
                      : Colors.cyanAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isError
                        ? Colors.redAccent.withOpacity(0.5)
                        : Colors.cyanAccent.withOpacity(0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isError
                          ? Colors.redAccent.withOpacity(0.3)
                          : Colors.cyanAccent.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      isError
                          ? Icons.error_outline_rounded
                          : Icons.check_circle_outline_rounded,
                      color: isError ? Colors.redAccent : Colors.cyanAccent,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);
  Future.delayed(
      const Duration(milliseconds: 3500), () => overlayEntry.remove());
}
