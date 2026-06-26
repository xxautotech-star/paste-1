import 'package:flutter/material.dart';

class CanvasWidget extends StatefulWidget {
  final Map widgetData;
  final String mqttTopic;
  final Function(double, double) onMove;
  final VoidCallback onDelete;

  const CanvasWidget({
    super.key,
    required this.widgetData,
    required this.mqttTopic,
    required this.onMove,
    required this.onDelete,
  });

  @override
  State<CanvasWidget> createState() => _CanvasWidgetState();
}

class _CanvasWidgetState extends State<CanvasWidget> {
  bool toggleValue = false;
  double sliderValue = 0.5;
  bool isMuted = false;

  Widget _buildControl() {
    final type = widget.widgetData['type'];
    final color = Color(widget.widgetData['color'] as int);

    switch (type) {
      case 'toggle':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: toggleValue,
              activeColor: color,
              onChanged: (v) => setState(() => toggleValue = v),
            ),
            Text(toggleValue ? 'ON' : 'OFF',
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        );

      case 'slider':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Slider(
              value: sliderValue,
              activeColor: color,
              onChanged: (v) => setState(() => sliderValue = v),
            ),
            Text('${(sliderValue * 100).toInt()}%',
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        );

      case 'button':
        return ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(20),
          ),
          child: const Icon(Icons.touch_app, color: Colors.black, size: 28),
        );

      case 'joystick':
        return Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
            color: color.withOpacity(0.1),
          ),
          child: Center(
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              child: const Icon(Icons.gamepad, color: Colors.black, size: 20),
            ),
          ),
        );

      case 'steering':
        return Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
            color: color.withOpacity(0.1),
          ),
          child: Icon(Icons.sync, color: color, size: 50),
        );

      case 'volume':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => setState(() => isMuted = !isMuted),
              icon: Icon(
                isMuted ? Icons.volume_off : Icons.volume_up,
                color: color, size: 32,
              ),
            ),
            Slider(
              value: isMuted ? 0 : sliderValue,
              activeColor: color,
              onChanged: (v) => setState(() { sliderValue = v; isMuted = false; }),
            ),
          ],
        );

      case 'dpad':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(onPressed: () {}, icon: Icon(Icons.arrow_upward, color: color)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(onPressed: () {}, icon: Icon(Icons.arrow_back, color: color)),
                Icon(Icons.circle, color: color.withOpacity(0.3), size: 20),
                IconButton(onPressed: () {}, icon: Icon(Icons.arrow_forward, color: color)),
              ],
            ),
            IconButton(onPressed: () {}, icon: Icon(Icons.arrow_downward, color: color)),
          ],
        );

      case 'gauge':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.speed, color: color, size: 50),
            const SizedBox(height: 4),
            Text('${(sliderValue * 100).toInt()}',
                style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        );

      default:
        return Icon(Icons.widgets, color: color, size: 40);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.widgetData['x'] as double,
      top: widget.widgetData['y'] as double,
      child: GestureDetector(
        onPanUpdate: (d) => widget.onMove(d.delta.dx, d.delta.dy),
        child: Container(
          constraints: const BoxConstraints(minWidth: 120),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Color(widget.widgetData['color'] as int).withOpacity(0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(widget.widgetData['color'] as int).withOpacity(0.15),
                blurRadius: 10,
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.widgetData['label'] as String,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: widget.onDelete,
                    child: const Icon(Icons.close, color: Colors.grey, size: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildControl(),
            ],
          ),
        ),
      ),
    );
  }
}