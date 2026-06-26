import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../widgets/widget_picker.dart';
import '../widgets/canvas_widget.dart';
import 'credentials_screen.dart';

class CanvasScreen extends StatefulWidget {
  final Map device;
  const CanvasScreen({super.key, required this.device});

  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends State<CanvasScreen> {
  List<Map> placedWidgets = [];
  bool _loading = true;
  bool _editMode = false;

  @override
  void initState() {
    super.initState();
    _loadWidgets();
  }

  Future<void> _loadWidgets() async {
    try {
      final deviceId = widget.device['id'].toString();
      final saved = await ApiService.loadWidgets(deviceId);
      setState(() {
        placedWidgets = saved.map((w) {
  return <String, dynamic>{
    'type': w['type'] ?? 'toggle',
    'label': w['label'] ?? 'Widget',
    'iconCode': w['iconCode'] is int
        ? w['iconCode']
        : int.tryParse(w['iconCode'].toString()) ?? 0xe59e,
    'color': w['color'] is int
        ? w['color']
        : int.tryParse(w['color'].toString()) ?? 0xFF00D4FF,
    'x': 0.0,
    'y': 0.0,
  };
}).toList();
        _loading = false;
      });
    } catch (e) {
      debugPrint('Load error: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _saveWidgets() async {
    try {
      final deviceId = widget.device['id'].toString();
      await ApiService.saveWidgets(deviceId, placedWidgets);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF111827),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            content: Row(
              children: [
                const Icon(Icons.check_circle,
                    color: Color(0xFF22C55E), size: 16),
                const SizedBox(width: 8),
                Text(
                  'Widgets saved!',
                  style: GoogleFonts.rajdhani(
                      color: Colors.white, fontSize: 13),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Save error: $e');
    }
  }

  void _openWidgetPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => WidgetPicker(
        onWidgetSelected: (w) {
          setState(() {
           placedWidgets.add(Map<String, dynamic>.from({
  'type': w['type'],
  'label': w['label'],
  'iconCode': w['iconCode'],
  'color': w['color'],
  'x': 0.0,
  'y': 0.0,
}));
          });
          Navigator.pop(context);
          _saveWidgets();
        },
      ),
    );
  }

  void _renameWidget(int index) {
    final controller = TextEditingController(
        text: placedWidgets[index]['label'] as String);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: Text('Rename Widget',
            style: GoogleFonts.orbitron(
                color: Colors.white, fontSize: 13)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Widget name',
            hintStyle: GoogleFonts.rajdhani(color: Colors.grey),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF1E2D45)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFF00D4FF)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.rajdhani(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                placedWidgets[index]['label'] = controller.text;
              });
              Navigator.pop(context);
              _saveWidgets();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4FF)),
            child: Text('Save',
                style: GoogleFonts.rajdhani(
                    color: Colors.black,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openCredentials() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CredentialsScreen(device: widget.device),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String deviceName = widget.device['name'] ?? 'Device';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        leading: BackButton(color: const Color(0xFF00D4FF)),
        title: Text(
          deviceName.toUpperCase(),
          style: GoogleFonts.orbitron(
            fontSize: 13,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF1E2D45)),
        ),
        actions: [
          // Edit mode toggle
          GestureDetector(
            onTap: () {
              setState(() => _editMode = !_editMode);
              if (!_editMode) _saveWidgets();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _editMode
                    ? const Color(0xFF22C55E).withOpacity(0.15)
                    : const Color(0xFF1A2234),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _editMode
                      ? const Color(0xFF22C55E)
                      : const Color(0xFF1E2D45),
                ),
              ),
              child: Text(
                _editMode ? 'DONE' : 'EDIT',
                style: GoogleFonts.orbitron(
                  fontSize: 9,
                  color: _editMode
                      ? const Color(0xFF22C55E)
                      : Colors.grey,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline,
                color: Color(0xFF00D4FF), size: 24),
            onPressed: _openWidgetPicker,
            tooltip: 'Add Widget',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00D4FF),
              ),
            )
          : placedWidgets.isEmpty
              ? _buildEmptyState()
              : _buildWidgetList(),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4FF).withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00D4FF).withOpacity(0.2),
                    ),
                  ),
                  child: const Icon(Icons.widgets_outlined,
                      color: Color(0xFF00D4FF), size: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  'No controls yet',
                  style: GoogleFonts.orbitron(
                      color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to add a widget',
                  style: GoogleFonts.rajdhani(
                      color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _openWidgetPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D4FF),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF00D4FF).withOpacity(0.3),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Text(
                      'ADD WIDGET',
                      style: GoogleFonts.orbitron(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildCredentialsButton(),
      ],
    );
  }

  Widget _buildWidgetList() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...placedWidgets.asMap().entries.map((entry) {
                final index = entry.key;
                final w = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ResizableWidget(
                    widgetData: w,
                    mqttTopic: widget.device['mqtt_topic'] ?? '',
                    editMode: _editMode,
                    onDelete: () {
                      setState(() => placedWidgets.removeAt(index));
                      _saveWidgets();
                    },
                    onRename: () => _renameWidget(index),
                  ),
                );
              }),
            ],
          ),
        ),
        _buildCredentialsButton(),
      ],
    );
  }

  Widget _buildCredentialsButton() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        border: Border(top: BorderSide(color: Color(0xFF1E2D45))),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: GestureDetector(
        onTap: _openCredentials,
        child: Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFFD740).withOpacity(0.4),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline,
                  color: Color(0xFFFFD740), size: 16),
              const SizedBox(width: 8),
              Text(
                'VIEW CREDENTIALS',
                style: GoogleFonts.orbitron(
                  color: const Color(0xFFFFD740),
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResizableWidget extends StatefulWidget {
  final Map widgetData;
  final String mqttTopic;
  final bool editMode;
  final VoidCallback onDelete;
  final VoidCallback onRename;

  const _ResizableWidget({
    required this.widgetData,
    required this.mqttTopic,
    required this.editMode,
    required this.onDelete,
    required this.onRename,
  });

  @override
  State<_ResizableWidget> createState() => _ResizableWidgetState();
}

class _ResizableWidgetState extends State<_ResizableWidget> {
  double _width = 300;
  double _height = 160;

  static const double _minW = 140;
  static const double _minH = 100;
  static const double _handleSize = 16;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _width,
      height: _height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CanvasWidget(
              widgetData: widget.widgetData,
              mqttTopic: widget.mqttTopic,
              editMode: widget.editMode,
              onMove: (_, __) {},
              onDelete: widget.onDelete,
              onRename: widget.onRename,
            ),
          ),
          if (widget.editMode) ...[
            _handle(Alignment.topLeft,
                (dx, dy) => _resize(dw: -dx, dh: -dy)),
            _handle(Alignment.topRight,
                (dx, dy) => _resize(dw: dx, dh: -dy)),
            _handle(Alignment.bottomLeft,
                (dx, dy) => _resize(dw: -dx, dh: dy)),
            _handle(Alignment.bottomRight,
                (dx, dy) => _resize(dw: dx, dh: dy)),
            _handle(Alignment.topCenter,
                (dx, dy) => _resize(dh: -dy)),
            _handle(Alignment.bottomCenter,
                (dx, dy) => _resize(dh: dy)),
            _handle(Alignment.centerLeft,
                (dx, dy) => _resize(dw: -dx)),
            _handle(Alignment.centerRight,
                (dx, dy) => _resize(dw: dx)),
          ],
        ],
      ),
    );
  }

  void _resize({double dw = 0, double dh = 0}) {
    setState(() {
      _width = (_width + dw).clamp(_minW, double.infinity);
      _height = (_height + dh).clamp(_minH, double.infinity);
    });
  }

  Widget _handle(
      Alignment alignment, void Function(double dx, double dy) onDrag) {
    return Align(
      alignment: alignment,
      child: GestureDetector(
        onPanUpdate: (d) => onDrag(d.delta.dx, d.delta.dy),
        child: Container(
          width: _handleSize,
          height: _handleSize,
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
                color: const Color(0xFF0A0E1A), width: 1.5),
          ),
        ),
      ),
    );
  }
}