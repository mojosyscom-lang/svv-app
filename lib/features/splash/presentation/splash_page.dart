import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/route_names.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {

  late AnimationController logoController;
  late AnimationController glowController;
  late AnimationController ringController;
  late AnimationController burstController;

  late Animation<double> logoScale;
  late Animation<double> logoOpacity;

  late Animation<double> glowScale;
  late Animation<double> glowOpacity;

  late Animation<double> ringScale;
  late Animation<double> ringOpacity;

  late Animation<double> burstScale;
  late Animation<double> burstOpacity;

  @override
  void initState() {
    super.initState();

    // --- LOGO ---
    logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    logoScale = Tween(begin: 0.92, end: 1.0)
        .animate(CurvedAnimation(parent: logoController, curve: Curves.easeOut));

    logoOpacity = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: logoController, curve: Curves.easeOut));

    // --- GLOW ---
    glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    glowScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.65, end: 0.95), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.05), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.55), weight: 45),
    ]).animate(CurvedAnimation(parent: glowController, curve: Curves.easeInOut));

    glowOpacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.85), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 0.55), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 0.55, end: 0.0), weight: 20),
    ]).animate(CurvedAnimation(parent: glowController, curve: Curves.easeInOut));

    // --- RING ---
    ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    ringScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 0.95), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.25), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.75), weight: 35),
    ]).animate(CurvedAnimation(parent: ringController, curve: Curves.easeInOut));

    ringOpacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.65), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.65, end: 0.35), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 0.35, end: 0.0), weight: 35),
    ]).animate(CurvedAnimation(parent: ringController, curve: Curves.easeInOut));

    // --- BURST ---
    burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    burstScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.1), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 2.9), weight: 45),
    ]).animate(CurvedAnimation(parent: burstController, curve: Curves.easeOut));

    burstOpacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 45),
    ]).animate(CurvedAnimation(parent: burstController, curve: Curves.easeOut));

    // START SEQUENCE
    logoController.forward();

    Future.delayed(const Duration(milliseconds: 200), () {
      glowController.forward();
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      ringController.forward();
    });

    Future.delayed(const Duration(milliseconds: 1800), () {
      burstController.forward();
    });

    // NAVIGATION AFTER 3s
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        RouteNames.authGate,
        (route) => false,
      );
    });
  }

  @override
  void dispose() {
    logoController.dispose();
    glowController.dispose();
    ringController.dispose();
    burstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = min(MediaQuery.of(context).size.width * 0.78, 320.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            logoController,
            glowController,
            ringController,
            burstController
          ]),
          builder: (_, __) {
            return Opacity(
              opacity: burstOpacity.value,
              child: Transform.scale(
                scale: burstScale.value,
                child: Stack(
                  alignment: Alignment.center,
                  children: [

                    // GLOW
                    Transform.scale(
                      scale: glowScale.value,
                      child: Opacity(
                        opacity: glowOpacity.value,
                        child: Container(
                          width: size * 1.2,
                          height: size * 1.2,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Color(0x59FF0080),
                                Colors.transparent
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // RING
                    Transform.scale(
                      scale: ringScale.value,
                      child: Opacity(
                        opacity: ringOpacity.value,
                        child: Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.22),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // LOGO
                    Transform.scale(
                      scale: logoScale.value,
                      child: Opacity(
                        opacity: logoOpacity.value,
                        child: Image.asset(
                          "assets/images/logo_svv1.png",
                          width: size,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}