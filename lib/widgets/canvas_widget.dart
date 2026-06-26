import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

// ── Color constants ──────────────────────────────────────────
const _cyan = Color(0xFF63C8FF);
const _cyanDim = Color(0xFF2A3F55);
const _cyanGlow = Color(0x2663C8FF);
const _cardBg = Color(0xFF111827);
const _trackBg = Color(0xFF1E2A3A);
const _baseBg = Color(0xFF0D1520);
const _orange = Color(0xFFFF6B35); // zero marker on steering

class CanvasWidget extends StatefulWidget {
  final Map widgetData;
  final String mqttTopic;
  final bool editMode;
  final Function(double, double) onMove;
  final VoidCallback onDelete;
  final VoidCallback onRename;

  const CanvasWidget({
    super.key,
    required this.widgetData,
    required this.mqttTopic,
    required this.editMode,
    required this.onMove,
    required this.onDelete,
    required this.onRename,
  });

  @override
  State<CanvasWidget> createState() => _CanvasWidgetState();
}

class _CanvasWidgetState extends State<CanvasWidget>
    with TickerProviderStateMixin {
  // shared state
  bool toggleValue = false;
  double sliderValue = 0.5;
  bool isMuted = false;

  // steering
  double steerAngle = 0;
  late AnimationController _steerReturnCtrl;
  late Animation<double> _steerReturnAnim;

  // gauge
  double _gaugeValue = 0;
  late AnimationController _gaugeCtrl;
  late Animation<double> _gaugeAnim;

  // button flash
  late AnimationController _btnFlashCtrl;

  @override
  void initState() {
    super.initState();
    _steerReturnCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _steerReturnAnim = Tween<double>(begin: 0, end: 0).animate(
        CurvedAnimation(parent: _steerReturnCtrl, curve: Curves.easeOut));
    _steerReturnAnim.addListener(() {
      setState(() => steerAngle = _steerReturnAnim.value);
    });

    _gaugeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _gaugeAnim = Tween<double>(begin: 0, end: 0).animate(
        CurvedAnimation(parent: _gaugeCtrl, curve: Curves.easeInOut));
    _gaugeAnim.addListener(() {
      setState(() => _gaugeValue = _gaugeAnim.value);
    });

    _btnFlashCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
  }

  @override
  void dispose() {
    _steerReturnCtrl.dispose();
    _gaugeCtrl.dispose();
    _btnFlashCtrl.dispose();
    super.dispose();
  }

  void _sendCommand(String command) async {
    try {
      final result = await ApiService.sendCommand(widget.mqttTopic, command);
      debugPrint('Sent via API: $command → $result');
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  // ── TOGGLE ──────────────────────────────────────────────────
  Widget _buildToggle(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            setState(() => toggleValue = !toggleValue);
            _sendCommand(toggleValue ? 'ON' : 'OFF');
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 62,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: toggleValue ? _baseBg : _trackBg,
              border: Border.all(
                color: toggleValue ? color : _cyanDim,
                width: 1.5,
              ),
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  top: 3,
                  left: toggleValue ? 31 : 3,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: toggleValue ? color : _cyanDim,
                      boxShadow: toggleValue
                          ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)]
                          : [],
                    ),
                    child: Center(
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white
                              .withOpacity(toggleValue ? 0.6 : 0.15),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          toggleValue ? 'ON' : 'OFF',
          style: GoogleFonts.orbitron(
            color: toggleValue ? color : _cyanDim,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        // pulse dot
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: toggleValue ? color : _cyanDim,
            boxShadow: toggleValue
                ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 5)]
                : [],
          ),
        ),
      ],
    );
  }

  // ── SLIDER ──────────────────────────────────────────────────
  Widget _buildSlider(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: color,
            inactiveTrackColor: _trackBg,
            thumbColor: color,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayColor: color.withOpacity(0.15),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: sliderValue,
            onChanged: (v) {
              setState(() => sliderValue = v);
              _sendCommand('SLIDER:${(v * 100).toInt()}');
            },
          ),
        ),
        Text(
          '${(sliderValue * 100).toInt()}%',
          style: GoogleFonts.orbitron(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  // ── BUTTON ──────────────────────────────────────────────────
  Widget _buildButton(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // outer glow ring
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.12), width: 1),
              ),
            ),
            GestureDetector(
              onTapDown: (_) {
                setState(() {});
                _btnFlashCtrl.forward(from: 0);
                _sendCommand('PRESS');
              },
              onTapUp: (_) => setState(() {}),
              onTapCancel: () => setState(() {}),
              child: AnimatedBuilder(
                animation: _btnFlashCtrl,
                builder: (_, __) {
                  final pressed = _btnFlashCtrl.isAnimating;
                  return Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: pressed ? const Color(0xFF1A3A52) : _baseBg,
                      border: Border.all(
                        color: pressed ? color.withOpacity(0.9) : color,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bolt_rounded, color: color, size: 28),
                        Text(
                          'EXEC',
                          style: GoogleFonts.orbitron(
                            color: color,
                            fontSize: 7,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AnimatedBuilder(
          animation: _btnFlashCtrl,
          builder: (_, __) => AnimatedOpacity(
            opacity: _btnFlashCtrl.isAnimating ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 5)]),
            ),
          ),
        ),
      ],
    );
  }

  // ── STEERING ─────────────────────────────────────────────────
  Widget _buildSteering(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onPanStart: (_) => _steerReturnCtrl.stop(),
          onPanUpdate: (d) {
            setState(() {
              steerAngle = (steerAngle + d.delta.dx * 1.5).clamp(-135.0, 135.0);
            });
            _sendCommand('STEER:${steerAngle.toInt()}');
          },
          onPanEnd: (_) {
            _steerReturnAnim = Tween<double>(begin: steerAngle, end: 0).animate(
                CurvedAnimation(parent: _steerReturnCtrl, curve: Curves.easeOut));
            _steerReturnAnim.addListener(() {
              setState(() => steerAngle = _steerReturnAnim.value);
            });
            _steerReturnCtrl.forward(from: 0);
          },
          child: SizedBox(
            width: 120,
            height: 120,
            child: CustomPaint(
              painter: _SteeringPainter(
                color: color,
                angle: steerAngle,
                zeroColor: _orange,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${steerAngle.round()}°',
          style: GoogleFonts.orbitron(
            color: steerAngle.abs() < 8 ? _orange : color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  // ── JOYSTICK ─────────────────────────────────────────────────
  Offset _joyOffset = Offset.zero;
  bool _joyDragging = false;
  static const double _joyRadius = 40.0;

  Widget _buildJoystick(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onPanStart: (_) {
            setState(() => _joyDragging = true);
          },
          onPanUpdate: (d) {
            setState(() {
              _joyOffset += d.delta;
              final dist = _joyOffset.distance;
              if (dist > _joyRadius) {
                _joyOffset = _joyOffset / dist * _joyRadius;
              }
            });
            _sendCommand(
                'JOY:${(_joyOffset.dx / _joyRadius * 100).toInt()}:${(-_joyOffset.dy / _joyRadius * 100).toInt()}');
          },
          onPanEnd: (_) {
            setState(() {
              _joyOffset = Offset.zero;
              _joyDragging = false;
            });
            _sendCommand('JOY:0:0');
          },
          child: SizedBox(
            width: 130,
            height: 130,
            child: CustomPaint(
              painter: _JoystickPainter(
                color: color,
                offset: _joyOffset,
                active: _joyDragging,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'X:${(_joyOffset.dx / _joyRadius * 100).toInt()}  Y:${(-_joyOffset.dy / _joyRadius * 100).toInt()}',
          style: GoogleFonts.orbitron(
              color: color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
      ],
    );
  }

  // ── D-PAD ────────────────────────────────────────────────────
  String _dpActive = '';

  Widget _buildDpad(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 132,
          height: 132,
          child: GridView.count(
            crossAxisCount: 3,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 3,
            crossAxisSpacing: 3,
            children: [
              const SizedBox.shrink(),
              _DpadCell(
                direction: 'FWD',
                active: _dpActive == 'FWD',
                color: color,
                child: CustomPaint(painter: _TrianglePainter(direction: 'up', color: color, active: _dpActive == 'FWD')),
                onDown: () { setState(() => _dpActive = 'FWD'); _sendCommand('FWD'); },
                onUp: () { setState(() => _dpActive = ''); },
              ),
              const SizedBox.shrink(),
              _DpadCell(
                direction: 'LEFT',
                active: _dpActive == 'LEFT',
                color: color,
                child: CustomPaint(painter: _TrianglePainter(direction: 'left', color: color, active: _dpActive == 'LEFT')),
                onDown: () { setState(() => _dpActive = 'LEFT'); _sendCommand('LEFT'); },
                onUp: () { setState(() => _dpActive = ''); },
              ),
              // center
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF141F2E),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withOpacity(0.4), width: 2),
                      color: color.withOpacity(0.1),
                    ),
                  ),
                ),
              ),
              _DpadCell(
                direction: 'RIGHT',
                active: _dpActive == 'RIGHT',
                color: color,
                child: CustomPaint(painter: _TrianglePainter(direction: 'right', color: color, active: _dpActive == 'RIGHT')),
                onDown: () { setState(() => _dpActive = 'RIGHT'); _sendCommand('RIGHT'); },
                onUp: () { setState(() => _dpActive = ''); },
              ),
              const SizedBox.shrink(),
              _DpadCell(
                direction: 'BCK',
                active: _dpActive == 'BCK',
                color: color,
                child: CustomPaint(painter: _TrianglePainter(direction: 'down', color: color, active: _dpActive == 'BCK')),
                onDown: () { setState(() => _dpActive = 'BCK'); _sendCommand('BCK'); },
                onUp: () { setState(() => _dpActive = ''); },
              ),
              const SizedBox.shrink(),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _dpActive.isEmpty ? '—' : _dpActive,
          style: GoogleFonts.orbitron(
              color: color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
      ],
    );
  }

  // ── GAUGE ────────────────────────────────────────────────────
  Widget _buildGauge(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 120,
          height: 72,
          child: CustomPaint(
            painter: _GaugePainter(value: _gaugeValue, color: color),
          ),
        ),
        Text(
          '${(_gaugeValue * 80).toInt()}',
          style: GoogleFonts.orbitron(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'RPM ×100',
          style: GoogleFonts.orbitron(
            color: const Color(0xFF3A6A88),
            fontSize: 8,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            activeTrackColor: color,
            inactiveTrackColor: _trackBg,
            thumbColor: color,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
          ),
          child: Slider(
            value: _gaugeValue,
            onChanged: (v) {
              _animateGaugeTo(v);
              _sendCommand('GAUGE:${(v * 100).toInt()}');
            },
          ),
        ),
      ],
    );
  }

  void _animateGaugeTo(double target) {
    _gaugeAnim = Tween<double>(begin: _gaugeValue, end: target).animate(
        CurvedAnimation(parent: _gaugeCtrl, curve: Curves.easeInOut));
    _gaugeAnim.addListener(() => setState(() => _gaugeValue = _gaugeAnim.value));
    _gaugeCtrl.forward(from: 0);
  }

  // ── VOLUME ───────────────────────────────────────────────────
  Widget _buildVolume(Color color) {
    final effectiveValue = isMuted ? 0.0 : sliderValue;
    IconData volIcon = isMuted
        ? Icons.volume_off_rounded
        : sliderValue > 0.5
            ? Icons.volume_up_rounded
            : Icons.volume_down_rounded;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            setState(() => isMuted = !isMuted);
            _sendCommand(isMuted ? 'MUTE' : 'UNMUTE');
          },
          child: Icon(volIcon,
              color: isMuted ? const Color(0xFF3A5068) : color, size: 30),
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: isMuted ? _cyanDim : color,
            inactiveTrackColor: _trackBg,
            thumbColor: isMuted ? _cyanDim : color,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayColor: color.withOpacity(0.15),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: sliderValue,
            onChanged: (v) {
              setState(() {
                sliderValue = v;
                isMuted = false;
              });
              _sendCommand('VOL:${(v * 100).toInt()}');
            },
          ),
        ),
        Text(
          isMuted ? 'MUTE' : '${(effectiveValue * 100).toInt()}%',
          style: GoogleFonts.orbitron(
            color: isMuted ? const Color(0xFF3A5068) : color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  // ── CONTROL ROUTER ───────────────────────────────────────────
  Widget _buildControl() {
    final type = widget.widgetData['type'];
    final color = Color(widget.widgetData['color'] as int);

    switch (type) {
      case 'toggle':
        return _buildToggle(color);
      case 'slider':
        return _buildSlider(color);
      case 'button':
        return _buildButton(color);
      case 'joystick':
        return _buildJoystick(color);
      case 'steering':
        return _buildSteering(color);
      case 'volume':
        return _buildVolume(color);
      case 'dpad':
        return _buildDpad(color);
      case 'gauge':
        return _buildGauge(color);
      default:
        return Icon(Icons.widgets, color: color, size: 40);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.widgetData['color'] as int);
    final label = widget.widgetData['label'] as String;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.editMode
              ? color.withOpacity(0.7)
              : color.withOpacity(0.2),
          width: widget.editMode ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.08), blurRadius: 10),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Stack(
        children: [
          // corner brackets
          ..._cornerBrackets(color),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.editMode ? widget.onRename : null,
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              label,
                              style: GoogleFonts.orbitron(
                                color: widget.editMode ? color : Colors.grey,
                                fontSize: 9,
                                letterSpacing: 1.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.editMode) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.edit, color: color, size: 10),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (widget.editMode)
                    GestureDetector(
                      onTap: widget.onDelete,
                      child: const Icon(Icons.close,
                          color: Color(0xFFFF5252), size: 14),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(child: Center(child: _buildControl())),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _cornerBrackets(Color color) {
    final c = color.withOpacity(0.35);
    const s = 7.0;
    const t = 1.0;
    return [
      Positioned(top: 4, left: 4,
          child: _Corner(color: c, size: s, t: t, top: true, left: true)),
      Positioned(top: 4, right: 4,
          child: _Corner(color: c, size: s, t: t, top: true, left: false)),
      Positioned(bottom: 4, left: 4,
          child: _Corner(color: c, size: s, t: t, top: false, left: true)),
      Positioned(bottom: 4, right: 4,
          child: _Corner(color: c, size: s, t: t, top: false, left: false)),
    ];
  }
}

// ── Corner bracket widget ────────────────────────────────────
class _Corner extends StatelessWidget {
  final Color color;
  final double size, t;
  final bool top, left;
  const _Corner({required this.color, required this.size, required this.t, required this.top, required this.left});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CornerPainter(color: color, t: t, top: top, left: left),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double t;
  final bool top, left;
  _CornerPainter({required this.color, required this.t, required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..strokeWidth = t..style = PaintingStyle.stroke;
    final x = left ? 0.0 : size.width;
    final y = top ? 0.0 : size.height;
    final x2 = left ? size.width : 0.0;
    final y2 = top ? size.height : 0.0;
    canvas.drawLine(Offset(x, y), Offset(x2, y), p);
    canvas.drawLine(Offset(x, y), Offset(x, y2), p);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}

// ── D-Pad cell ───────────────────────────────────────────────
class _DpadCell extends StatelessWidget {
  final String direction;
  final bool active;
  final Color color;
  final Widget child;
  final VoidCallback onDown, onUp;

  const _DpadCell({
    required this.direction,
    required this.active,
    required this.color,
    required this.child,
    required this.onDown,
    required this.onUp,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onDown(),
      onTapUp: (_) => onUp(),
      onTapCancel: onUp,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0A1E30) : const Color(0xFF0D1520),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active ? color : const Color(0xFF2A3F55),
            width: active ? 1.5 : 1,
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ── Triangle painter for D-pad ───────────────────────────────
class _TrianglePainter extends CustomPainter {
  final String direction;
  final Color color;
  final bool active;
  _TrianglePainter({required this.direction, required this.color, required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = active ? Color.lerp(color, Colors.white, 0.3)! : color
      ..style = PaintingStyle.fill;
    final cx = size.width / 2;
    final cy = size.height / 2;
    const w = 18.0, h = 28.0;
    final path = Path();
    switch (direction) {
      case 'up':
        path.moveTo(cx, cy - h / 2);
        path.lineTo(cx - w / 2, cy + h / 2);
        path.lineTo(cx + w / 2, cy + h / 2);
        break;
      case 'down':
        path.moveTo(cx, cy + h / 2);
        path.lineTo(cx - w / 2, cy - h / 2);
        path.lineTo(cx + w / 2, cy - h / 2);
        break;
      case 'left':
        path.moveTo(cx - h / 2, cy);
        path.lineTo(cx + h / 2, cy - w / 2);
        path.lineTo(cx + h / 2, cy + w / 2);
        break;
      case 'right':
        path.moveTo(cx + h / 2, cy);
        path.lineTo(cx - h / 2, cy - w / 2);
        path.lineTo(cx - h / 2, cy + w / 2);
        break;
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) =>
      old.active != active || old.color != color;
}

// ── Steering wheel painter ───────────────────────────────────
class _SteeringPainter extends CustomPainter {
  final Color color;
  final double angle;
  final Color zeroColor;
  _SteeringPainter({required this.color, required this.angle, required this.zeroColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 8;
    final ir = r * 0.22;

    // fixed zero triangle pointer at top
    final triPaint = Paint()..color = zeroColor..style = PaintingStyle.fill;
    final triPath = Path()
      ..moveTo(cx, cy - r - 7)
      ..lineTo(cx - 5, cy - r + 2)
      ..lineTo(cx + 5, cy - r + 2)
      ..close();
    canvas.drawPath(triPath, triPaint);

    // rotating wheel
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(angle * pi / 180);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // outer ring
    paint.color = color;
    paint.strokeWidth = 6;
    canvas.drawCircle(Offset.zero, r, paint);

    // inner hub
    paint.strokeWidth = 2.5;
    canvas.drawCircle(Offset.zero, ir, paint);

    // zero spoke (top) — orange
    paint.color = zeroColor;
    paint.strokeWidth = 3;
    canvas.drawLine(Offset(0, -ir), Offset(0, -r), paint);
    final dotPaint = Paint()..color = zeroColor..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(0, -r), 5, dotPaint);

    // other 3 spokes — cyan
    paint.color = color;
    paint.strokeWidth = 2.5;
    final spokes = [Offset(0, r), Offset(-r, 0), Offset(r, 0)];
    for (final s in spokes) {
      canvas.drawLine(
          Offset(s.dx * ir / r, s.dy * ir / r), s, paint);
    }
    final rimDot = Paint()..color = color..style = PaintingStyle.fill;
    for (final s in spokes) {
      canvas.drawCircle(s, 4, rimDot);
    }
    canvas.drawCircle(Offset.zero, 5, rimDot);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_SteeringPainter old) =>
      old.angle != angle || old.color != color;
}

// ── Joystick painter ─────────────────────────────────────────
class _JoystickPainter extends CustomPainter {
  final Color color;
  final Offset offset;
  final bool active;
  _JoystickPainter({required this.color, required this.offset, required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 4;

    // base circle
    final basePaint = Paint()
      ..color = _baseBg
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r, basePaint);
    final borderPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(cx, cy), r, borderPaint);

    // crosshair lines
    final linePaint = Paint()
      ..color = color.withOpacity(0.07)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(cx, cy - r + 4), Offset(cx, cy + r - 4), linePaint);
    canvas.drawLine(Offset(cx - r + 4, cy), Offset(cx + r - 4, cy), linePaint);

    // dashed rings
    final dashPaint = Paint()
      ..color = color.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(cx, cy), r * 0.52, dashPaint);
    canvas.drawCircle(Offset(cx, cy), r * 0.85, dashPaint);

    // cardinal dots
    final dotPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    for (final pt in [
      Offset(cx, cy - r + 4), Offset(cx, cy + r - 4),
      Offset(cx - r + 4, cy), Offset(cx + r - 4, cy),
    ]) {
      canvas.drawCircle(pt, 2.5, dotPaint);
    }

    // thumb
    final tx = cx + offset.dx;
    final ty = cy + offset.dy;
    final thumbBg = Paint()..color = const Color(0xFF0D1F30)..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(tx, ty), 25, thumbBg);
    final thumbBorder = Paint()
      ..color = active ? color.withOpacity(0.9) : color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(tx, ty), 25, thumbBorder);
    // inner dot
    final innerDot = Paint()
      ..color = color.withOpacity(active ? 0.6 : 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(tx, ty), 8, innerDot);
  }

  @override
  bool shouldRepaint(_JoystickPainter old) =>
      old.offset != offset || old.active != active || old.color != color;
}

// ── Gauge painter ─────────────────────────────────────────────
class _GaugePainter extends CustomPainter {
  final double value; // 0.0 – 1.0
  final Color color;
  _GaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height - 4;
    final r = size.width / 2 - 6;
    const startAngle = pi * 0.75;
    const sweepAngle = pi * 1.5;

    // track
    final trackPaint = Paint()
      ..color = _trackBg
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      startAngle, sweepAngle, false, trackPaint,
    );

    // fill
    if (value > 0) {
      final fillPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        startAngle, sweepAngle * value, false, fillPaint,
      );
    }

    // needle
    final needleAngle = startAngle + sweepAngle * value;
    final nx = cx + cos(needleAngle) * r * 0.72;
    final ny = cy + sin(needleAngle) * r * 0.72;
    final needlePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, cy), Offset(nx, ny), needlePaint);

    // center dot
    canvas.drawCircle(Offset(cx, cy), 4,
        Paint()..color = color..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value || old.color != color;
}