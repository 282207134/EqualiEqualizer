import 'dart:math';

import 'package:flutter/material.dart';

import '../../ui/theme.dart';
import '../../ui/widgets.dart';

class Vinyl extends StatelessWidget {
  const Vinyl({super.key, required this.cover, required this.rotation});
  final String cover;
  final double rotation;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final size = min(c.maxHeight, c.maxWidth * .88);
      return Center(
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(child: CustomPaint(painter: _AuraPainter(rotation))),
              Transform.rotate(
                angle: rotation,
                child: Container(
                  width: size * .81,
                  height: size * .81,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Color(0x55596882), offset: Offset(2, 3), blurRadius: 5),
                    ],
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF4B5696),
                        Color(0xFF9984EA),
                        Color(0xFF6C5B82),
                        Color(0xFF7265BD),
                      ],
                    ),
                  ),
                  child: CustomPaint(
                    painter: _GroovePainter(),
                    child: Center(
                      child: ClipOval(
                        child: Artwork(cover, size: size * .53, radius: size),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _AuraPainter extends CustomPainter {
  _AuraPainter(this.phase);
  final double phase;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .65;
    for (int ring = 0; ring < 22; ring++) {
      final path = Path();
      for (int i = 0; i <= 240; i++) {
        final angle = i / 240 * pi * 2;
        final radius =
            size.width * (.425 + ring * .0025) +
            sin(angle * 5 + ring * .10 + phase) * size.width * .025;
        final point = center + Offset(cos(angle) * radius, sin(angle) * radius);
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_AuraPainter old) => old.phase != phase;
}

class _GroovePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7;
    for (final radius in [.33, .37, .43, .495]) {
      canvas.drawCircle(size.center(Offset.zero), size.width * radius, paint);
    }
  }

  @override
  bool shouldRepaint(_GroovePainter old) => false;
}

class SoundDial extends StatelessWidget {
  const SoundDial({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
    this.black = false,
  });
  final double value;
  final String label;
  final ValueChanged<double>? onChanged;
  final bool black;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final size = min(c.maxWidth, c.maxHeight);
      void adjust(Offset local) {
        final angle = atan2(local.dy - size / 2, local.dx - size / 2);
        final normalized = ((angle - pi * .75) % (2 * pi)) / (pi * 1.5);
        onChanged?.call(normalized.clamp(0, 1));
      }

      return Center(
        child: Semantics(
          label: label,
          value: '${(value * 100).round()} percent',
          increasedValue: '${min(100, (value * 100).round() + 5)} percent',
          decreasedValue: '${max(0, (value * 100).round() - 5)} percent',
          onIncrease: onChanged == null ? null : () => onChanged!((value + .05).clamp(0, 1)),
          onDecrease: onChanged == null ? null : () => onChanged!((value - .05).clamp(0, 1)),
          child: GestureDetector(
            onPanUpdate: onChanged == null ? null : (event) => adjust(event.localPosition),
            onTapDown: onChanged == null ? null : (event) => adjust(event.localPosition),
            child: SizedBox.square(
              dimension: size,
              child: CustomPaint(
                painter: _DialPainter(value),
                child: Center(
                  child: SizedBox.square(
                    dimension: size * .70,
                    child: NeuBox(
                      radius: size,
                      child: Padding(
                        padding: EdgeInsets.all(size * .06),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: black ? const Color(0xFF090C0E) : null,
                          ),
                          child: black
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${(value * 100).round()}%',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(label, style: const TextStyle(color: Colors.white)),
                                  ],
                                )
                              : Align(
                                  alignment: Alignment(-.75 + value * .95, -.72),
                                  child: const SizedBox.square(
                                    dimension: 14,
                                    child: NeuBox(radius: 20, child: SizedBox()),
                                  ),
                                ),
                        ),
                      ),
                    ),
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

class _DialPainter extends CustomPainter {
  _DialPainter(this.value);
  final double value;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero), radius = size.width * .43;
    final shader = const LinearGradient(colors: [Color(0xFF6465FF), Color(0xFFD948FA)])
        .createShader(Offset.zero & size);
    for (int i = 0; i <= 32; i++) {
      final angle = pi * .75 + i / 32 * pi * 1.5;
      final paint = Paint()
        ..strokeWidth = size.width * .017
        ..strokeCap = StrokeCap.round;
      if (i / 32 <= value) {
        paint.shader = shader;
      } else {
        paint.color = const Color(0xFFCBD2DF);
      }
      canvas.drawLine(
        center + Offset(cos(angle), sin(angle)) * radius,
        center +
            Offset(cos(angle), sin(angle)) * (radius + size.width * (i % 4 == 0 ? .045 : .018)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DialPainter old) => old.value != value;
}

class Waveform extends StatelessWidget {
  const Waveform({super.key, required this.progress, required this.onSeek});
  final double progress;
  final ValueChanged<double> onSeek;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Playback position',
    value: '${(progress * 100).round()} percent',
    child: LayoutBuilder(
      builder: (context, c) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (e) => onSeek(e.localPosition.dx / c.maxWidth),
        onHorizontalDragUpdate: (e) => onSeek(e.localPosition.dx / c.maxWidth),
        child: SizedBox(
          height: 44,
          width: double.infinity,
          child: CustomPaint(painter: _WavePainter(progress)),
        ),
      ),
    ),
  );
}

class _WavePainter extends CustomPainter {
  _WavePainter(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 1;
    const count = 110;
    for (int i = 0; i < count; i++) {
      final x = i / (count - 1) * size.width;
      final height = 5 + (sin(i * 1.77).abs() * .5 + sin(i * .43).abs() * .5) * size.height * .85;
      paint.color = i / count <= progress
          ? Color.lerp(EqualiColors.primary, const Color(0xFFDC49FA), i / count)!
          : const Color(0xFFCBD2DE);
      canvas.drawLine(
        Offset(x, (size.height - height) / 2),
        Offset(x, (size.height + height) / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.progress != progress;
}

class EqualizerTicks extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = EqualiColors.icon
      ..strokeWidth = .7;
    for (int i = 0; i <= 24; i++) {
      final y = i / 24 * size.height;
      final length = i % 5 == 0 ? 10.0 : 5.0;
      canvas.drawLine(Offset(0, y), Offset(length, y), paint);
      canvas.drawLine(Offset(size.width - length, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(EqualizerTicks old) => false;
}
