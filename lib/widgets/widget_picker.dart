import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class WidgetPicker extends StatefulWidget {
  final Function(Map) onWidgetSelected;
  const WidgetPicker({super.key, required this.onWidgetSelected});

  @override
  State<WidgetPicker> createState() => _WidgetPickerState();
}

class _WidgetPickerState extends State<WidgetPicker> {
  static final List<Map> _activeWidgets = [
    {'type': 'toggle',      'label': 'Toggle Switch', 'iconCode': 0xe59e, 'color': 0xFF00D4FF},
    {'type': 'slider',      'label': 'Slider',        'iconCode': 0xe3ee, 'color': 0xFF00B8E6},
    {'type': 'button',      'label': 'Button',        'iconCode': 0xe061, 'color': 0xFF00E5CC},
    {'type': 'joystick',    'label': 'Joystick',      'iconCode': 0xe30f, 'color': 0xFF0099FF},
    {'type': 'steering',    'label': 'Steering',      'iconCode': 0xe627, 'color': 0xFF00C4E8},
    {'type': 'volume',      'label': 'Volume',        'iconCode': 0xe050, 'color': 0xFF00EEFF},
    {'type': 'dpad',        'label': 'D-Pad',         'iconCode': 0xe129, 'color': 0xFF00AAF0},
    {'type': 'gauge',       'label': 'Gauge',         'iconCode': 0xe576, 'color': 0xFF00D4CC},
    {'type': 'horn',        'label': 'Horn',          'iconCode': 0xe332, 'color': 0xFFFFD740},
    {'type': 'brake',       'label': 'Brake',         'iconCode': 0xe1a3, 'color': 0xFFFF5252},
    {'type': 'clutch',      'label': 'Clutch',        'iconCode': 0xe1a3, 'color': 0xFF9575CD},
    {'type': 'pedalset',    'label': 'Pedal Set',     'iconCode': 0xe1b3, 'color': 0xFFFFA726},
    {'type': 'accelerator', 'label': 'Accelerator',   'iconCode': 0xe1b3, 'color': 0xFF22C55E},
    {'type': 'gearshift',   'label': 'Gear Shift',    'iconCode': 0xe3ca, 'color': 0xFFFF9800},
    {'type': 'headlights',  'label': 'Headlights',    'iconCode': 0xe518, 'color': 0xFFFFF176},
    {'type': 'turbo',       'label': 'Turbo Boost',   'iconCode': 0xe1b2, 'color': 0xFF00FFD0},
    {'type': 'rgb',      'label': 'RGB Picker',    'iconCode': 0xe3af, 'color': 0xFFE040FB},
    {'type': 'fanspeed', 'label': 'Fan Speed',      'iconCode': 0xf0270, 'color': 0xFF80D8FF},
    {'type': 'graph',    'label': 'Graph',          'iconCode': 0xe24b, 'color': 0xFF00E5FF},
    {'type': 'alarm',    'label': 'Alarm Trigger',  'iconCode': 0xe855, 'color': 0xFFFF1744},
    {'type': 'irblast',  'label': 'IR Blaster',     'iconCode': 0xe007, 'color': 0xFFD500F9},
    {'type': 'stopwatch','label': 'Stopwatch',      'iconCode': 0xe425, 'color': 0xFF00D4FF},
    {'type': 'countdown','label': 'Countdown Timer','iconCode': 0xe422, 'color': 0xFF00D4FF},
    {'type': 'toggle2',  'label': 'Toggle (Rounded)','iconCode': 0xe835, 'color': 0xFF00D4FF},
    {'type': 'doorlock', 'label': 'Door Lock',       'iconCode': 0xe897, 'color': 0xFFFFD740},
    {'type': 'servo',    'label': 'Servo Controller','iconCode': 0xe627, 'color': 0xFF00B0FF},
    {'type': 'start',    'label': 'Start',           'iconCode': 0xe037, 'color': 0xFF22C55E},
    {'type': 'stop',     'label': 'Stop',            'iconCode': 0xe047, 'color': 0xFFFF5252},
    {'type': 'chup',     'label': 'CH +',            'iconCode': 0xe5c7, 'color': 0xFFD500F9},
    {'type': 'chdown',   'label': 'CH -',            'iconCode': 0xe5c5, 'color': 0xFFD500F9},
    {'type': 'volup',    'label': 'VOL +',           'iconCode': 0xe050, 'color': 0xFFD500F9},
    {'type': 'voldown',  'label': 'VOL -',           'iconCode': 0xe04d, 'color': 0xFFD500F9},
    {'type': 'muteonly', 'label': 'Mute',            'iconCode': 0xe04f, 'color': 0xFFD500F9},
    {'type': 'shape_circle', 'label': 'Circle',      'iconCode': 0xef4a, 'color': 0xFF00D4FF},
    {'type': 'shape_rect',   'label': 'Rectangle',   'iconCode': 0xe3ba, 'color': 0xFF00D4FF},
    {'type': 'shape_line',   'label': 'Line',        'iconCode': 0xe914, 'color': 0xFF00D4FF},
    {'type': 'barchart', 'label': 'Bar Chart',        'iconCode': 0xe26b, 'color': 0xFF00E5FF},
    {'type': 'table',    'label': 'Table',            'iconCode': 0xe32a, 'color': 0xFF00E5FF},
    {'type': 'robotarm', 'label': 'Robot Arm',        'iconCode': 0xe84f, 'color': 0xFF00D4FF},
    {'type': 'dpad2',    'label': 'D-Pad (Classic)',  'iconCode': 0xe329, 'color': 0xFF00D4FF},
  ];

