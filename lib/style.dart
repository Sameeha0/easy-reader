import 'dart:ui';

import 'package:flutter/material.dart';

// Varsity colours: navy, gold, cherry red on warm cream.
const navy = Color(0xFF1A2868);
const navyDark = Color(0xFF0F1A4A);
const gold = Color(0xFFF0C030);
const goldDark = Color(0xFFC99A12);
const cherry = Color(0xFFC41230);
const cherryDark = Color(0xFF8E0C22);
const cream = Color(0xFFF7F1E3);
const ink = Color(0xFF14183A);
const muted = Color(0xFF5B5F7A);

// Strong ease-out, feels snappier than the built-in one.
const easeOut = Cubic(0.23, 1, 0.32, 1);

// Bricolage Grotesque for headings. It's a variable font, so the weight is set with 'wght'.
TextStyle heading(double size, {Color color = navy}) => TextStyle(
      fontFamily: 'Bricolage',
      fontSize: size,
      color: color,
      height: 1.05,
      letterSpacing: -size * 0.02,
      fontVariations: [const FontVariation('wght', 760), FontVariation('opsz', size.clamp(12, 96).toDouble())],
    );

// Figtree for everything else.
TextStyle body(double size, {Color color = ink, double weight = 500}) => TextStyle(
      fontFamily: 'Figtree',
      fontSize: size,
      color: color,
      height: 1.35,
      fontVariations: [FontVariation('wght', weight)],
    );

// Solid rounded block with a hard edge underneath, like a sticker.
BoxDecoration block(Color color, {Color? edge, Color? border}) => BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      border: border == null ? null : Border.all(color: border, width: 2.5),
      boxShadow: edge == null ? null : [BoxShadow(color: edge, offset: const Offset(0, 5))],
    );

// Frosted glass panel. The tint is kept strong so the words stay easy to read.
class Glass extends StatelessWidget {
  final Widget child;
  final Color tint;
  final EdgeInsets padding;
  const Glass({super.key, required this.child, required this.tint, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [BoxShadow(color: navy.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: radius,
              // light top-left to slightly clearer bottom-right, like real glass
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [tint.withValues(alpha: 0.92), tint.withValues(alpha: 0.78)],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1.5),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// Gold and red stripes, like a jersey collar.
class Stripes extends StatelessWidget {
  const Stripes({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(height: 6, color: gold),
      Container(height: 6, color: cherry),
    ]);
  }
}

// Notebook background: a grid of boxes with a soft glow in the middle,
// drifting slowly. Stays still if "Remove animations" is on in the phone settings.
class NotebookGrid extends StatefulWidget {
  final Widget child;
  final Color line, glow;
  const NotebookGrid({super.key, required this.child, required this.line, required this.glow});

  @override
  State<NotebookGrid> createState() => _NotebookGridState();
}

class _NotebookGridState extends State<NotebookGrid> with SingleTickerProviderStateMixin {
  late final AnimationController time = AnimationController(vsync: this, duration: const Duration(seconds: 12));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      time.stop();
    } else if (!time.isAnimating) {
      time.repeat();
    }
  }

  @override
  void dispose() {
    time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GridPainter(time, widget.line, widget.glow), child: widget.child);
  }
}

class _GridPainter extends CustomPainter {
  final AnimationController time;
  final Color line, glow;
  _GridPainter(this.time, this.line, this.glow) : super(repaint: time);

  static const box = 44.0;

  @override
  void paint(Canvas canvas, Size size) {
    final area = Offset.zero & size;
    canvas.clipRect(area);

    // soft light in the middle, like the spotlight in the video
    canvas.drawRect(
      area,
      Paint()
        ..shader = RadialGradient(
          radius: 0.8,
          colors: [glow, glow.withValues(alpha: 0)],
        ).createShader(area),
    );

    // grid lines, strongest in the middle and fading out at the edges
    final paint = Paint()
      ..strokeWidth = 1.2
      ..shader = RadialGradient(
        radius: 0.9,
        colors: [line, line.withValues(alpha: 0)],
        stops: const [0.35, 1],
      ).createShader(area);

    // moving by exactly one box loops without a jump
    final shift = time.value * box;
    for (var y = shift - box; y < size.height; y += box) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (var x = size.width / 2 % box; x < size.width; x += box) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}

// Sinks a little the moment the finger lands.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const Pressable({super.key, required this.child, required this.onTap});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => down = true),
      onTapUp: (_) => setState(() => down = false),
      onTapCancel: () => setState(() => down = false),
      onTap: widget.onTap,
      child: AnimatedSlide(
        // moves down onto its hard edge, like pressing a real button
        offset: down ? const Offset(0, 0.03) : Offset.zero,
        duration: const Duration(milliseconds: 120),
        curve: easeOut,
        child: AnimatedScale(
          scale: down ? 0.98 : 1,
          duration: const Duration(milliseconds: 120),
          curve: easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

// A big button with words on it (no icon-only buttons in the app).
class BigButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool filled;
  const BigButton(this.text, this.onPressed, {super.key, this.filled = true});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onPressed,
      child: Container(
        height: 60,
        alignment: Alignment.center,
        decoration: filled ? block(navy, edge: navyDark) : block(Colors.white, border: navy, edge: navy),
        child: Text(text, style: body(20, color: filled ? gold : navy, weight: 750)),
      ),
    );
  }
}

// Top bar used on every other screen: a big "Back" button, a title and the stripes.
PreferredSizeWidget topBar(BuildContext context, String title) {
  return AppBar(
    toolbarHeight: 84,
    leadingWidth: 132,
    backgroundColor: cream,
    leading: Padding(
      padding: const EdgeInsets.only(left: 12, top: 12, bottom: 16),
      child: BigButton('‹ Back', () => Navigator.pop(context), filled: false),
    ),
    title: Text(title, maxLines: 2, style: heading(20)),
    bottom: const PreferredSize(preferredSize: Size.fromHeight(12), child: Stripes()),
  );
}
