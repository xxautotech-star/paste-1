import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/device_state.dart';
import '../services/mqtt_service.dart';
import 'dart:async';

const _cyan = Color(0xFF00D4FF);
const _cyanDim = Color(0xFF2A3F55);
const _cardBg = Color(0xFF111827);
const _trackBg = Color(0xFF1E2A3A);
const _baseBg = Color(0xFF0D1520);

class CanvasWidget extends StatefulWidget {
  final dynamic widgetData;
  final String mqttTopic;
  final String deviceId;
  final bool editMode;
  final int widgetTypeIndex;
  final int widgetIndex;
  final String mqttDeviceId;
  final int widgetTypeTotal;
  final Function(double, double) onMove;
  final VoidCallback onDelete;
  final VoidCallback onRename;
  final VoidCallback onToggleLabel;

  const CanvasWidget({
    super.key,
    required this.widgetData,
    required this.mqttTopic,
    required this.deviceId,
    required this.editMode,
    required this.widgetTypeIndex,
    required this.widgetTypeTotal,
    required this.widgetIndex,
    required this.mqttDeviceId,
    required this.onMove,
    required this.onDelete,
    required this.onRename,
    required this.onToggleLabel,
  });

  @override
  State<CanvasWidget> createState() => _CanvasWidgetState();
}