  static final List<Map> _comingSoon = [
    {'label': 'Temperature',        'iconCode': 0xe1ff, 'color': 0xFFFF6E40},
    {'label': 'Humidity',           'iconCode': 0xe798, 'color': 0xFF40C4FF},
    {'label': 'GPS Tracker',        'iconCode': 0xe0c8, 'color': 0xFF69F0AE},
    {'label': 'Camera Feed',        'iconCode': 0xe04b, 'color': 0xFFFF5252},

    
    {'label': 'Motion Detector',    'iconCode': 0xe554, 'color': 0xFF76FF03},
    {'label': 'Fingerprint',        'iconCode': 0xe90d, 'color': 0xFF00E5FF},
    {'label': 'Voice Command',      'iconCode': 0xe31d, 'color': 0xFFE040FB},
    {'label': 'SMS Alert',          'iconCode': 0xe61f, 'color': 0xFF69F0AE},
    {'label': 'Battery Monitor',    'iconCode': 0xe1a4, 'color': 0xFF22C55E},
    {'label': 'Relay Bank',         'iconCode': 0xe63e, 'color': 0xFFFF9800},
    {'label': 'Custom Script',      'iconCode': 0xe86f, 'color': 0xFFFF6D00},
  ];

  static IconData _getIcon(String type) {
    switch (type) {
      case 'toggle':      return Icons.toggle_on;
      case 'slider':      return Icons.tune;
      case 'button':      return Icons.power_settings_new_rounded;
      case 'joystick':    return Icons.videogame_asset_rounded;
      case 'steering':    return Icons.sync_alt;
      case 'volume':      return Icons.volume_up;
      case 'dpad':        return Icons.control_camera_rounded;
      case 'gauge':       return Icons.speed;
      case 'horn':        return Icons.volume_up_rounded;
      case 'brake':       return Icons.stop_circle_outlined;
      case 'clutch':      return Icons.compress_rounded;
      case 'pedalset':    return Icons.directions_car_filled_rounded;
      case 'accelerator': return Icons.arrow_upward_rounded;
      case 'gearshift':   return Icons.settings_input_component;
      case 'headlights':  return Icons.lightbulb_outline;
      case 'turbo':       return Icons.bolt_rounded;
      case 'rgb':         return Icons.palette;
      case 'fanspeed':    return Icons.air;
      case 'graph':       return Icons.show_chart;
      case 'alarm':       return Icons.notification_important;
      case 'irblast':     return Icons.settings_remote;
      case 'stopwatch':   return Icons.timer;
      case 'countdown':   return Icons.hourglass_bottom_rounded;
      case 'toggle2':     return Icons.toggle_on;
      case 'doorlock':    return Icons.lock;
      case 'servo':       return Icons.sync_alt;
      case 'start':       return Icons.play_arrow_rounded;
      case 'stop':        return Icons.stop_rounded;
      case 'chup':        return Icons.keyboard_arrow_up;
      case 'chdown':      return Icons.keyboard_arrow_down;
      case 'volup':       return Icons.volume_up;
      case 'voldown':     return Icons.volume_down;
      case 'muteonly':    return Icons.volume_off;
      case 'shape_circle': return Icons.circle_outlined;
      case 'shape_rect':   return Icons.crop_square_rounded;
      case 'shape_line':   return Icons.horizontal_rule_rounded;
      case 'barchart':     return Icons.bar_chart_rounded;
      case 'table':        return Icons.table_rows_rounded;
      case 'robotarm':     return Icons.precision_manufacturing_rounded;
      case 'dpad2':        return Icons.control_camera_rounded;
      default:              return Icons.widgets;
    }
  }

