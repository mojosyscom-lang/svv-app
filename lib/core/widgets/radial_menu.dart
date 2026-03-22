import 'dart:math' as math;
import 'package:flutter/material.dart';

class RadialItem {
  final String imagePath;
  final VoidCallback? onTap;

  RadialItem({required this.imagePath, this.onTap});
}

class RadialMenu extends StatefulWidget {
  final List<RadialItem> items;
  final VoidCallback? onCenterTap;

  const RadialMenu({
    super.key,
    required this.items,
    this.onCenterTap,
  });

  @override
  State<RadialMenu> createState() => _RadialMenuState();
}

class _RadialMenuState extends State<RadialMenu> with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _entranceAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _entranceAnimation = CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack);
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;
        final double minDimension = math.min(width, height);

        // We check if this is the Dashboard (4 items) or the Expanded Page (6 items)
        final bool isExpandedPage = widget.items.length > 4;

        // 1. SIZES
        final double centerStarSize = minDimension * (isExpandedPage ? 0.60 : 0.85); 
        final double buttonSize = minDimension * (isExpandedPage ? 0.35 : 0.42);     
        
        // 2. SPREAD / ALIGNMENT
        final double orbitRadiusX = width * (isExpandedPage ? 0.30 : 0.40); 
        final double orbitRadiusY = height * (isExpandedPage ? 0.35 : 0.45); 

        final double centerX = width / 2;
        final double centerY = height / 2;

        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. The Orbiting Buttons
              ...List.generate(widget.items.length, (index) {
                
                double angle;
                if (!isExpandedPage) {
                  // Dashboard: 4 corners
                  final angleMap = [-145.0, -35.0, 145.0, 35.0];
                  angle = angleMap[index] * math.pi / 180;
                } else {
                  // Expanded: Perfect circle of 6
                  angle = ((index * 360 / widget.items.length) - 90) * math.pi / 180;
                }

                double leftPos = centerX + (orbitRadiusX * math.cos(angle)) - (buttonSize / 2);
                double topPos = centerY + (orbitRadiusY * math.sin(angle)) - (buttonSize / 2);

                return Positioned(
                  left: leftPos,
                  top: topPos,
                  child: ScaleTransition(
                    scale: _entranceAnimation,
                    child: InteractiveRadialButton(
                      imagePath: widget.items[index].imagePath,
                      size: buttonSize,
                      onTap: widget.items[index].onTap,
                    ),
                  ),
                );
              }),

              // 2. The Center Star
              Align(
                alignment: Alignment.center,
                child: ScaleTransition(
                  scale: _entranceAnimation,
                  child: InteractiveRadialButton(
                    imagePath: 'assets/images/module-star.png',
                    size: centerStarSize,
                    onTap: widget.onCenterTap,
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

// ============================================================================
// --- CUSTOM WIDGET: Tactile "Scale & Shadow" press effect WITH GLOW ---
// ============================================================================
class InteractiveRadialButton extends StatefulWidget {
  final String imagePath;
  final double size;
  final VoidCallback? onTap;

  const InteractiveRadialButton({
    super.key,
    required this.imagePath,
    required this.size,
    this.onTap,
  });

  @override
  State<InteractiveRadialButton> createState() => _InteractiveRadialButtonState();
}

class _InteractiveRadialButtonState extends State<InteractiveRadialButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  Future<void> _handleTapUp(TapUpDetails details) async {
    await Future.delayed(const Duration(milliseconds: 75));
    if (mounted) setState(() => _isPressed = false);

    if (widget.onTap != null) {
      await Future.delayed(const Duration(milliseconds: 100));
      widget.onTap!();
    }
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedScale(
        scale: _isPressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        // --- NEW: A Container to hold our beautiful golden glow! ---
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                // The glow is bright gold normally, but dims when pressed into the screen
                color: const Color(0xFFFFD166).withOpacity(_isPressed ? 0.15 : 0.45),
                blurRadius: _isPressed ? 10 : 25, // Glow shrinks when pressed
                spreadRadius: _isPressed ? 1 : 5,
              ),
            ],
          ),
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(_isPressed ? 0.4 : 0.0), 
              BlendMode.srcATop, 
            ),
            child: Image.asset(
              widget.imagePath,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}