class _CanvasWidgetState extends State<CanvasWidget>
    with TickerProviderStateMixin {
  bool toggleValue = false;
  double sliderValue = 0.5;
  bool isMuted = false;
  double steerAngle = 0;
  late AnimationController _steerReturnCtrl;
  late Animation<double> _steerReturnAnim;
  double _gaugeValue = 0;
  late AnimationController _gaugeCtrl;
  late Animation<double> _gaugeAnim;
  late AnimationController _btnFlashCtrl;

  String get _ownSuffix =>
      widget.widgetTypeIndex > 1 ? '_${widget.widgetTypeIndex}' : '';
  String get _powerKey =>
      widget.widgetTypeIndex > 1
          ? '${widget.mqttTopic}_${widget.widgetTypeIndex}'
          : widget.mqttTopic;

  Map<String, dynamic> get _savedState =>
      widget.widgetData['state'] is Map
          ? Map<String, dynamic>.from(widget.widgetData['state'])
          : <String, dynamic>{};

  void _saveState(Map<String, dynamic> state) {
    ApiService.saveWidgetState(widget.deviceId, widget.widgetIndex, state);
  }

  @override
  void initState() {
    super.initState();
    final _s = _savedState;
    toggleValue = (_s['on'] as bool?) ?? DevicePowerState.get(_powerKey);
    sliderValue = (_s['value'] as num?)?.toDouble() ?? 0.5;
    isMuted = (_s['muted'] as bool?) ?? false;
    _lightsOn = (_s['on'] as bool?) ?? false;
    _alarmOn = (_s['on'] as bool?) ?? false;
    _fanSpeed = (_s['value'] as num?)?.toDouble() ?? 0.0;
    _currentGear = (_s['gear'] as String?) ?? 'N';
    _toggle2Value = (_s['on2'] as bool?) ?? false;
    _doorLocked = (_s['locked'] as bool?) ?? true;
    _servoAngle = (_s['angle'] as num?)?.toDouble() ?? 90.0;
    _shoulderAngle = (_s['shoulder'] as num?)?.toDouble() ?? 90.0;
    _elbowAngle = (_s['elbow'] as num?)?.toDouble() ?? 90.0;
    _wristAngle = (_s['wrist'] as num?)?.toDouble() ?? 90.0;
    if (_s['r'] != null && _s['g'] != null && _s['b'] != null) {
      _rgbColor = Color.fromARGB(255, _s['r'] as int, _s['g'] as int, _s['b'] as int);
    }

    DevicePowerState.notifier.addListener(_onPowerStateChange);

    MqttService().onMessage.listen((data) {
      if (!mounted) return;
      final topic = data['topic'];
      final command = data['command'];
      final sensorData = data['data'];

      if (sensorData != null && topic == widget.mqttDeviceId) {
        if (sensorData.startsWith('BAR$_ownSuffix=')) {
          final val = double.tryParse(sensorData.substring(4 + _ownSuffix.length)) ?? 0.0;
          setState(() {
            _barData.removeAt(0);
            _barData.add(val.clamp(0.0, 1.0));
          });
        }
        if (sensorData.startsWith('TBL$_ownSuffix=')) {
          final payload = sensorData.substring(4 + _ownSuffix.length);
          setState(() {
            for (final pair in payload.split(';')) {
              final kv = pair.split(':');
              if (kv.length == 2) _tableRows[kv[0]] = kv[1];
            }
          });
        }
        if (sensorData.startsWith('GRAPH=')) {
          final val = double.tryParse(sensorData.substring(6)) ?? 0.0;
          setState(() {
            _graphLatest = val;
            _graphData.removeAt(0);
            _graphData.add((val / 100).clamp(0.0, 1.0));
          });
        }
      }

      if (topic == widget.mqttTopic && command != null) {
        final type = widget.widgetData['type'] as String;
        if (type == 'toggle' &&
            (command == 'ON$_ownSuffix' || command == 'OFF$_ownSuffix')) {
          final newVal = command == 'ON$_ownSuffix';
          setState(() => toggleValue = newVal);
          DevicePowerState.set(_powerKey, newVal);
        }
        if (type == 'graph' && command.startsWith('GRAPH$_ownSuffix:')) {
          final val =
              double.tryParse(command.substring(6 + _ownSuffix.length)) ?? 0.0;
          setState(() {
            _graphLatest = val;
            _graphData.removeAt(0);
            _graphData.add((val / 4095).clamp(0.0, 1.0));
          });
        }
      }
    });

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

  void _onPowerStateChange() {
    if (mounted) {
      setState(() {
        toggleValue = DevicePowerState.get(_powerKey);
      });
    }
  }

  @override
  void dispose() {
    DevicePowerState.notifier.removeListener(_onPowerStateChange);
    _steerReturnCtrl.dispose();
    _gaugeCtrl.dispose();
    _btnFlashCtrl.dispose();
    _swTimer?.cancel();
    _cdTimer?.cancel();
    super.dispose();
  }

  void _sendCommand(String command) async {
    final idx = widget.widgetTypeIndex;
    final type = widget.widgetData['type'] as String;
    final needsIndex = ['joystick','dpad','steering','toggle','button',
        'slider','horn','brake','accelerator','gearshift','headlights','turbo',
        'volume','gauge','rgb','fanspeed','alarm','irblast','stopwatch',
        'clutch','pedalset','countdown','toggle2','doorlock','servo',
        'start','stop','chup','chdown','volup','voldown','muteonly','robotarm'];
    final indexedCommand = needsIndex.contains(type) && widget.widgetTypeTotal > 1
        ? command.contains(':') ? command.replaceFirst(':', '_$idx:') : '${command}_$idx'
        : command;
    try {
      final result = await ApiService.sendCommand(widget.mqttTopic, indexedCommand);
      debugPrint('Sent via API: $command → $result');
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  // Bold, flat slider style: thick rounded track, big flat thumb, no ripple.
  SliderThemeData _boldSlider(Color color,
      {double trackHeight = 14, double thumbRadius = 15}) {
    return SliderTheme.of(context).copyWith(
      trackHeight: trackHeight,
      activeTrackColor: color,
      inactiveTrackColor: _trackBg,
      thumbColor: color,
      trackShape: const RoundedRectSliderTrackShape(),
      thumbShape: RoundSliderThumbShape(
          enabledThumbRadius: thumbRadius, elevation: 0, pressedElevation: 0),
      overlayShape: SliderComponentShape.noOverlay,
    );
  }

  Widget _buildToggle(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            final newVal = !toggleValue;
            setState(() => toggleValue = newVal);
            DevicePowerState.set(widget.mqttTopic, newVal);
            _sendCommand(newVal ? 'ON' : 'OFF');
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
              boxShadow: toggleValue
                  ? [BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 1)]
                  : [],
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
                          ? [BoxShadow(
                              color: color.withValues(alpha: 0.7),
                              blurRadius: 10,
                              spreadRadius: 1)]
                          : [],
                    ),
                    child: Center(
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white
                              .withValues(alpha: toggleValue ? 0.6 : 0.15),
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
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: toggleValue ? color : _cyanDim,
            boxShadow: toggleValue
                ? [BoxShadow(
                    color: color.withValues(alpha: 0.8),
                    blurRadius: 8,
                    spreadRadius: 1)]
                : [],
          ),
        ),
      ],
    );
  }

  Widget _buildSlider(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SliderTheme(
          data: _boldSlider(color),
          child: Slider(
            value: sliderValue,
            onChanged: (v) {
              setState(() => sliderValue = v);
              _sendCommand('SLIDER:${(v * 100).toInt()}');
              _saveState({'value': v});
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

  Widget _buildButton(Color color) {
    return GestureDetector(
      onTapDown: (_) {
        _btnFlashCtrl.forward(from: 0);
        _sendCommand('PRESS');
        setState(() {});
      },
      onTapUp: (_) => setState(() {}),
      onTapCancel: () => setState(() {}),
      child: AnimatedBuilder(
        animation: _btnFlashCtrl,
        builder: (_, _) {
          final pressed = _btnFlashCtrl.isAnimating;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pressed ? color : _baseBg,
              border: Border.all(color: color, width: 2),
              boxShadow: pressed
                  ? [BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 20, spreadRadius: 3)]
                  : [],
            ),
            child: Icon(
              Icons.power_settings_new_rounded,
              color: pressed ? Colors.white : color,
              size: 42,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSteering(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onPanStart: (_) => _steerReturnCtrl.stop(),
          onPanUpdate: (d) {
            setState(() {
              steerAngle =
                  (steerAngle + d.delta.dx * 1.5).clamp(-135.0, 135.0);
            });
            _sendCommand('STEER:${steerAngle.toInt()}');
          },
          onPanEnd: (_) {
            _steerReturnAnim = Tween<double>(begin: steerAngle, end: 0)
                .animate(CurvedAnimation(
                    parent: _steerReturnCtrl, curve: Curves.easeOut));
            _steerReturnAnim.addListener(() {
              setState(() => steerAngle = _steerReturnAnim.value);
            });
            _steerReturnCtrl.forward(from: 0);
          },
          child: SizedBox(
            width: 120,
            height: 120,
            child: CustomPaint(
              painter:
                  _SteeringPainter(color: color, angle: steerAngle),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${steerAngle.round()}°',
          style: GoogleFonts.orbitron(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 2),
        ),
      ],
    );
  }

  Offset _joyOffset = Offset.zero;
  bool _joyDragging = false;
  static const double _joyRadius = 40.0;

  Widget _buildJoystick(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onPanStart: (_) => setState(() => _joyDragging = true),
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
                  active: _joyDragging),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'X:${(_joyOffset.dx / _joyRadius * 100).toInt()}  Y:${(-_joyOffset.dy / _joyRadius * 100).toInt()}',
          style: GoogleFonts.orbitron(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5),
        ),
      ],
    );
  }

  String _dpActive = '';

  Widget _buildDpad(Color color) {
    return ClipRect(
      child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 122,
          height: 122,
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
                child: CustomPaint(
                    painter: _TrianglePainter(
                        direction: 'up',
                        color: color,
                        active: _dpActive == 'FWD')),
                onDown: () {
                  setState(() => _dpActive = 'FWD');
                  _sendCommand('FWD');
                },
                onUp: () => setState(() => _dpActive = ''),
              ),
              const SizedBox.shrink(),
              _DpadCell(
                direction: 'LEFT',
                active: _dpActive == 'LEFT',
                color: color,
                child: CustomPaint(
                    painter: _TrianglePainter(
                        direction: 'left',
                        color: color,
                        active: _dpActive == 'LEFT')),
                onDown: () {
                  setState(() => _dpActive = 'LEFT');
                  _sendCommand('LEFT');
                },
                onUp: () => setState(() => _dpActive = ''),
              ),
              Container(
                decoration: BoxDecoration(
                    color: const Color(0xFF141F2E),
                    borderRadius: BorderRadius.circular(6)),
                child: Center(
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: color.withValues(alpha: 0.5), width: 2),
                      color: color.withValues(alpha: 0.15),
                      boxShadow: [
                        BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 8)
                      ],
                    ),
                  ),
                ),
              ),
              _DpadCell(
                direction: 'RIGHT',
                active: _dpActive == 'RIGHT',
                color: color,
                child: CustomPaint(
                    painter: _TrianglePainter(
                        direction: 'right',
                        color: color,
                        active: _dpActive == 'RIGHT')),
                onDown: () {
                  setState(() => _dpActive = 'RIGHT');
                  _sendCommand('RIGHT');
                },
                onUp: () => setState(() => _dpActive = ''),
              ),
              const SizedBox.shrink(),
              _DpadCell(
                direction: 'BCK',
                active: _dpActive == 'BCK',
                color: color,
                child: CustomPaint(
                    painter: _TrianglePainter(
                        direction: 'down',
                        color: color,
                        active: _dpActive == 'BCK')),
                onDown: () {
                  setState(() => _dpActive = 'BCK');
                  _sendCommand('BCK');
                },
                onUp: () => setState(() => _dpActive = ''),
              ),
              const SizedBox.shrink(),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _dpActive.isEmpty ? '—' : _dpActive,
          style: GoogleFonts.orbitron(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 2),
        ),
      ],
    ),
    );
  }

  Widget _buildGauge(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 120,
          height: 72,
          child: CustomPaint(
              painter:
                  _GaugePainter(value: _gaugeValue, color: color)),
        ),
        Text('${(_gaugeValue * 80).toInt()}',
            style: GoogleFonts.orbitron(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        Text('RPM ×100',
            style: GoogleFonts.orbitron(
                color: color.withValues(alpha: 0.4),
                fontSize: 8,
                letterSpacing: 2)),
        const SizedBox(height: 8),
        SliderTheme(
          data: _boldSlider(color, trackHeight: 10, thumbRadius: 11),
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
    _gaugeAnim.addListener(
        () => setState(() => _gaugeValue = _gaugeAnim.value));
    _gaugeCtrl.forward(from: 0);
  }

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
            _saveState({'value': sliderValue, 'muted': isMuted});
          },
          child: Icon(volIcon,
              color: isMuted ? _cyanDim : color, size: 30),
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: _boldSlider(isMuted ? _cyanDim : color),
          child: Slider(
            value: sliderValue,
            onChanged: (v) {
              setState(() {
                sliderValue = v;
                isMuted = false;
              });
              _sendCommand('VOL:${(v * 100).toInt()}');
              _saveState({'value': v, 'muted': false});
            },
          ),
        ),
        Text(
          isMuted ? 'MUTE' : '${(effectiveValue * 100).toInt()}%',
          style: GoogleFonts.orbitron(
            color: isMuted ? _cyanDim : color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
  Widget _buildHorn(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTapDown: (_) {
            _btnFlashCtrl.forward(from: 0);
            _sendCommand('HORN');
            setState(() {});
          },
          onTapUp: (_) => setState(() {}),
          child: AnimatedBuilder(
            animation: _btnFlashCtrl,
            builder: (_, _) {
              final pressed = _btnFlashCtrl.isAnimating;
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: pressed ? color.withValues(alpha: 0.2) : _baseBg,
                  border: Border.all(color: color, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                        color: color.withValues(alpha: pressed ? 0.8 : 0.3),
                        blurRadius: pressed ? 24 : 10,
                        spreadRadius: pressed ? 4 : 1),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.volume_up_rounded, color: color, size: 30),
                    Text('HORN',
                        style: GoogleFonts.orbitron(
                            color: color, fontSize: 7, letterSpacing: 2)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  bool _brakeHeld = false;

  Widget _buildBrake(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTapDown: (_) {
            setState(() => _brakeHeld = true);
            _sendCommand('BRAKE:ON');
          },
          onTapUp: (_) {
            setState(() => _brakeHeld = false);
            _sendCommand('BRAKE:OFF');
          },
          onTapCancel: () {
            setState(() => _brakeHeld = false);
            _sendCommand('BRAKE:OFF');
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 80,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.transparent,
              boxShadow: _brakeHeld
                  ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 20, spreadRadius: 2)]
                  : [],
            ),
            child: CustomPaint(
              painter: _PedalIconPainter(color: color, pressed: _brakeHeld),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text('BRAKE',
            style: GoogleFonts.orbitron(
                color: color, fontSize: 7, letterSpacing: 2)),
        Text(_brakeHeld ? 'ENGAGED' : 'RELEASED',
            style: GoogleFonts.orbitron(
                color: color.withValues(alpha: _brakeHeld ? 1 : 0.4),
                fontSize: 8,
                letterSpacing: 2)),
      ],
    );
  }

  bool _clutchHeld = false;

  Widget _buildClutch(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTapDown: (_) {
            setState(() => _clutchHeld = true);
            _sendCommand('CLUTCH:ON');
          },
          onTapUp: (_) {
            setState(() => _clutchHeld = false);
            _sendCommand('CLUTCH:OFF');
          },
          onTapCancel: () {
            setState(() => _clutchHeld = false);
            _sendCommand('CLUTCH:OFF');
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 80,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.transparent,
              boxShadow: _clutchHeld
                  ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 20, spreadRadius: 2)]
                  : [],
            ),
            child: CustomPaint(
              painter: _PedalIconPainter(color: color, pressed: _clutchHeld),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text('CLUTCH',
            style: GoogleFonts.orbitron(
                color: color, fontSize: 7, letterSpacing: 2)),
        Text(_clutchHeld ? 'ENGAGED' : 'RELEASED',
            style: GoogleFonts.orbitron(
                color: color.withValues(alpha: _clutchHeld ? 1 : 0.4),
                fontSize: 8,
                letterSpacing: 2)),
      ],
    );
  }

  bool _psClutchHeld = false;
  bool _psBrakeHeld = false;
  bool _psAccelHeld = false;

  Widget _buildPedalSet(Color color) {
    Widget pedal(String label, bool held, VoidCallback onDown, VoidCallback onUp) {
      return GestureDetector(
        onTapDown: (_) => onDown(),
        onTapUp: (_) => onUp(),
        onTapCancel: onUp,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 46,
              height: 60,
              child: CustomPaint(
                painter: _PedalIconPainter(color: color, pressed: held),
              ),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.orbitron(
                    color: color.withValues(alpha: held ? 1 : 0.6),
                    fontSize: 6,
                    letterSpacing: 1)),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Shared bar the pedals hang from.
        Container(
          width: 160,
          height: 5,
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(3),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 6)],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            pedal('CLUTCH', _psClutchHeld, () {
              setState(() => _psClutchHeld = true);
              _sendCommand('CLUTCH:ON');
            }, () {
              setState(() => _psClutchHeld = false);
              _sendCommand('CLUTCH:OFF');
            }),
            pedal('BRAKE', _psBrakeHeld, () {
              setState(() => _psBrakeHeld = true);
              _sendCommand('BRAKE:ON');
            }, () {
              setState(() => _psBrakeHeld = false);
              _sendCommand('BRAKE:OFF');
            }),
            pedal('ACCEL', _psAccelHeld, () {
              setState(() => _psAccelHeld = true);
              _sendCommand('ACCEL:100');
            }, () {
              setState(() => _psAccelHeld = false);
              _sendCommand('ACCEL:0');
            }),
          ],
        ),
      ],
    );
  }

  double _accelValue = 0.0;

  Widget _buildAccelerator(Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RotatedBox(
          quarterTurns: 3,
          child: SliderTheme(
            data: _boldSlider(color, trackHeight: 12, thumbRadius: 13),
            child: Slider(
              value: _accelValue,
              onChanged: (v) {
                setState(() => _accelValue = v);
                _sendCommand('ACCEL:${(v * 100).toInt()}');
              },
              onChangeEnd: (v) {
                setState(() => _accelValue = 0.0);
                _sendCommand('ACCEL:0');
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_upward_rounded, color: color, size: 20),
            const SizedBox(height: 4),
            Text('${(_accelValue * 100).toInt()}%',
                style: GoogleFonts.orbitron(
                    color: color, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('ACCEL',
                style: GoogleFonts.orbitron(
                    color: color.withValues(alpha: 0.5), fontSize: 7, letterSpacing: 2)),
          ],
        ),
      ],
    );
  }

  String _currentGear = 'N';

  Widget _buildGearShift(Color color) {
    final gears = ['R', 'N', '1', '2', '3', '4'];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('GEAR',
            style: GoogleFonts.orbitron(
                color: color.withValues(alpha: 0.5), fontSize: 8, letterSpacing: 2)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: gears.map((g) {
            final active = _currentGear == g;
            return GestureDetector(
              onTap: () {
                setState(() => _currentGear = g);
                _sendCommand('GEAR:$g');
                _saveState({'gear': g});
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: active ? color.withValues(alpha: 0.2) : _baseBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: active ? color : _cyanDim, width: active ? 2 : 1),
                  boxShadow: active
                      ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10)]
                      : [],
                ),
                child: Center(
                  child: Text(g,
                      style: GoogleFonts.orbitron(
                          color: active ? color : Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        Text(_currentGear == 'N'
            ? 'NEUTRAL'
            : _currentGear == 'R'
                ? 'REVERSE'
                : 'DRIVE $_currentGear',
            style: GoogleFonts.orbitron(
                color: color, fontSize: 8, letterSpacing: 1)),
      ],
    );
  }

  bool _lightsOn = false;

  Widget _buildHeadlights(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            setState(() => _lightsOn = !_lightsOn);
            _sendCommand(_lightsOn ? 'LIGHTS:ON' : 'LIGHTS:OFF');
            _saveState({'on': _lightsOn});
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _lightsOn ? color.withValues(alpha: 0.15) : _baseBg,
              border: Border.all(
                  color: _lightsOn ? color : _cyanDim, width: 2),
              boxShadow: _lightsOn
                  ? [
                      BoxShadow(
                          color: color.withValues(alpha: 0.6),
                          blurRadius: 30,
                          spreadRadius: 6),
                    ]
                  : [],
            ),
            child: Icon(
              _lightsOn ? Icons.lightbulb : Icons.lightbulb_outline,
              color: _lightsOn ? color : _cyanDim,
              size: 36,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(_lightsOn ? 'ON' : 'OFF',
            style: GoogleFonts.orbitron(
                color: _lightsOn ? color : _cyanDim,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
      ],
    );
  }

  bool _turboActive = false;

  Widget _buildTurbo(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTapDown: (_) {
            setState(() => _turboActive = true);
            _btnFlashCtrl.repeat();
            _sendCommand('TURBO:ON');
          },
          onTapUp: (_) {
            setState(() => _turboActive = false);
            _btnFlashCtrl.stop();
            _btnFlashCtrl.reset();
            _sendCommand('TURBO:OFF');
          },
          onTapCancel: () {
            setState(() => _turboActive = false);
            _btnFlashCtrl.stop();
            _btnFlashCtrl.reset();
            _sendCommand('TURBO:OFF');
          },
          child: AnimatedBuilder(
            animation: _btnFlashCtrl,
            builder: (_, _) => AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _turboActive ? color.withValues(alpha: 0.2) : _baseBg,
                border: Border.all(color: color, width: 2.5),
                boxShadow: [
                  BoxShadow(
                      color: color.withValues(alpha: _turboActive ? 0.9 : 0.3),
                      blurRadius: _turboActive ? 30 : 10,
                      spreadRadius: _turboActive ? 6 : 1),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bolt_rounded, color: color, size: 34),
                  Text('TURBO',
                      style: GoogleFonts.orbitron(
                          color: color, fontSize: 7, letterSpacing: 2)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(_turboActive ? '⚡ BOOST ACTIVE' : 'HOLD TO BOOST',
            style: GoogleFonts.orbitron(
                color: _turboActive ? color : color.withValues(alpha: 0.4),
                fontSize: 7,
                letterSpacing: 1)),
      ],
    );
  }
  Color _rgbColor = const Color(0xFFFF0000);

  Widget _buildRgb(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _rgbColor,
            boxShadow: [BoxShadow(color: _rgbColor.withValues(alpha: 0.6), blurRadius: 20, spreadRadius: 4)],
            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _rgbSlider('R', Colors.red, _rgbColor.red, (v) {
              setState(() => _rgbColor = Color.fromARGB(255, v.toInt(), _rgbColor.green, _rgbColor.blue));
              _sendCommand('RGB:${_rgbColor.red},${_rgbColor.green},${_rgbColor.blue}');
              _saveState({'r': _rgbColor.red, 'g': _rgbColor.green, 'b': _rgbColor.blue});
            }),
            const SizedBox(width: 4),
            _rgbSlider('G', Colors.green, _rgbColor.green, (v) {
              setState(() => _rgbColor = Color.fromARGB(255, _rgbColor.red, v.toInt(), _rgbColor.blue));
              _sendCommand('RGB:${_rgbColor.red},${_rgbColor.green},${_rgbColor.blue}');
              _saveState({'r': _rgbColor.red, 'g': _rgbColor.green, 'b': _rgbColor.blue});
            }),
            const SizedBox(width: 4),
            _rgbSlider('B', Colors.blue, _rgbColor.blue, (v) {
              setState(() => _rgbColor = Color.fromARGB(255, _rgbColor.red, _rgbColor.green, v.toInt()));
              _sendCommand('RGB:${_rgbColor.red},${_rgbColor.green},${_rgbColor.blue}');
              _saveState({'r': _rgbColor.red, 'g': _rgbColor.green, 'b': _rgbColor.blue});
            }),
          ],
        ),
      ],
    );
  }

  Widget _rgbSlider(String label, Color c, int value, Function(double) onChanged) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: GoogleFonts.orbitron(color: c, fontSize: 8)),
        RotatedBox(
          quarterTurns: 3,
          child: SizedBox(
            width: 80,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 8,
                activeTrackColor: c,
                inactiveTrackColor: c.withValues(alpha: 0.2),
                thumbColor: c,
                trackShape: const RoundedRectSliderTrackShape(),
                thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 9, elevation: 0, pressedElevation: 0),
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(value: value.toDouble(), min: 0, max: 255, onChanged: onChanged),
            ),
          ),
        ),
        Text('$value', style: GoogleFonts.orbitron(color: c, fontSize: 7)),
      ],
    );
  }

  double _fanSpeed = 0.0;

  Widget _buildFanSpeed(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: _fanSpeed,
                backgroundColor: _trackBg,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeWidth: 6,
              ),
            ),
            Icon(Icons.air, color: color, size: 30),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: _boldSlider(color),
          child: Slider(
            value: _fanSpeed,
            onChanged: (v) {
              setState(() => _fanSpeed = v);
              _sendCommand('FAN:${(v * 100).toInt()}');
              _saveState({'value': v});
            },
          ),
        ),
        Text('${(_fanSpeed * 100).toInt()}%',
            style: GoogleFonts.orbitron(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        Text('FAN SPEED', style: GoogleFonts.orbitron(color: color.withValues(alpha: 0.4), fontSize: 7, letterSpacing: 2)),
      ],
    );
  }

  final List<double> _graphData = List.filled(20, 0.0);
  double _graphLatest = 0.0;

  Widget _buildGraph(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 80,
          child: CustomPaint(
            painter: _GraphPainter(data: _graphData, color: color),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('LIVE',
                style: GoogleFonts.orbitron(color: color, fontSize: 8, letterSpacing: 2)),
            const SizedBox(width: 8),
            Text(_graphLatest.toStringAsFixed(1),
                style: GoogleFonts.orbitron(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        Text('SENSOR VALUE',
            style: GoogleFonts.orbitron(color: color.withValues(alpha: 0.4), fontSize: 7, letterSpacing: 2)),
      ],
    );
  }

  bool _alarmOn = false;

  Widget _buildAlarm(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            setState(() => _alarmOn = !_alarmOn);
            _sendCommand(_alarmOn ? 'ALARM:ON' : 'ALARM:OFF');
            _saveState({'on': _alarmOn});
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _alarmOn ? color.withValues(alpha: 0.2) : _baseBg,
              border: Border.all(color: _alarmOn ? color : _cyanDim, width: 2.5),
              boxShadow: _alarmOn
                  ? [BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 24, spreadRadius: 6)]
                  : [],
            ),
            child: Icon(
              _alarmOn ? Icons.notifications_active : Icons.notifications_off_outlined,
              color: _alarmOn ? color : _cyanDim,
              size: 34,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(_alarmOn ? 'ALARM ON' : 'ALARM OFF',
            style: GoogleFonts.orbitron(
                color: _alarmOn ? color : _cyanDim,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
      ],
    );
  }

  
  String _lastIr = '';

  Widget _irBtn(Color color, String code, IconData icon, {double size = 40}) {
    final active = _lastIr == code;
    return GestureDetector(
      onTap: () {
        setState(() => _lastIr = code);
        _sendCommand('IR:$code');
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) setState(() => _lastIr = '');
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? color.withValues(alpha: 0.3) : _baseBg,
          border: Border.all(color: active ? color : _cyanDim, width: active ? 2 : 1),
          boxShadow: active
              ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 12)]
              : [],
        ),
        child: Icon(icon, color: active ? Colors.white : color, size: size * 0.45),
      ),
    );
  }

  Widget _buildIrBlast(Color color) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _irBtn(color, 'HOME', Icons.home_rounded, size: 34),
              _irBtn(color, 'PWR', Icons.power_settings_new_rounded, size: 34),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 16,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _lastIr.isEmpty ? '' : _lastIr,
                key: ValueKey(_lastIr),
                style: GoogleFonts.orbitron(
                    color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _irBtn(color, 'UP', Icons.keyboard_arrow_up_rounded, size: 38),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _irBtn(color, 'LEFT', Icons.keyboard_arrow_left_rounded, size: 38),
              const SizedBox(width: 6),
              _irBtn(color, 'OK', Icons.circle, size: 34),
              const SizedBox(width: 6),
              _irBtn(color, 'RIGHT', Icons.keyboard_arrow_right_rounded, size: 38),
            ],
          ),
          const SizedBox(height: 4),
          _irBtn(color, 'DOWN', Icons.keyboard_arrow_down_rounded, size: 38),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _irBtn(color, 'REW', Icons.fast_rewind_rounded, size: 32),
              _irBtn(color, 'PLAY', Icons.play_arrow_rounded, size: 32),
              _irBtn(color, 'PAUSE', Icons.pause_rounded, size: 32),
              _irBtn(color, 'FF', Icons.fast_forward_rounded, size: 32),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _irBtn(color, 'VOL-', Icons.volume_down_rounded, size: 32),
              _irBtn(color, 'MUTE', Icons.volume_off_rounded, size: 32),
              _irBtn(color, 'KEYBOARD', Icons.keyboard_rounded, size: 32),
              _irBtn(color, 'VOL+', Icons.volume_up_rounded, size: 32),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _irBtn(color, 'BACK', Icons.reply_rounded, size: 32),
            ],
          ),
        ],
      ),
    );
  }
 

  bool _swRunning = false;
  Duration _swElapsed = Duration.zero;
  DateTime? _swStart;
  Timer? _swTimer;

  Widget _buildStopwatch(Color color) {
    final ms = _swElapsed.inMilliseconds;
    final mins = (ms ~/ 60000).toString().padLeft(2, '0');
    final secs = ((ms ~/ 1000) % 60).toString().padLeft(2, '0');
    final cents = ((ms ~/ 10) % 100).toString().padLeft(2, '0');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$mins:$secs.$cents',
            style: GoogleFonts.orbitron(
                color: color, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                if (_swRunning) {
                  _swTimer?.cancel();
                  setState(() {
                    _swRunning = false;
                    _swElapsed += DateTime.now().difference(_swStart!);
                  });
                  _sendCommand('STOPWATCH:STOP');
                } else {
                  _swStart = DateTime.now();
                  _swTimer = Timer.periodic(const Duration(milliseconds: 10), (_) {
                    if (mounted) setState(() {});
                  });
                  setState(() => _swRunning = true);
                  _sendCommand('STOPWATCH:START');
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                ),
                child: Text(_swRunning ? 'STOP' : 'START',
                    style: GoogleFonts.orbitron(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                _swTimer?.cancel();
                setState(() {
                  _swRunning = false;
                  _swElapsed = Duration.zero;
                  _swStart = null;
                });
                _sendCommand('STOPWATCH:RESET');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _cyanDim.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _cyanDim),
                ),
                child: Text('RESET',
                    style: GoogleFonts.orbitron(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  int _cdTotalSeconds = 60;
  int _cdRemainingSeconds = 60;
  bool _cdRunning = false;
  Timer? _cdTimer;

  void _cdAdjust(int deltaSeconds) {
    if (_cdRunning) return;
    setState(() {
      _cdTotalSeconds = (_cdTotalSeconds + deltaSeconds).clamp(10, 3600);
      _cdRemainingSeconds = _cdTotalSeconds;
    });
  }

  void _cdToggle() {
    if (_cdRunning) {
      _cdTimer?.cancel();
      setState(() => _cdRunning = false);
      _sendCommand('COUNTDOWN:PAUSE');
    } else {
      if (_cdRemainingSeconds <= 0) _cdRemainingSeconds = _cdTotalSeconds;
      setState(() => _cdRunning = true);
      _sendCommand('COUNTDOWN:START');
      _cdTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _cdRemainingSeconds--;
          if (_cdRemainingSeconds <= 0) {
            _cdRemainingSeconds = 0;
            _cdRunning = false;
            _cdTimer?.cancel();
            _sendCommand('COUNTDOWN:DONE');
          }
        });
      });
    }
  }

  void _cdReset() {
    _cdTimer?.cancel();
    setState(() {
      _cdRunning = false;
      _cdRemainingSeconds = _cdTotalSeconds;
    });
    _sendCommand('COUNTDOWN:RESET');
  }

  Widget _buildCountdown(Color color) {
    final mins = (_cdRemainingSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_cdRemainingSeconds % 60).toString().padLeft(2, '0');
    final done = _cdRemainingSeconds <= 0 && !_cdRunning && _cdTotalSeconds > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$mins:$secs',
            style: GoogleFonts.orbitron(
                color: done ? const Color(0xFFFF5252) : color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => _cdAdjust(-30),
              child: Icon(Icons.remove_circle_outline, color: color.withValues(alpha: 0.7), size: 18),
            ),
            const SizedBox(width: 10),
            Text('SET: ${(_cdTotalSeconds ~/ 60)}m ${_cdTotalSeconds % 60}s',
                style: GoogleFonts.orbitron(color: color.withValues(alpha: 0.5), fontSize: 7)),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _cdAdjust(30),
              child: Icon(Icons.add_circle_outline, color: color.withValues(alpha: 0.7), size: 18),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _cdToggle,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                ),
                child: Text(_cdRunning ? 'PAUSE' : 'START',
                    style: GoogleFonts.orbitron(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _cdReset,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: _cyanDim.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _cyanDim),
                ),
                child: Text('RESET',
                    style: GoogleFonts.orbitron(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool _toggle2Value = false;

  Widget _buildToggle2(Color color) {
    return GestureDetector(
      onTap: () {
        final newVal = !_toggle2Value;
        setState(() => _toggle2Value = newVal);
        _sendCommand(newVal ? 'ON2' : 'OFF2');
        _saveState({'on2': newVal});
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: _toggle2Value ? _cyan.withValues(alpha: 0.15) : _baseBg,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
              color: _toggle2Value ? _cyan : _cyanDim, width: 2),
          boxShadow: _toggle2Value
              ? [BoxShadow(color: _cyan.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 2)]
              : [],
        ),
        child: Icon(
          Icons.power_settings_new_rounded,
          color: _toggle2Value ? _cyan : _cyanDim,
          size: 36,
        ),
      ),
    );
  }

  bool _doorLocked = true;

  Widget _buildDoorLock(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            final newVal = !_doorLocked;
            setState(() => _doorLocked = newVal);
            _sendCommand(newVal ? 'LOCK:ON' : 'LOCK:OFF');
            _saveState({'locked': newVal});
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _doorLocked ? color.withValues(alpha: 0.15) : _baseBg,
              border: Border.all(color: _doorLocked ? color : _cyanDim, width: 2),
              boxShadow: _doorLocked
                  ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 2)]
                  : [],
            ),
            child: Icon(
              _doorLocked ? Icons.lock : Icons.lock_open,
              color: _doorLocked ? color : _cyanDim,
              size: 34,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(_doorLocked ? 'LOCKED' : 'UNLOCKED',
            style: GoogleFonts.orbitron(
                color: _doorLocked ? color : _cyanDim,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
      ],
    );
  }

  double _servoAngle = 90.0;

  Widget _buildServo(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.sync_alt, color: color, size: 28),
        SliderTheme(
          data: _boldSlider(color),
          child: Slider(
            value: _servoAngle,
            min: 0,
            max: 180,
            onChanged: (v) {
              setState(() => _servoAngle = v);
              _sendCommand('SERVO:${v.toInt()}');
              _saveState({'angle': v});
            },
          ),
        ),
        Text('${_servoAngle.toInt()}°',
            style: GoogleFonts.orbitron(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSimpleButton(Color color, String cmd, IconData icon, String label) {
    return GestureDetector(
      onTapDown: (_) {
        _btnFlashCtrl.forward(from: 0);
        _sendCommand(cmd);
        setState(() {});
      },
      onTapUp: (_) => setState(() {}),
      child: AnimatedBuilder(
        animation: _btnFlashCtrl,
        builder: (_, _) {
          final pressed = _btnFlashCtrl.isAnimating;
          return Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pressed ? color.withValues(alpha: 0.2) : _baseBg,
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(
                    color: color.withValues(alpha: pressed ? 0.7 : 0.25),
                    blurRadius: pressed ? 20 : 8,
                    spreadRadius: pressed ? 3 : 0),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 24),
                Text(label,
                    style: GoogleFonts.orbitron(color: color, fontSize: 7, letterSpacing: 1)),
              ],
            ),
          );
        },
      ),
    );
  }

  final List<double> _barData = List.filled(8, 0.0);

  Widget _buildBarChart(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 80,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _barData.map((v) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 6 + v * 74,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),
        Text('LIVE DATA', style: GoogleFonts.orbitron(color: color.withValues(alpha: 0.5), fontSize: 7, letterSpacing: 2)),
      ],
    );
  }

  final Map<String, String> _tableRows = {};

  Widget _buildTable(Color color) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: _tableRows.isEmpty
          ? Text('Waiting for data…',
              style: GoogleFonts.rajdhani(color: Colors.grey, fontSize: 11))
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: _tableRows.entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key, style: GoogleFonts.rajdhani(color: Colors.grey, fontSize: 11)),
                      Text(e.value,
                          style: GoogleFonts.orbitron(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  double _shoulderAngle = 90.0;
  double _elbowAngle = 90.0;
  double _wristAngle = 90.0;

  void _sendJoint(String joint, double angle) {
    _sendCommand('$joint:${angle.toInt()}');
    _saveState({'shoulder': _shoulderAngle, 'elbow': _elbowAngle, 'wrist': _wristAngle});
  }

  Widget _jointSlider(Color color, String label, double value, void Function(double) onChanged) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: GoogleFonts.orbitron(color: color.withValues(alpha: 0.6), fontSize: 7, letterSpacing: 1)),
        RotatedBox(
          quarterTurns: 3,
          child: SizedBox(
            width: 70,
            child: SliderTheme(
              data: _boldSlider(color, trackHeight: 8, thumbRadius: 9),
              child: Slider(value: value, min: 0, max: 180, onChanged: onChanged),
            ),
          ),
        ),
        Text('${value.toInt()}°', style: GoogleFonts.orbitron(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRobotArm(Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 90,
          height: 110,
          child: CustomPaint(
            painter: _RobotArmPainter(
              shoulder: _shoulderAngle,
              elbow: _elbowAngle,
              wrist: _wristAngle,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 6),
        _jointSlider(color, 'SHOULDER', _shoulderAngle, (v) {
          setState(() => _shoulderAngle = v);
          _sendJoint('SHOULDER', v);
        }),
        _jointSlider(color, 'ELBOW', _elbowAngle, (v) {
          setState(() => _elbowAngle = v);
          _sendJoint('ELBOW', v);
        }),
        _jointSlider(color, 'WRIST', _wristAngle, (v) {
          setState(() => _wristAngle = v);
          _sendJoint('WRIST', v);
        }),
      ],
    );
  }

  String _dp2Active = '';

  Widget _dp2Cell(Color color, String direction, IconData? icon, VoidCallback onDown, VoidCallback onUp) {
    final active = _dp2Active == direction;
    return GestureDetector(
      onTapDown: (_) { onDown(); setState(() => _dp2Active = direction); },
      onTapUp: (_) { onUp(); setState(() => _dp2Active = ''); },
      onTapCancel: () { onUp(); setState(() => _dp2Active = ''); },
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: icon != null
              ? Icon(icon, color: active ? Colors.white : color, size: 22)
              : Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? Colors.white : color,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildDpad2(Color color) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Solid cross shape background
          CustomPaint(
            size: const Size(140, 140),
            painter: _CrossShapePainter(color: color, activeDirection: _dp2Active),
          ),
          // Up
          Positioned(
            top: 0, left: 46, width: 48, height: 46,
            child: _dp2Cell(color, 'FWD', Icons.arrow_drop_up_rounded,
                () => _sendCommand('FWD'), () {}),
          ),
          // Down
          Positioned(
            bottom: 0, left: 46, width: 48, height: 46,
            child: _dp2Cell(color, 'BCK', Icons.arrow_drop_down_rounded,
                () => _sendCommand('BCK'), () {}),
          ),
          // Left
          Positioned(
            left: 0, top: 46, width: 46, height: 48,
            child: _dp2Cell(color, 'LEFT', Icons.arrow_left_rounded,
                () => _sendCommand('LEFT'), () {}),
          ),
          // Right
          Positioned(
            right: 0, top: 46, width: 46, height: 48,
            child: _dp2Cell(color, 'RIGHT', Icons.arrow_right_rounded,
                () => _sendCommand('RIGHT'), () {}),
          ),
          // Center circle button
          Positioned(
            left: 46, top: 46, width: 48, height: 48,
            child: _dp2Cell(color, 'CENTER', null,
                () => _sendCommand('PRESS'), () {}),
          ),
        ],
      ),
    );
  }

  Widget _buildControl() {
    final type = widget.widgetData['type'];
    final color = Color(widget.widgetData['color'] as int);
    switch (type) {
      case 'toggle': return _buildToggle(color);
      case 'slider': return _buildSlider(color);
      case 'button': return _buildButton(color);
      case 'joystick': return _buildJoystick(color);
      case 'steering': return _buildSteering(color);
      case 'volume': return _buildVolume(color);
      case 'dpad': return _buildDpad(color);
      case 'gauge':        return _buildGauge(color);
      case 'horn':         return _buildHorn(color);
      case 'brake':        return _buildBrake(color);
      case 'clutch':       return _buildClutch(color);
      case 'pedalset':     return _buildPedalSet(color);
      case 'countdown':    return _buildCountdown(color);
      case 'accelerator':  return _buildAccelerator(color);
      case 'gearshift':    return _buildGearShift(color);
      case 'headlights':   return _buildHeadlights(color);
      case 'turbo':        return _buildTurbo(color);
      case 'rgb':          return _buildRgb(color);
      case 'fanspeed':     return _buildFanSpeed(color);
      case 'graph':        return _buildGraph(color);
      case 'alarm':        return _buildAlarm(color);
      case 'irblast':      return _buildIrBlast(color);
      case 'stopwatch':    return _buildStopwatch(color);
      case 'barchart':     return _buildBarChart(color);
      case 'table':        return _buildTable(color);
      case 'robotarm':     return _buildRobotArm(color);
      case 'dpad2':        return _buildDpad2(color);
      case 'toggle2':      return _buildToggle2(color);
      case 'doorlock':     return _buildDoorLock(color);
      case 'servo':        return _buildServo(color);
      case 'start':        return _buildSimpleButton(color, 'START', Icons.play_arrow_rounded, 'START');
      case 'stop':         return _buildSimpleButton(color, 'STOP', Icons.stop_rounded, 'STOP');
      case 'chup':         return _buildSimpleButton(color, 'CH+', Icons.keyboard_arrow_up, 'CH+');
      case 'chdown':       return _buildSimpleButton(color, 'CH-', Icons.keyboard_arrow_down, 'CH-');
      case 'volup':        return _buildSimpleButton(color, 'VOL+', Icons.volume_up, 'VOL+');
      case 'voldown':      return _buildSimpleButton(color, 'VOL-', Icons.volume_down, 'VOL-');
      case 'muteonly':     return _buildSimpleButton(color, 'MUTE', Icons.volume_off, 'MUTE');
      default: return Icon(Icons.widgets, color: color, size: 40);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.widgetData['color'] as int);
    final label = widget.widgetData['label'] as String;
    final editMode = widget.editMode;
    final labelHidden = widget.widgetData['labelHidden'] == true;

    return Container(
      width: double.infinity,
      height: double.infinity,
      // Edit mode: transparent fill so widgets underneath stay visible while
      // dragging — only the outline frame shows, no solid card behind it.
      // Live mode: no decoration at all, so taps only land on the actual
      // control shape (empty space passes through to whatever's beneath).
      decoration: editMode
          ? BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.9), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: color.withValues(alpha: 0.18),
                    blurRadius: 18,
                    spreadRadius: 1),
              ],
            )
          : null,
      padding: EdgeInsets.all(editMode ? 4 : 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Control fills the full box edge-to-edge.
          Positioned.fill(
            child: ClipRect(
              clipBehavior: editMode ? Clip.hardEdge : Clip.none,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Reference size the controls were originally designed at.
                  // As the box is resized, we scale the whole control
                  // (switch, button, dpad, etc.) up/down to match.
                  const baseW = 160.0;
                  const baseH = 140.0;
                  final scale = constraints.maxWidth > 0 && constraints.maxHeight > 0
                      ? min(constraints.maxWidth / baseW, constraints.maxHeight / baseH)
                          .clamp(0.5, 2.8)
                      : 1.0;
                  return Center(
                    child: Transform.scale(
                      scale: scale,
                      child: _buildControl(),
                    ),
                  );
                },
              ),
            ),
          ),
          // Edit mode: an invisible layer sits over the control and absorbs
          // all gestures, so tapping/dragging a toggle or slider no longer
          // triggers it — instead, holding down anywhere on the widget
          // moves it, just like rearranging icons on a phone home screen.
          if (editMode)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (d) => widget.onMove(d.delta.dx, d.delta.dy),
                child: Container(color: Colors.transparent),
              ),
            ),
          // Edit mode: label pill + icons overlaid on top.
          // Positioned below the top row of resize handles (which sit right
          // at the box edges) so the header content isn't hidden underneath
          // them.
          if (editMode)
            Positioned(
              top: 46,
              left: 6,
              right: 6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: _cardBg.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: GestureDetector(
                              onTap: widget.onRename,
                              child: Text(
                                label,
                                style: GoogleFonts.orbitron(
                                  color: Colors.grey,
                                  fontSize: 9,
                                  letterSpacing: 1.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: widget.onRename,
                            child: Icon(Icons.edit, color: color, size: 16),
                          ),
                          const SizedBox(width: 6),
                          // Show/hide the label in live mode — right next to
                          // the rename pencil.
                          GestureDetector(
                            onTap: widget.onToggleLabel,
                            child: Icon(
                                labelHidden
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: color,
                                size: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      margin: const EdgeInsets.only(left: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B3B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: const Color(0xFFFF3B3B)
                                .withValues(alpha: 0.5),
                            width: 1),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFFFF3B3B)
                                  .withValues(alpha: 0.2),
                              blurRadius: 8)
                        ],
                      ),
                      child: const Icon(Icons.delete_rounded,
                          color: Color(0xFFFF3B3B), size: 16),
                    ),
                  ),
                ],
              ),
            ),
          // Live mode: no box, just the widget's name floating below the
          // control (grey, blending with the background) unless hidden.
          if (!editMode && !labelHidden)
            Positioned(
              left: 0,
              right: 0,
              bottom: -18,
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.orbitron(
                    color: Colors.grey.withValues(alpha: 0.8),
                    fontSize: 9,
                    letterSpacing: 1.2,
                    shadows: const [
                      Shadow(color: Colors.black, blurRadius: 6),
                      Shadow(color: Colors.black, blurRadius: 12),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DpadCell extends StatelessWidget {
  final String direction;
  final bool active;
  final Color color;
  final Widget child;
  final VoidCallback onDown, onUp;

  const _DpadCell(
      {required this.direction,
      required this.active,
      required this.color,
      required this.child,
      required this.onDown,
      required this.onUp});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onDown(),
      onTapUp: (_) => onUp(),
      onTapCancel: onUp,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF0A1E30)
              : const Color(0xFF0D1520),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: active ? color : const Color(0xFF2A3F55),
              width: active ? 1.5 : 1),
          boxShadow: active
              ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10)]
              : [],
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final String direction;
  final Color color;
  final bool active;
  _TrianglePainter(
      {required this.direction,
      required this.color,
      required this.active});

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