  static IconData _getComingSoonIcon(String label) {
    switch (label) {
      case 'Temperature':        return Icons.thermostat;
      case 'Humidity':           return Icons.water_drop;
      case 'GPS Tracker':        return Icons.gps_fixed;
      case 'Camera Feed':        return Icons.videocam;
      case 'Servo Controller':   return Icons.sync_alt;
      case 'Door Lock':          return Icons.lock;
      case 'Motion Detector':    return Icons.sensors;
      case 'Fingerprint':        return Icons.fingerprint;
      case 'Voice Command':      return Icons.mic;
      case 'SMS Alert':          return Icons.sms;
      case 'Battery Monitor':    return Icons.battery_full;
      case 'Relay Bank':         return Icons.dns;
      case 'Custom Script':      return Icons.code;
      default:                   return Icons.widgets;
    }
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF111827),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            const Icon(Icons.rocket_launch, color: Color(0xFF00D4FF), size: 16),
            const SizedBox(width: 8),
            Text(
              'Coming soon — stay tuned!',
              style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openSuggestSheet() {
    final nameController = TextEditingController();
    final useCaseController = TextEditingController();
    bool submitted = false;
    bool sending = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: submitted
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00D4FF).withValues(alpha: 0.1),
                        border: Border.all(
                            color: const Color(0xFF00D4FF).withValues(alpha: 0.4)),
                      ),
                      child: const Icon(Icons.check,
                          color: Color(0xFF00D4FF), size: 32),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Idea Received!',
                      style: GoogleFonts.orbitron(
                          color: const Color(0xFF00D4FF),
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Your idea has been noted.\nWe build for our community.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.rajdhani(
                          color: Colors.white54, fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D4FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text('Close',
                              style: GoogleFonts.orbitron(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D4FF).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Suggest a Widget',
                        style: GoogleFonts.orbitron(
                            color: const Color(0xFF00D4FF),
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                        'Have an idea? Tell us what you need and how you\'d use it.',
                        style: GoogleFonts.rajdhani(
                            color: Colors.white38, fontSize: 12)),
                    const SizedBox(height: 20),
                    Text('Widget Name',
                        style: GoogleFonts.orbitron(
                            color: Colors.white54,
                            fontSize: 9,
                            letterSpacing: 1)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      style: GoogleFonts.rajdhani(
                          color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'e.g. Temperature Display',
                        hintStyle: GoogleFonts.rajdhani(
                            color: Colors.white24, fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFF0A0E1A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFF1E2D45)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFF1E2D45)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFF00D4FF)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('How would you use it?',
                        style: GoogleFonts.orbitron(
                            color: Colors.white54,
                            fontSize: 9,
                            letterSpacing: 1)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: useCaseController,
                      style: GoogleFonts.rajdhani(
                          color: Colors.white, fontSize: 14),
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            'e.g. I want to read temperature from my ESP32 sensor and display it live.',
                        hintStyle: GoogleFonts.rajdhani(
                            color: Colors.white24, fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFF0A0E1A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFF1E2D45)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFF1E2D45)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFF00D4FF)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: sending
                          ? null
                          : () async {
                              if (nameController.text.trim().isEmpty ||
                                  useCaseController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: const Color(0xFF111827),
                                    content: Text('Please fill in both fields.',
                                        style: GoogleFonts.rajdhani(
                                            color: Colors.white)),
                                  ),
                                );
                                return;
                              }
                              setInner(() => sending = true);
                              try {
                                await ApiService.submitWidgetSuggestion(
                                  nameController.text.trim(),
                                  useCaseController.text.trim(),
                                );
                                setInner(() {
                                  submitted = true;
                                  sending = false;
                                });
                              } catch (e) {
                                setInner(() => sending = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: const Color(0xFF111827),
                                    content: Text('Failed to submit. Try again.',
                                        style: GoogleFonts.rajdhani(
                                            color: Colors.white)),
                                  ),
                                );
                              }
                            },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D4FF),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color:
                                    const Color(0xFF00D4FF).withValues(alpha: 0.3),
                                blurRadius: 16,
                                spreadRadius: 1),
                          ],
                        ),
                        child: Center(
                          child: sending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.black, strokeWidth: 2),
                                )
                              : Text('Submit Idea',
                                  style: GoogleFonts.orbitron(
                                      color: Colors.black,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: const Color(0xFF00D4FF),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(text,
              style: GoogleFonts.orbitron(
                  color: Colors.white54, fontSize: 9, letterSpacing: 2)),
        ],
      ),
    );
  }

  Widget _widgetCard(
      {required String label,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.2), blurRadius: 12, spreadRadius: 1),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 10)
                ],
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 7),
            Text(label,
                textAlign: TextAlign.center,
                style: GoogleFonts.rajdhani(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D1520),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFF00D4FF), width: 1)),
        boxShadow: [
          BoxShadow(color: Color(0x4400D4FF), blurRadius: 24, spreadRadius: 2)
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4FF).withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: const [
                    BoxShadow(color: Color(0x6600D4FF), blurRadius: 8)
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text('ADD WIDGET',
                  style: GoogleFonts.orbitron(
                      color: const Color(0xFF00D4FF),
                      fontSize: 13,
                      letterSpacing: 2,
                      shadows: const [
                        Shadow(color: Color(0x8800D4FF), blurRadius: 10)
                      ])),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text('Tap to add to your control panel',
                  style:
                      GoogleFonts.rajdhani(color: Colors.grey, fontSize: 13)),
            ),
            const SizedBox(height: 24),

            // ── SECTION 1: ACTIVE WIDGETS ──
            _sectionLabel('CONTROLS'),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: _activeWidgets.length,
              itemBuilder: (context, i) {
                final w = _activeWidgets[i];
                final color = Color(w['color'] as int);
                return _widgetCard(
                  label: w['label'] as String,
                  icon: _getIcon(w['type'] as String),
                  color: color,
                  onTap: () => widget.onWidgetSelected({
                    'type': w['type'],
                    'label': w['label'],
                    'iconCode': w['iconCode'],
                    'color': w['color'],
                  }),
                );
              },
            ),

            const SizedBox(height: 24),

            // ── SECTION 2: COMING SOON ──
            _sectionLabel('COMING SOON'),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: _comingSoon.length,
              itemBuilder: (context, i) {
                final w = _comingSoon[i];
                final color = Color(w['color'] as int);
                return _widgetCard(
                  label: w['label'] as String,
                  icon: _getComingSoonIcon(w['label'] as String),
                  color: color.withValues(alpha: 0.4),
                  onTap: _showComingSoon,
                );
              },
            ),

            const SizedBox(height: 28),

            // ── SUGGEST BUTTON ──
            GestureDetector(
              onTap: _openSuggestSheet,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0E1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF00D4FF).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        color: Color(0xFF00D4FF), size: 16),
                    const SizedBox(width: 8),
                    Text('Suggest a Widget',
                        style: GoogleFonts.orbitron(
                            color: const Color(0xFF00D4FF),
                            fontSize: 11,
                            letterSpacing: 1)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}