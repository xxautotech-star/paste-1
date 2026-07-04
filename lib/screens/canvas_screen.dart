import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../widgets/widget_picker.dart';
import '../widgets/canvas_widget.dart';
import '../widgets/schedule_sheet.dart';
import 'credentials_screen.dart';
import '../models/schedule.dart';
import '../services/schedule_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CanvasScreen extends StatefulWidget {
  final Map device;
  const CanvasScreen({super.key, required this.device});

  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends State<CanvasScreen> {
  List<Map> placedWidgets = [];
  List<Map> localShapes = [];
  bool _loading = true;
  bool _editMode = false;

  static double _defaultW(String type) => 300;
  static double _defaultH(String type) {
    switch (type) {
      case 'dpad': return 220;
      case 'joystick': return 230;
      case 'button': return 220;
      case 'steering': return 220;
      case 'gauge': return 230;
      case 'pedalset': return 220;
      case 'countdown': return 200;
      default: return 180;
    }
  }

  static double _minW(String type) {
    switch (type) {
      case 'dpad': return 180;
      case 'joystick': return 190;
      case 'button': return 160;
      case 'steering': return 180;
      case 'gauge': return 180;
      case 'slider': return 160;
      case 'volume': return 160;
      case 'pedalset': return 220;
      case 'countdown': return 180;
      default: return 140;
    }
  }

  static double _minH(String type) {
    switch (type) {
      case 'dpad': return 200;
      case 'joystick': return 210;
      case 'button': return 200;
      case 'steering': return 200;
      case 'gauge': return 210;
      case 'slider': return 120;
      case 'volume': return 140;
      case 'pedalset': return 180;
      case 'countdown': return 160;
      default: return 120;
    }
  }

  void _openScheduleOverview() {
    final deviceId = widget.device['id'].toString();
    final mqttTopic = widget.device['mqtt_topic'] ?? '';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ScheduleOverviewSheet(
        deviceId: deviceId,
        mqttTopic: mqttTopic,
        placedWidgets: placedWidgets,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadWidgets();
    _loadLocalShapes();
  }

  Future<void> _loadWidgets() async {
    try {
      final deviceId = widget.device['id'].toString();
      final saved = await ApiService.loadWidgets(deviceId);
      setState(() {
        placedWidgets = saved.map((w) {
          final type = w['type'] ?? 'toggle';
          return <String, dynamic>{
            'type': type,
            'label': w['label'] ?? 'Widget',
            'iconCode': w['iconCode'] is int
                ? w['iconCode']
                : int.tryParse(w['iconCode'].toString()) ?? 0xe59e,
            'color': w['color'] is int
                ? w['color']
                : int.tryParse(w['color'].toString()) ?? 0xFF00D4FF,
            'x': w['x'] != null
                ? (w['x'] is double ? w['x'] : double.tryParse(w['x'].toString()) ?? 0.0)
                : 0.0,
            'y': w['y'] != null
                ? (w['y'] is double ? w['y'] : double.tryParse(w['y'].toString()) ?? 0.0)
                : 0.0,
            'w': w['w'] != null
                ? (w['w'] is double ? w['w'] : double.tryParse(w['w'].toString()) ?? _defaultW(type))
                : _defaultW(type),
            'h': w['h'] != null
                ? (w['h'] is double ? w['h'] : double.tryParse(w['h'].toString()) ?? _defaultH(type))
                : _defaultH(type),
            'labelHidden': w['labelHidden'] == true,
            'state': w['state'] is Map ? Map<String, dynamic>.from(w['state']) : <String, dynamic>{},
          };
        }).toList();
        _loading = false;
      });
    } catch (e) {
      debugPrint('Load error: $e');
      setState(() => _loading = false);
    }
  }

  String get _shapesKey => 'local_shapes_${widget.device['id']}';

  Future<void> _loadLocalShapes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_shapesKey);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw) as List;
      setState(() {
        localShapes = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    } catch (_) {}
  }

  Future<void> _saveLocalShapes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_shapesKey, jsonEncode(localShapes));
  }

  void _addLocalShape(String type) {
    setState(() {
      localShapes.add({
        'type': type,
        'x': 40.0,
        'y': 40.0,
        'w': type == 'shape_line' ? 160.0 : 120.0,
        'h': type == 'shape_line' ? 4.0 : 120.0,
        'color': 0xFF00D4FF,
        'thickness': 3.0,
        'radius': type == 'shape_rect' ? 12.0 : 0.0,
      });
    });
    _saveLocalShapes();
  }

  void _editShapeStyle(int index) {
    final shape = localShapes[index];
    double thickness = (shape['thickness'] as num).toDouble();
    double radius = (shape['radius'] as num).toDouble();
    Color color = Color(shape['color'] as int);
    final isRect = shape['type'] == 'shape_rect';

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setInner) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SHAPE STYLE',
                  style: GoogleFonts.orbitron(
                      color: const Color(0xFF00D4FF), fontSize: 12, letterSpacing: 2)),
              const SizedBox(height: 16),
              Text('Color', style: GoogleFonts.rajdhani(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: [
                  0xFF00D4FF, 0xFFFF5252, 0xFF22C55E, 0xFFFFD740,
                  0xFFE040FB, 0xFFFF9800, 0xFFFFFFFF,
                ].map((c) {
                  final col = Color(c);
                  return GestureDetector(
                    onTap: () => setInner(() => color = col),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: col,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: color.value == c ? Colors.white : Colors.transparent,
                            width: 2),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text('Thickness: ${thickness.toInt()}',
                  style: GoogleFonts.rajdhani(color: Colors.grey, fontSize: 12)),
              Slider(
                value: thickness,
                min: 1,
                max: 12,
                activeColor: const Color(0xFF00D4FF),
                onChanged: (v) => setInner(() => thickness = v),
              ),
              if (isRect) ...[
                Text('Corner Roundness: ${radius.toInt()}',
                    style: GoogleFonts.rajdhani(color: Colors.grey, fontSize: 12)),
                Slider(
                  value: radius,
                  min: 0,
                  max: 60,
                  activeColor: const Color(0xFF00D4FF),
                  onChanged: (v) => setInner(() => radius = v),
                ),
              ],
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  setState(() {
                    localShapes[index]['color'] = color.value;
                    localShapes[index]['thickness'] = thickness;
                    localShapes[index]['radius'] = radius;
                  });
                  _saveLocalShapes();
                  Navigator.pop(ctx);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text('DONE',
                        style: GoogleFonts.orbitron(
                            color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                Text('Widgets saved!',
                    style: GoogleFonts.rajdhani(
                        color: Colors.white, fontSize: 13)),
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
          final type = w['type'] as String;
          if (type.startsWith('shape_')) {
            Navigator.pop(context);
            _addLocalShape(type);
            return;
          }
          final offset = placedWidgets.length * 20.0;
          setState(() {
            placedWidgets.add(Map<String, dynamic>.from({
              'type': type,
              'label': w['label'],
              'iconCode': w['iconCode'],
              'color': w['color'],
              'x': 16.0 + offset,
              'y': 16.0 + offset,
              'w': _defaultW(type),
              'h': _defaultH(type),
              'labelHidden': false,
              'state': <String, dynamic>{},
            }));
          });
          Navigator.pop(context);
          _saveWidgets();
        },
      ),
    );
  }

  void _renameWidget(int index) {
    final controller =
        TextEditingController(text: placedWidgets[index]['label'] as String);
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
              borderSide: const BorderSide(color: Color(0xFF00D4FF)),
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
              setState(
                  () => placedWidgets[index]['label'] = controller.text);
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
        builder: (_) => CredentialsScreen(
          device: widget.device,
          placedWidgets: placedWidgets,
        ),
      ),
    );
  }

  void _deleteDevice() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFFF5252), size: 20),
            const SizedBox(width: 8),
            Text('DELETE DEVICE',
                style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 12,
                    letterSpacing: 1)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${widget.device['name']}"? This cannot be undone.',
          style: GoogleFonts.rajdhani(color: Colors.grey, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL',
                style: GoogleFonts.orbitron(
                    color: Colors.grey, fontSize: 10)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final deviceId = widget.device['id'].toString();
                await ApiService.deleteDevice(deviceId);
                if (mounted) {
                  Navigator.popUntil(
                      context, (route) => route.isFirst);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF111827),
                      content: Text('Failed to delete device',
                          style: GoogleFonts.rajdhani(
                              color: Colors.white)),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('DELETE',
                style: GoogleFonts.orbitron(
                    color: Colors.white, fontSize: 10)),
          ),
        ],
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
        leading: const BackButton(color: Color(0xFF00D4FF)),
        title: Text(
          deviceName.toUpperCase(),
          style: GoogleFonts.orbitron(
              fontSize: 13, color: Colors.white, letterSpacing: 1),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF1E2D45)),
        ),
        actions: [
          _NavIcon(
            icon: Icons.lock_outline,
            color: const Color(0xFF00D4FF),
            onTap: _openCredentials,
          ),
          _NavIcon(
            icon: Icons.close,
            color: const Color(0xFFFF5252),
            onTap: _deleteDevice,
          ),
          _NavIcon(
            icon: Icons.schedule_rounded,
            color: const Color(0xFF00D4FF),
            onTap: _openScheduleOverview,
          ),
          _NavIcon(
            icon: Icons.edit_outlined,
            color: _editMode ? const Color(0xFF22C55E) : const Color(0xFF00D4FF),
            onTap: () {
              setState(() => _editMode = !_editMode);
              if (!_editMode) _saveWidgets();
            },
          ),
          _NavIcon(
            icon: Icons.add_circle_outline,
            color: const Color(0xFF00D4FF),
            onTap: _openWidgetPicker,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00D4FF)))
          : placedWidgets.isEmpty
              ? _buildEmptyState()
              : _buildCanvas(),
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
                    color: const Color(0xFF00D4FF).withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFF00D4FF).withValues(alpha: 0.2)),
                  ),
                  child: const Icon(Icons.widgets_outlined,
                      color: Color(0xFF00D4FF), size: 32),
                ),
                const SizedBox(height: 16),
                Text('No controls yet',
                    style: GoogleFonts.orbitron(
                        color: Colors.white, fontSize: 14)),
                const SizedBox(height: 8),
                Text('Tap + to add a widget',
                    style: GoogleFonts.rajdhani(
                        color: Colors.grey, fontSize: 13)),
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
                            color: const Color(0xFF00D4FF).withValues(alpha: 0.3),
                            blurRadius: 16,
                            spreadRadius: 1),
                      ],
                    ),
                    child: Text(
                      'ADD WIDGET',
                      style: GoogleFonts.orbitron(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCanvas() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasW = constraints.maxWidth;
        final canvasH = constraints.maxHeight;
        return InteractiveViewer(
          constrained: true,
          boundaryMargin: EdgeInsets.zero,
          minScale: 0.5,
          maxScale: 2.0,
          panEnabled: !_editMode,
          scaleEnabled: !_editMode,
          child: SizedBox(
            width: canvasW,
            height: canvasH,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                CustomPaint(
                  size: Size(canvasW, canvasH),
                  painter: _GridPainter(),
                ),
                ...localShapes.asMap().entries.map((entry) {
                  final i = entry.key;
                  final s = entry.value;
                  return _ResizableShape(
                    key: ValueKey('shape_$i'),
                    shape: s,
                    editMode: _editMode,
                    maxW: canvasW,
                    maxH: canvasH,
                    onEdit: () => _editShapeStyle(i),
                    onDelete: () {
                      setState(() => localShapes.removeAt(i));
                      _saveLocalShapes();
                    },
                    onUpdate: (x, y, w2, h2) {
                      setState(() {
                        localShapes[i]['x'] = x;
                        localShapes[i]['y'] = y;
                        localShapes[i]['w'] = w2;
                        localShapes[i]['h'] = h2;
                      });
                      _saveLocalShapes();
                    },
                  );
                }),
                ...placedWidgets.asMap().entries.map((entry) {
                  final index = entry.key;
                  final w = entry.value;
                  final type = w['type'] as String;
                  final typeIndex = placedWidgets
                      .sublist(0, index)
                      .where((pw) => pw['type'] == type)
                      .length + 1;
                  final typeTotal = placedWidgets
                      .where((pw) => pw['type'] == type)
                      .length;
                  return _ResizableWidget(
                    key: ValueKey('widget_$index'),
                    widgetData: w,
                    mqttTopic: widget.device['mqtt_topic'] ?? '',
                    deviceId: widget.device['id'].toString(),
                    mqttDeviceId: widget.device['device_id']?.toString() ?? '',
                    widgetIndex: index,
                    widgetTypeIndex: typeIndex,
                    widgetTypeTotal: typeTotal,
                    editMode: _editMode,
                    minW: _minW(w['type'] as String),
                    minH: _minH(w['type'] as String),
                    maxW: canvasW,
                    maxH: canvasH,
                    onDelete: () {
                      setState(() => placedWidgets.removeAt(index));
                      _saveWidgets();
                    },
                    onRename: () => _renameWidget(index),
                    onToggleLabel: () {
                      setState(() {
                        placedWidgets[index]['labelHidden'] =
                            !(placedWidgets[index]['labelHidden'] == true);
                      });
                      _saveWidgets();
                    },
                    onUpdate: (x, y, nw, nh) {
                      setState(() {
                        placedWidgets[index]['x'] = x;
                        placedWidgets[index]['y'] = y;
                        placedWidgets[index]['w'] = nw;
                        placedWidgets[index]['h'] = nh;
                      });
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E2D45).withValues(alpha: 0.5)
      ..strokeWidth = 1;
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}

class _ResizableWidget extends StatefulWidget {
  final Map widgetData;
  final String mqttTopic;
  final String deviceId;
  final String mqttDeviceId;
  final bool editMode;
  final int widgetTypeIndex;
  final int widgetIndex;
  final int widgetTypeTotal;
  final double minW;
  final double minH;
  final double maxW;
  final double maxH;
  final VoidCallback onDelete;
  final VoidCallback onRename;
  final VoidCallback onToggleLabel;
  final Function(double x, double y, double w, double h) onUpdate;

  const _ResizableWidget({
    super.key,
    required this.widgetData,
    required this.mqttTopic,
    required this.deviceId,
    required this.mqttDeviceId,
    required this.editMode,
    required this.widgetTypeIndex,
    required this.widgetIndex,
    required this.minW,
    required this.minH,
    required this.widgetTypeTotal,
    required this.maxW,
    required this.maxH,
    required this.onDelete,
    required this.onRename,
    required this.onToggleLabel,
    required this.onUpdate,
  });

  @override
  State<_ResizableWidget> createState() => _ResizableWidgetState();
}

class _ResizableWidgetState extends State<_ResizableWidget>
    with SingleTickerProviderStateMixin {
  late double _x;
  late double _y;
  late double _w;
  late double _h;

  double _rawX = 0;
  double _rawY = 0;
  double _rawW = 0;
  double _rawH = 0;

  // Bigger touch target for the visible handle chip.
  static const double _handleVisualSize = 22;
  // Extra invisible padding around the visual chip so it's easy to grab on mobile.
  static const double _handleHitPadding = 20;
  static const double _grid = 40.0;
  // How close (in px) you need to be to a grid line before it pulls you in.
  // Smaller = weaker "attraction", more free-form movement — like rearranging
  // icons on an Android home screen instead of a rigid drafting grid.
  static const double _snapThreshold = 18.0;

  double _snap(double value) {
    final nearest = (value / _grid).round() * _grid;
    return (value - nearest).abs() <= _snapThreshold ? nearest : value;
  }

  late AnimationController _neonCtrl;

  @override
  void initState() {
    super.initState();
    _neonCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _rawX = (widget.widgetData['x'] as double?) ?? 0.0;
    _rawY = (widget.widgetData['y'] as double?) ?? 0.0;
    _rawW = (widget.widgetData['w'] as double?) ?? 280.0;
    _rawH = (widget.widgetData['h'] as double?) ?? 160.0;
    _x = _snap(_rawX);
    _y = _snap(_rawY);
    _w = _snap(_rawW);
    _h = _snap(_rawH);
  }

  @override
  void dispose() {
    _neonCtrl.dispose();
    super.dispose();
  }

  void _onDrag(double dx, double dy) {
    _rawX = (_rawX + dx).clamp(0.0, widget.maxW - _w);
    _rawY = (_rawY + dy).clamp(0.0, widget.maxH - _h);
    setState(() {
      _x = _snap(_rawX);
      _y = _snap(_rawY);
    });
    widget.onUpdate(_x, _y, _w, _h);
  }

  void _resize({double dw = 0, double dh = 0, double dx = 0, double dy = 0}) {
    _rawW = (_rawW + dw).clamp(widget.minW, widget.maxW);
    _rawH = (_rawH + dh).clamp(widget.minH, widget.maxH);
    if (dx != 0) _rawX = (_rawX + dx).clamp(0.0, _rawX + _rawW - widget.minW);
    if (dy != 0) _rawY = (_rawY + dy).clamp(0.0, _rawY + _rawH - widget.minH);
    setState(() {
      _w = _snap(_rawW);
      _h = _snap(_rawH);
      _x = dx != 0 ? _snap(_rawX) : _x;
      _y = dy != 0 ? _snap(_rawY) : _y;
    });
    widget.onUpdate(_x, _y, _w, _h);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _x,
      top: _y,
      width: _w,
      height: _h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CanvasWidget(
              widgetData: widget.widgetData,
              mqttTopic: widget.mqttTopic,
              deviceId: widget.deviceId,
              mqttDeviceId: widget.mqttDeviceId,
              editMode: widget.editMode,
              widgetTypeIndex: widget.widgetTypeIndex,
              widgetTypeTotal: widget.widgetTypeTotal,
              widgetIndex: widget.widgetIndex,
              // Wired up to the same drag logic as before — now driven by
              // the visible drag handle inside CanvasWidget's header row.
              onMove: (dx, dy) => _onDrag(dx, dy),
              onDelete: widget.onDelete,
              onRename: widget.onRename,
              onToggleLabel: widget.onToggleLabel,
            ),
          ),
          if (widget.editMode) ...[
            _handle(Alignment.topLeft,
                (dx, dy) => _resize(dw: -dx, dh: -dy, dx: dx, dy: dy)),
            _handle(Alignment.topCenter,
                (dx, dy) => _resize(dh: -dy, dy: dy)),
            _handle(Alignment.topRight,
                (dx, dy) => _resize(dw: dx, dh: -dy, dy: dy)),
            _handle(Alignment.centerLeft,
                (dx, dy) => _resize(dw: -dx, dx: dx)),
            _handle(Alignment.centerRight,
                (dx, dy) => _resize(dw: dx)),
            _handle(Alignment.bottomLeft,
                (dx, dy) => _resize(dw: -dx, dh: dy, dx: dx)),
            _handle(Alignment.bottomCenter,
                (dx, dy) => _resize(dh: dy)),
            _handle(Alignment.bottomRight,
                (dx, dy) => _resize(dw: dx, dh: dy)),
          ],
        ],
      ),
    );
  }

  // Angle each arrow should point, based on its position on the box —
  // corners point diagonally outward, edge-centers point straight out.
  double _arrowAngle(Alignment alignment) {
    if (alignment == Alignment.topLeft) return -3 * 3.14159 / 4;
    if (alignment == Alignment.topCenter) return -3.14159 / 2;
    if (alignment == Alignment.topRight) return -3.14159 / 4;
    if (alignment == Alignment.centerLeft) return 3.14159;
    if (alignment == Alignment.centerRight) return 0;
    if (alignment == Alignment.bottomLeft) return 3 * 3.14159 / 4;
    if (alignment == Alignment.bottomCenter) return 3.14159 / 2;
    if (alignment == Alignment.bottomRight) return 3.14159 / 4;
    return 0;
  }

  Widget _handle(
      Alignment alignment, void Function(double dx, double dy) onDrag) {
    final hitSize = _handleVisualSize + _handleHitPadding;
    final angle = _arrowAngle(alignment);
    return Align(
      alignment: alignment,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (d) => onDrag(d.delta.dx, d.delta.dy),
        child: Container(
          width: hitSize,
          height: hitSize,
          color: Colors.transparent,
          child: Center(
            child: AnimatedBuilder(
              animation: _neonCtrl,
              builder: (_, _) {
                return Transform.rotate(
                  angle: angle,
                  child: CustomPaint(
                    size: Size(_handleVisualSize, _handleVisualSize),
                    painter: _NeonArrowPainter(color: const Color(0xFF0D47A1)),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
class _NeonArrowPainter extends CustomPainter {
  final Color color;
  _NeonArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Solid filled triangle pointing right; Transform.rotate in the
    // caller aims it in the correct direction per handle position.
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(w * 0.2, h * 0.15)
      ..lineTo(w * 0.85, h * 0.5)
      ..lineTo(w * 0.2, h * 0.85)
      ..close();

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(_NeonArrowPainter old) => old.color != color;
}

class _ResizableShape extends StatefulWidget {
  final Map shape;
  final bool editMode;
  final double maxW;
  final double maxH;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(double x, double y, double w, double h) onUpdate;

  const _ResizableShape({
    super.key,
    required this.shape,
    required this.editMode,
    required this.maxW,
    required this.maxH,
    required this.onEdit,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  State<_ResizableShape> createState() => _ResizableShapeState();
}

class _ResizableShapeState extends State<_ResizableShape> {
  late double _x, _y, _w, _h;

  @override
  void initState() {
    super.initState();
    _x = (widget.shape['x'] as num).toDouble();
    _y = (widget.shape['y'] as num).toDouble();
    _w = (widget.shape['w'] as num).toDouble();
    _h = (widget.shape['h'] as num).toDouble();
  }

  void _onDrag(double dx, double dy) {
    setState(() {
      _x = (_x + dx).clamp(0.0, widget.maxW - _w);
      _y = (_y + dy).clamp(0.0, widget.maxH - _h);
    });
    widget.onUpdate(_x, _y, _w, _h);
  }

  void _onResize(double dw, double dh) {
    final isLine = widget.shape['type'] == 'shape_line';
    setState(() {
      _w = (_w + dw).clamp(20.0, widget.maxW);
      _h = isLine ? _h : (_h + dh).clamp(4.0, widget.maxH);
    });
    widget.onUpdate(_x, _y, _w, _h);
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.shape['type'] as String;
    final color = Color(widget.shape['color'] as int);
    final thickness = (widget.shape['thickness'] as num).toDouble();
    final radius = (widget.shape['radius'] as num).toDouble();

    return Positioned(
      left: _x,
      top: _y,
      width: _w,
      height: _h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: widget.editMode ? widget.onEdit : null,
            onPanUpdate: widget.editMode ? (d) => _onDrag(d.delta.dx, d.delta.dy) : null,
            child: CustomPaint(
              size: Size(_w, _h),
              painter: _ShapePainter(
                  type: type, color: color, thickness: thickness, radius: radius),
            ),
          ),
          if (widget.editMode) ...[
            Positioned(
              top: type == 'shape_line' ? -20 : -10,
              right: -10,
              child: GestureDetector(
                onTap: widget.onDelete,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      color: Color(0xFFFF3B3B), shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                ),
              ),
            ),
            Positioned(
              bottom: type == 'shape_line' ? -20 : -10,
              right: -10,
              child: GestureDetector(
                onPanUpdate: (d) => _onResize(d.delta.dx, d.delta.dy),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      color: Color(0xFF22C55E), shape: BoxShape.circle),
                  child: const Icon(Icons.open_in_full, color: Colors.white, size: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ShapePainter extends CustomPainter {
  final String type;
  final Color color;
  final double thickness;
  final double radius;
  _ShapePainter({required this.type, required this.color, required this.thickness, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    switch (type) {
      case 'shape_circle':
        canvas.drawOval(Rect.fromLTWH(thickness / 2, thickness / 2,
            size.width - thickness, size.height - thickness), paint);
        break;
      case 'shape_rect':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(thickness / 2, thickness / 2,
                size.width - thickness, size.height - thickness),
            Radius.circular(radius),
          ),
          paint,
        );
        break;
      case 'shape_line':
        canvas.drawLine(
            Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
        break;
    }
  }

  @override
  bool shouldRepaint(_ShapePainter old) =>
      old.color != color || old.thickness != thickness || old.radius != radius;
}

// ── SCHEDULE OVERVIEW SHEET ──
class _ScheduleOverviewSheet extends StatefulWidget {
  final String deviceId;
  final String mqttTopic;
  final List<Map> placedWidgets;

  const _ScheduleOverviewSheet({
    required this.deviceId,
    required this.mqttTopic,
    required this.placedWidgets,
  });

  @override
  State<_ScheduleOverviewSheet> createState() => _ScheduleOverviewSheetState();
}

class _ScheduleOverviewSheetState extends State<_ScheduleOverviewSheet> {
  List<Schedule> _schedules = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await ScheduleService.getDeviceSchedules(widget.deviceId);
      setState(() {
        _schedules = list;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _delete(int id) async {
    await ScheduleService.deleteSchedule(id);
    _load();
  }

  Future<void> _toggle(int id) async {
    await ScheduleService.toggleSchedule(id);
    _load();
  }

  String _repeatLabel(List<int> days) {
    if (days.length == 7) return 'Every day';
    if (days.length == 5 && !days.contains(0) && !days.contains(6)) {
      return 'Weekdays';
    }
    if (days.length == 2 && days.contains(0) && days.contains(6)) {
      return 'Weekends';
    }
    const names = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days.map((d) => names[d]).join(', ');
  }

  static IconData _getWidgetIcon(String type) {
    switch (type) {
      case 'toggle':      return Icons.toggle_on;
      case 'slider':      return Icons.tune;
      case 'button':      return Icons.radio_button_checked;
      case 'joystick':    return Icons.games;
      case 'steering':    return Icons.sync_alt;
      case 'volume':      return Icons.volume_up;
      case 'dpad':        return Icons.gamepad;
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
      default:            return Icons.widgets;
    }
  }

  void _openScheduleForWidget(Map widgetData) async {
    final result = await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ScheduleSheet(
          widgetData: widgetData,
          mqttTopic: widget.mqttTopic,
          deviceId: widget.deviceId,
        ),
      ),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF0D1520),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFF00D4FF), width: 1.5)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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
          const SizedBox(height: 16),

          // Title
          Center(
            child: Text('SCHEDULES',
                style: GoogleFonts.orbitron(
                    color: const Color(0xFF00D4FF),
                    fontSize: 13,
                    letterSpacing: 2)),
          ),
          const SizedBox(height: 20),

          // ── SECTION 1: WIDGET PICKER ──
          Text('SCHEDULE A WIDGET',
              style: GoogleFonts.orbitron(
                  color: Colors.grey, fontSize: 9, letterSpacing: 2)),
          const SizedBox(height: 10),

          widget.placedWidgets.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                  ),
                  child: Text('No widgets on canvas yet.',
                      style: GoogleFonts.rajdhani(
                          color: Colors.grey, fontSize: 13)),
                )
              : SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.placedWidgets.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final w = widget.placedWidgets[i];
                      final color = Color(w['color'] as int);
                      final type = w['type'] as String;
                      final label = w['label'] as String;
                      return GestureDetector(
                        onTap: () => _openScheduleForWidget(w),
                        child: Container(
                          width: 72,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: color.withValues(alpha: 0.4), width: 1.2),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getWidgetIcon(type),
                                color: color,
                                size: 26,
                              ),
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4),
                                child: Text(
                                  label,
                                  style: GoogleFonts.rajdhani(
                                      color: Colors.white, fontSize: 10),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

          const SizedBox(height: 20),
          const Divider(color: Color(0xFF1E2D45)),
          const SizedBox(height: 12),

          // ── SECTION 2: ACTIVE SCHEDULES ──
          Text('ACTIVE SCHEDULES',
              style: GoogleFonts.orbitron(
                  color: Colors.grey, fontSize: 9, letterSpacing: 2)),
          const SizedBox(height: 10),

          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF00D4FF)))
                : _schedules.isEmpty
                    ? Center(
                        child: Text('No schedules set yet.',
                            style: GoogleFonts.rajdhani(
                                color: Colors.grey, fontSize: 13)))
                    : ListView.builder(
                        itemCount: _schedules.length,
                        itemBuilder: (_, i) {
                          final s = _schedules[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF111827),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: s.isActive
                                    ? const Color(0xFF00D4FF).withValues(alpha: 0.4)
                                    : Colors.grey.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.schedule_rounded,
                                    color: s.isActive
                                        ? const Color(0xFF00D4FF)
                                        : Colors.grey,
                                    size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(s.widgetLabel,
                                          style: GoogleFonts.orbitron(
                                              color: Colors.white,
                                              fontSize: 10,
                                              letterSpacing: 1)),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${s.scheduledAt.toLocal().toString().substring(0, 16)}  →  ${s.command}',
                                        style: GoogleFonts.rajdhani(
                                            color: Colors.grey,
                                            fontSize: 12),
                                      ),
                                      if (s.alternateMode)
                                        Text(
                                          '⚡ Alternate every ${s.alternateInterval ~/ 1000}s × ${s.alternateCount}',
                                          style: GoogleFonts.rajdhani(
                                              color: const Color(0xFF00D4FF),
                                              fontSize: 11),
                                        ),
                                      if (s.isRecurring)
                                        Text(
                                          '🔁 ${_repeatLabel(s.repeatDays)}',
                                          style: GoogleFonts.rajdhani(
                                              color: const Color(0xFF22C55E),
                                              fontSize: 11),
                                        ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: s.isActive,
                                  activeThumbColor: const Color(0xFF00D4FF),
                                  onChanged: (_) => _toggle(s.id!),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_rounded,
                                      color: Color(0xFFFF3B3B), size: 18),
                                  onPressed: () => _delete(s.id!),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
class _NavIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _NavIcon({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.25),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}