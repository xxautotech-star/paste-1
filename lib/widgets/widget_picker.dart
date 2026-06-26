import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WidgetPicker extends StatelessWidget {
  final Function(Map) onWidgetSelected;
  const WidgetPicker({super.key, required this.onWidgetSelected});

  static final List<Map> availableWidgets = [
    {
      'type': 'toggle',
      'label': 'Toggle Switch',
      'iconCode': 0xe59e,
      'color': 0xFF00D4FF,
    },
    {
      'type': 'slider',
      'label': 'Slider',
      'iconCode': 0xe3ee,
      'color': 0xFF7C3AED,
    },
    {
      'type': 'button',
      'label': 'Button',
      'iconCode': 0xe061,
      'color': 0xFF00E676,
    },
    {
      'type': 'joystick',
      'label': 'Joystick',
      'iconCode': 0xe30f,
      'color': 0xFFFFD740,
    },
    {
      'type': 'steering',
      'label': 'Steering',
      'iconCode': 0xe627,
      'color': 0xFFFF5252,
    },
    {
      'type': 'volume',
      'label': 'Volume',
      'iconCode': 0xe050,
      'color': 0xFF00BCD4,
    },
    {
      'type': 'dpad',
      'label': 'D-Pad',
      'iconCode': 0xe129,
      'color': 0xFFFF9800,
    },
    {
      'type': 'gauge',
      'label': 'Gauge',
      'iconCode': 0xe576,
      'color': 0xFFE91E63,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF374151),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'ADD WIDGET',
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 13,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap to add to your control panel',
            style: GoogleFonts.rajdhani(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: availableWidgets.length,
            itemBuilder: (context, i) {
              final w = availableWidgets[i];
              final color = Color(w['color'] as int);
              final iconCode = (w['iconCode'] as num).toInt();
              return GestureDetector(
                onTap: () => onWidgetSelected({
                  'type': w['type'],
                  'label': w['label'],
                  'iconCode': w['iconCode'],
                  'color': w['color'],
                }),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2234),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
  IconData(iconCode, fontFamily: 'MaterialIcons'),
  color: color,
  size: 22,
),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        w['label'] as String,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.rajdhani(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}