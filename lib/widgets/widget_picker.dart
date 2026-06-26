import 'package:flutter/material.dart';

class WidgetPicker extends StatelessWidget {
  final Function(Map) onWidgetSelected;
  const WidgetPicker({super.key, required this.onWidgetSelected});

  final List<Map> availableWidgets = const [
    {'type': 'toggle', 'label': 'Toggle Switch', 'icon': Icons.toggle_on, 'color': 0xFF00D4FF},
    {'type': 'slider', 'label': 'Slider', 'icon': Icons.linear_scale, 'color': 0xFF7C3AED},
    {'type': 'button', 'label': 'Button', 'icon': Icons.radio_button_checked, 'color': 0xFF00E676},
    {'type': 'joystick', 'label': 'Joystick', 'icon': Icons.gamepad, 'color': 0xFFFFD740},
    {'type': 'steering', 'label': 'Steering Wheel', 'icon': Icons.sync, 'color': 0xFFFF5252},
    {'type': 'volume', 'label': 'Volume Control', 'icon': Icons.volume_up, 'color': 0xFF00BCD4},
    {'type': 'dpad', 'label': 'D-Pad', 'icon': Icons.control_camera, 'color': 0xFFFF9800},
    {'type': 'gauge', 'label': 'Gauge', 'icon': Icons.speed, 'color': 0xFFE91E63},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Choose a Widget',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Tap to add to your canvas',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: availableWidgets.length,
            itemBuilder: (context, i) {
              final w = availableWidgets[i];
              return GestureDetector(
                onTap: () => onWidgetSelected(w),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2234),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Color(w['color'] as int).withOpacity(0.3)),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: Color(w['color'] as int).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(w['icon'] as IconData,
                            color: Color(w['color'] as int), size: 24),
                      ),
                      const SizedBox(height: 8),
                      Text(w['label'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}