// Draws a single hanging pedal: a short arm dropping from the top edge into
// a rounded pedal pad with two "bolt" dots and texture lines — matching the
// reference pedal icon style.
class _PedalIconPainter extends CustomPainter {
  final Color color;
  final bool pressed;
  _PedalIconPainter({required this.color, required this.pressed});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeColor = pressed ? Color.lerp(color, Colors.white, 0.3)! : color;
    final stroke = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final armTopY = 0.0;
    final armBottomY = h * 0.32;
    final padTop = h * 0.30;
    final padHeight = h * 0.66;
    final padWidth = w * 0.78;
    final padLeft = (w - padWidth) / 2;

    // Arm connecting to the shared bar above.
    canvas.drawLine(Offset(w / 2, armTopY), Offset(w / 2, armBottomY), stroke);

    // Pedal pad — rounded rect, slightly tilted down when pressed.
    final padRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(padLeft, padTop, padWidth, padHeight),
      const Radius.circular(8),
    );
    canvas.save();
    if (pressed) {
      canvas.translate(w / 2, padTop);
      canvas.rotate(0.05);
      canvas.translate(-w / 2, -padTop);
    }
    canvas.drawRRect(padRect, stroke);

    // Two bolt dots near the top of the pad.
    final dotPaint = Paint()..color = strokeColor..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(padLeft + padWidth * 0.3, padTop + padHeight * 0.18), 1.6, dotPaint);
    canvas.drawCircle(Offset(padLeft + padWidth * 0.7, padTop + padHeight * 0.18), 1.6, dotPaint);

    // Texture lines across the pad.
    for (final f in [0.42, 0.58, 0.74]) {
      canvas.drawLine(
        Offset(padLeft + padWidth * 0.15, padTop + padHeight * f),
        Offset(padLeft + padWidth * 0.85, padTop + padHeight * f),
        stroke..strokeWidth = 1.6,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PedalIconPainter old) =>
      old.pressed != pressed || old.color != color;
}

