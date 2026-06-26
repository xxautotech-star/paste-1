import 'package:flutter/material.dart';
import '../widgets/widget_picker.dart';
import '../widgets/canvas_widget.dart';

class CanvasScreen extends StatefulWidget {
  final Map device;
  const CanvasScreen({super.key, required this.device});
  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends State<CanvasScreen> {
  List<Map> placedWidgets = [];

  void _openWidgetPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => WidgetPicker(
        onWidgetSelected: (widget) {
          setState(() {
            placedWidgets.add({
              ...widget,
              'x': 50.0,
              'y': 50.0 + (placedWidgets.length * 120),
              'label': widget['label'],
            });
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        title: Text(
          widget.device['name'] ?? 'Device',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Color(0xFF00D4FF), size: 28),
            onPressed: _openWidgetPicker,
            tooltip: 'Add Widget',
          ),
        ],
      ),
      body: placedWidgets.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.widgets, color: Color(0xFF00D4FF), size: 60),
                  const SizedBox(height: 16),
                  const Text('No widgets yet',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Tap + to add controls',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _openWidgetPicker,
                    icon: const Icon(Icons.add, color: Colors.black),
                    label: const Text('Add Widget', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D4FF)),
                  ),
                ],
              ),
            )
          : Stack(
              children: placedWidgets.map((w) {
                return CanvasWidget(
                  widgetData: w,
                  mqttTopic: widget.device['mqtt_topic'] ?? '',
                  onMove: (dx, dy) {
                    setState(() {
                      w['x'] = (w['x'] as double) + dx;
                      w['y'] = (w['y'] as double) + dy;
                    });
                  },
                  onDelete: () {
                    setState(() { placedWidgets.remove(w); });
                  },
                );
              }).toList(),
            ),
    );
  }
}