class _SteeringPainter extends CustomPainter {
  final Color color;
  final double angle;
  _SteeringPainter({required this.color, required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 8;
    final ir = r * 0.22;

    final triPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    final triPath = Path()
      ..moveTo(cx, cy - r - 7)
      ..lineTo(cx - 5, cy - r + 2)
      ..lineTo(cx + 5, cy - r + 2)
      ..close();
    canvas.drawPath(triPath, triPaint);

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(angle * pi / 180);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    paint.color = color.withValues(alpha: 0.15);
    paint.strokeWidth = 12;
    canvas.drawCircle(Offset.zero, r, paint);

    paint.color = color;
    paint.strokeWidth = 4;
    canvas.drawCircle(Offset.zero, r, paint);

    paint.strokeWidth = 2.5;
    canvas.drawCircle(Offset.zero, ir, paint);

    paint.strokeWidth = 2.5;
    final spokes = [
      Offset(0, -r),
      Offset(0, r),
      Offset(-r, 0),
      Offset(r, 0)
    ];
    for (final s in spokes) {
      canvas.drawLine(
          Offset(s.dx * ir / r, s.dy * ir / r), s, paint);
    }
    final rimDot = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
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

class _JoystickPainter extends CustomPainter {
  final Color color;
  final Offset offset;
  final bool active;
  _JoystickPainter(
      {required this.color, required this.offset, required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 4;

    final basePaint = Paint()
      ..color = _baseBg
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r, basePaint);

    canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = color.withValues(alpha: 0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8);

    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(cx, cy), r, borderPaint);

    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    canvas.drawLine(
        Offset(cx, cy - r + 4), Offset(cx, cy + r - 4), linePaint);
    canvas.drawLine(
        Offset(cx - r + 4, cy), Offset(cx + r - 4, cy), linePaint);

    final dashPaint = Paint()
      ..color = color.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(cx, cy), r * 0.52, dashPaint);
    canvas.drawCircle(Offset(cx, cy), r * 0.85, dashPaint);

    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    for (final pt in [
      Offset(cx, cy - r + 4),
      Offset(cx, cy + r - 4),
      Offset(cx - r + 4, cy),
      Offset(cx + r - 4, cy)
    ]) {
      canvas.drawCircle(pt, 2.5, dotPaint);
    }

    final tx = cx + offset.dx;
    final ty = cy + offset.dy;
    canvas.drawCircle(
        Offset(tx, ty),
        28,
        Paint()
          ..color = color.withValues(alpha: active ? 0.15 : 0.06)
          ..style = PaintingStyle.fill);
    canvas.drawCircle(
        Offset(tx, ty),
        25,
        Paint()
          ..color = const Color(0xFF0D1F30)
          ..style = PaintingStyle.fill);
    canvas.drawCircle(
        Offset(tx, ty),
        25,
        Paint()
          ..color = active ? color.withValues(alpha: 0.9) : color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    canvas.drawCircle(
        Offset(tx, ty),
        8,
        Paint()
          ..color = color.withValues(alpha: active ? 0.7 : 0.3)
          ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_JoystickPainter old) =>
      old.offset != offset || old.active != active || old.color != color;
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color color;
  _GaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height - 4;
    final r = size.width / 2 - 6;
    const startAngle = pi * 0.75;
    const sweepAngle = pi * 1.5;

    canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = _trackBg
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round);

    if (value > 0) {
      canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: r),
          startAngle,
          sweepAngle * value,
          false,
          Paint()
            ..color = color.withValues(alpha: 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 14
            ..strokeCap = StrokeCap.round);
      canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: r),
          startAngle,
          sweepAngle * value,
          false,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7
            ..strokeCap = StrokeCap.round);
    }

    final needleAngle = startAngle + sweepAngle * value;
    final nx = cx + cos(needleAngle) * r * 0.72;
    final ny = cy + sin(needleAngle) * r * 0.72;
    canvas.drawLine(
        Offset(cx, cy),
        Offset(nx, ny),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round);
    canvas.drawCircle(Offset(cx, cy), 4,
        Paint()..color = color..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value || old.color != color;
}

class _CrossShapePainter extends CustomPainter {
  final Color color;
  final String activeDirection;
  _CrossShapePainter({required this.color, required this.activeDirection});
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const armThickness = 48.0;
    final armStart = (w - armThickness) / 2;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(armStart, 0, armThickness, h), const Radius.circular(10)))
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(0, armStart, w, armThickness), const Radius.circular(10)));
    canvas.drawPath(path, paint);
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, borderPaint);
  }
  @override
  bool shouldRepaint(_CrossShapePainter old) =>
      old.color != color || old.activeDirection != activeDirection;
}

class _RobotArmPainter extends CustomPainter {
  final double shoulder, elbow, wrist;
  final Color color;
  _RobotArmPainter({required this.shoulder, required this.elbow, required this.wrist, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final base = Offset(size.width / 2, size.height);
    final segLen = size.height / 3.2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final glow = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final jointPaint = Paint()..color = Colors.white;

    // Shoulder joint: 0-180 maps to swinging left-right from vertical.
    final a1 = (shoulder - 90) * pi / 180;
    final p1 = base + Offset(sin(a1) * segLen, -cos(a1) * segLen);

    // Elbow angle is relative to the shoulder segment's direction.
    final a2 = a1 + (elbow - 90) * pi / 180;
    final p2 = p1 + Offset(sin(a2) * segLen, -cos(a2) * segLen);

    // Wrist angle relative to elbow segment.
    final a3 = a2 + (wrist - 90) * pi / 180;
    final p3 = p2 + Offset(sin(a3) * segLen * 0.6, -cos(a3) * segLen * 0.6);

    canvas.drawLine(base, p1, glow);
    canvas.drawLine(p1, p2, glow);
    canvas.drawLine(p2, p3, glow);
    canvas.drawLine(base, p1, paint);
    canvas.drawLine(p1, p2, paint);
    canvas.drawLine(p2, p3, paint);

    canvas.drawCircle(base, 5, jointPaint);
    canvas.drawCircle(p1, 5, jointPaint);
    canvas.drawCircle(p2, 5, jointPaint);
    canvas.drawCircle(p3, 4, jointPaint);
  }

  @override
  bool shouldRepaint(_RobotArmPainter old) =>
      old.shoulder != shoulder || old.elbow != elbow || old.wrist != wrist || old.color != color;
}

class _GraphPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  _GraphPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final stepX = size.width / (data.length - 1);
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      points.add(Offset(i * stepX, size.height - (data[i] * size.height)));
    }

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    final fillPath = Path()
      ..moveTo(points[0].dx, size.height)
      ..lineTo(points[0].dx, points[0].dy);

    // Smooth curve through points using quadratic midpoints — gives the
    // line a soft, "alive" flowing look instead of sharp zig-zags.
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
      fillPath.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    fillPath.lineTo(points.last.dx, points.last.dy);
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
    canvas.drawCircle(points.last, 4, Paint()..color = color);
    canvas.drawCircle(points.last, 4, Paint()
      ..color = color.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
  }

  @override
  bool shouldRepaint(_GraphPainter old) => old.data != data || old.color != color;
}