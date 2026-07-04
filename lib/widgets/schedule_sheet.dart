import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/schedule.dart';
import '../services/schedule_service.dart';

const _cyan = Color(0xFF00D4FF);
const _cardBg = Color(0xFF111827);
const _baseBg = Color(0xFF0D1520);
const _dayChipBg = Color(0xFF1A2433);

class ScheduleSheet extends StatefulWidget {
  final Map widgetData;
  final String mqttTopic;
  final String deviceId;

  const ScheduleSheet({
    super.key,
    required this.widgetData,
    required this.mqttTopic,
    required this.deviceId,
  });

  @override
  State<ScheduleSheet> createState() => _ScheduleSheetState();
}

enum _RepeatMode { once, daily, weekdays, weekends, custom }

class _ScheduleSheetState extends State<ScheduleSheet> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  // Seconds are now handled automatically in the background to avoid
  // collisions between schedules set in the same minute. No UI slider.
  int _autoSecond = 0;

  // For dropdown-based widgets (toggle, dpad)
  String _selectedCommand = 'ON';

  // For numeric-value widgets (slider, volume, gauge, steering)
  final TextEditingController _valueCtrl = TextEditingController(text: '0');

  // For joystick (two numeric values)
  final TextEditingController _valueXCtrl = TextEditingController(text: '0');
  final TextEditingController _valueYCtrl = TextEditingController(text: '0');

  // For volume: numeric vs MUTE/UNMUTE toggle
  bool _volumeMuteMode = false;
  String _volumeMuteCommand = 'MUTE';

  bool _alternateMode = false;
  int _alternateInterval = 1;
  String _alternateUnit = 'seconds';
  int _alternateCount = 10;

  // Recurrence
  _RepeatMode _repeatMode = _RepeatMode.once;
  final Set<int> _customDays = {}; // 0=Sunday ... 6=Saturday

  bool _loading = false;

  static const List<String> _dayLabels = [
    'S', 'M', 'T', 'W', 'T', 'F', 'S'
  ];

  String get _type => widget.widgetData['type'] ?? 'toggle';

  bool get _isDropdownType => _type == 'toggle' || _type == 'dpad';
  bool get _isSingleNumericType =>
      _type == 'slider' || _type == 'gauge' || _type == 'steering';
  bool get _isVolumeType => _type == 'volume';
  bool get _isJoystickType => _type == 'joystick';
  bool get _isButtonType => _type == 'button';

  List<String> get _commands {
    switch (_type) {
      case 'toggle':
        return ['ON', 'OFF'];
      case 'dpad':
        return ['FWD', 'BCK', 'LEFT', 'RIGHT'];
      default:
        return ['ON', 'OFF'];
    }
  }

  double get _numericMin => _type == 'steering' ? -135 : 0;
  double get _numericMax => _type == 'steering' ? 135 : 100;

  String _buildNumericCommand(String rawValue) {
    final v = double.tryParse(rawValue) ?? 0;
    final clamped = v.clamp(_numericMin, _numericMax);
    final intVal = clamped.toInt();
    switch (_type) {
      case 'slider':
        return 'SLIDER:$intVal';
      case 'gauge':
        return 'GAUGE:$intVal';
      case 'steering':
        return 'STEER:$intVal';
      case 'volume':
        return 'VOL:$intVal';
      default:
        return '$intVal';
    }
  }

  String _buildJoystickCommand() {
    final x = (double.tryParse(_valueXCtrl.text) ?? 0).clamp(-100, 100).toInt();
    final y = (double.tryParse(_valueYCtrl.text) ?? 0).clamp(-100, 100).toInt();
    return 'JOY:$x:$y';
  }

  String get _alternateCommand {
    switch (_type) {
      case 'toggle':
        return 'ON|OFF';
      case 'button':
        return 'PRESS|PRESS';
      case 'dpad':
        return '$_selectedCommand|$_selectedCommand';
      case 'slider':
      case 'gauge':
      case 'steering':
        final cmd = _buildNumericCommand(_valueCtrl.text);
        return '$cmd|$cmd';
      case 'volume':
        if (_volumeMuteMode) {
          return '$_volumeMuteCommand|$_volumeMuteCommand';
        }
        final cmd = _buildNumericCommand(_valueCtrl.text);
        return '$cmd|$cmd';
      case 'joystick':
        final cmd = _buildJoystickCommand();
        return '$cmd|JOY:0:0';
      default:
        return 'ON|OFF';
    }
  }

  String _resolveFinalCommand() {
    if (_alternateMode) return _alternateCommand;
    if (_isDropdownType) return _selectedCommand;
    if (_isButtonType) return 'PRESS';
    if (_isJoystickType) return _buildJoystickCommand();
    if (_isVolumeType) {
      return _volumeMuteMode ? _volumeMuteCommand : _buildNumericCommand(_valueCtrl.text);
    }
    if (_isSingleNumericType) return _buildNumericCommand(_valueCtrl.text);
    return _selectedCommand;
  }

  int get _intervalMs {
    if (_alternateUnit == 'seconds') return _alternateInterval * 1000;
    if (_alternateUnit == 'minutes') return _alternateInterval * 60000;
    return _alternateInterval * 1000;
  }

  List<int> get _resolvedRepeatDays {
    switch (_repeatMode) {
      case _RepeatMode.once:
        return [];
      case _RepeatMode.daily:
        return [0, 1, 2, 3, 4, 5, 6];
      case _RepeatMode.weekdays:
        return [1, 2, 3, 4, 5];
      case _RepeatMode.weekends:
        return [0, 6];
      case _RepeatMode.custom:
        return _customDays.toList()..sort();
    }
  }

  bool get _isRecurring => _repeatMode != _RepeatMode.once;

  @override
  void initState() {
    super.initState();
    if (_isDropdownType) {
      _selectedCommand = _commands.first;
    }
    // Auto-assign seconds based on current millisecond fragment to
    // minimize the chance of two schedules landing on the exact same
    // second when created close together.
    _autoSecond = DateTime.now().millisecond % 60;
  }

  @override
  void dispose() {
    _valueCtrl.dispose();
    _valueXCtrl.dispose();
    _valueYCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: _cyan),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _selectedDate = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: _cyan),
        ),
        child: child!,
      ),
    );
    if (t != null) setState(() => _selectedTime = t);
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      // Re-roll the auto second right before saving for extra collision
      // safety if the user paused a while on this screen.
      _autoSecond = DateTime.now().millisecond % 60;

      final scheduled = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
        _autoSecond,
      );

      final schedule = Schedule(
        deviceId: widget.deviceId,
        widgetId: widget.widgetData['id']?.toString() ??
            widget.widgetData['label'],
        widgetLabel: widget.widgetData['label'],
        mqttTopic: widget.mqttTopic,
        command: _resolveFinalCommand(),
        scheduledAt: scheduled,
        alternateMode: _alternateMode,
        alternateInterval: _intervalMs,
        alternateCount: _alternateCount,
        isRecurring: _isRecurring,
        repeatDays: _resolvedRepeatDays,
      );

      await ScheduleService.createSchedule(schedule);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Schedule saved!',
                style: GoogleFonts.orbitron(color: _cyan)),
            backgroundColor: _cardBg,
          ),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 16),
        child: Text(text,
            style: GoogleFonts.orbitron(
                color: _cyan, fontSize: 10, letterSpacing: 2)),
      );

  Widget _cyanBox(Widget child, {Color? borderColor}) => Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: (borderColor ?? _cyan).withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: child,
      );

  Widget _numericField(TextEditingController ctrl, String label) {
    return _cyanBox(Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.rajdhani(color: Colors.grey, fontSize: 13)),
        SizedBox(
          width: 100,
          child: TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            textAlign: TextAlign.right,
            style: GoogleFonts.orbitron(color: Colors.white, fontSize: 16),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    ));
  }

  Widget _buildCommandSection() {
    if (_isButtonType) {
      return _cyanBox(Text('Command: PRESS',
          style: GoogleFonts.orbitron(color: Colors.white, fontSize: 13)));
    }

    if (_isDropdownType) {
      return _cyanBox(DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCommand,
          isExpanded: true,
          dropdownColor: _cardBg,
          style: GoogleFonts.orbitron(color: Colors.white, fontSize: 12),
          items: _commands
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) => setState(() => _selectedCommand = v!),
        ),
      ));
    }

    if (_isVolumeType) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cyanBox(Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mute / Unmute mode',
                  style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 14)),
              Switch(
                value: _volumeMuteMode,
                activeThumbColor: _cyan,
                onChanged: (v) => setState(() => _volumeMuteMode = v),
              ),
            ],
          )),
          const SizedBox(height: 10),
          if (_volumeMuteMode)
            _cyanBox(DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _volumeMuteCommand,
                isExpanded: true,
                dropdownColor: _cardBg,
                style: GoogleFonts.orbitron(color: Colors.white, fontSize: 12),
                items: ['MUTE', 'UNMUTE']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _volumeMuteCommand = v!),
              ),
            ))
          else
            _numericField(_valueCtrl, 'Volume (0-100)'),
        ],
      );
    }

    if (_isJoystickType) {
      return Column(
        children: [
          _numericField(_valueXCtrl, 'X (-100 to 100)'),
          const SizedBox(height: 10),
          _numericField(_valueYCtrl, 'Y (-100 to 100)'),
        ],
      );
    }

    if (_isSingleNumericType) {
      String label = _type == 'steering' ? 'Angle (-135 to 135)' : 'Value (0-100)';
      return _numericField(_valueCtrl, label);
    }

    return _cyanBox(DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _selectedCommand,
        isExpanded: true,
        dropdownColor: _cardBg,
        style: GoogleFonts.orbitron(color: Colors.white, fontSize: 12),
        items: _commands
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(),
        onChanged: (v) => setState(() => _selectedCommand = v!),
      ),
    ));
  }

  Widget _repeatModeChip(_RepeatMode mode, String label) {
    final selected = _repeatMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _repeatMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? _cyan.withValues(alpha: 0.15) : _dayChipBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _cyan : Colors.grey.withValues(alpha: 0.25),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.orbitron(
            color: selected ? _cyan : Colors.grey,
            fontSize: 10,
            letterSpacing: 1,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _dayChip(int dayIndex) {
    final selected = _customDays.contains(dayIndex);
    return GestureDetector(
      onTap: () => setState(() {
        if (selected) {
          _customDays.remove(dayIndex);
        } else {
          _customDays.add(dayIndex);
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? _cyan : _dayChipBg,
          border: Border.all(
            color: selected ? _cyan : Colors.grey.withValues(alpha: 0.3),
          ),
          boxShadow: selected
              ? [BoxShadow(color: _cyan.withValues(alpha: 0.4), blurRadius: 10)]
              : [],
        ),
        child: Text(
          _dayLabels[dayIndex],
          style: GoogleFonts.orbitron(
            color: selected ? _baseBg : Colors.grey,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildRepeatSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _repeatModeChip(_RepeatMode.once, 'ONCE'),
            _repeatModeChip(_RepeatMode.daily, 'DAILY'),
            _repeatModeChip(_RepeatMode.weekdays, 'WEEKDAYS'),
            _repeatModeChip(_RepeatMode.weekends, 'WEEKENDS'),
            _repeatModeChip(_RepeatMode.custom, 'CUSTOM'),
          ],
        ),
        if (_repeatMode == _RepeatMode.custom) ...[
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) => _dayChip(i)),
          ),
        ],
        if (_isRecurring) ...[
          const SizedBox(height: 10),
          Text(
            'This schedule will repeat every selected day at the same time.',
            style: GoogleFonts.rajdhani(
                color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.widgetData['color'] as int);

    return Container(
      decoration: BoxDecoration(
        color: _baseBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: color, width: 1.5)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text('SCHEDULE WIDGET',
                  style: GoogleFonts.orbitron(
                      color: color, fontSize: 13, letterSpacing: 2)),
            ),
            Center(
              child: Text(widget.widgetData['label'],
                  style: GoogleFonts.rajdhani(
                      color: Colors.grey, fontSize: 13)),
            ),

            // DATE
            _sectionLabel('DATE'),
            GestureDetector(
              onTap: _pickDate,
              child: _cyanBox(Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selectedDate.year} / '
                    '${_selectedDate.month.toString().padLeft(2, '0')} / '
                    '${_selectedDate.day.toString().padLeft(2, '0')}',
                    style: GoogleFonts.orbitron(
                        color: Colors.white, fontSize: 14),
                  ),
                  const Icon(Icons.calendar_today, color: _cyan, size: 18),
                ],
              )),
            ),

            // TIME (seconds handled automatically, no slider)
            _sectionLabel('TIME'),
            GestureDetector(
              onTap: _pickTime,
              child: _cyanBox(Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selectedTime.hour.toString().padLeft(2, '0')} : '
                    '${_selectedTime.minute.toString().padLeft(2, '0')}',
                    style: GoogleFonts.orbitron(
                        color: Colors.white, fontSize: 14),
                  ),
                  const Icon(Icons.access_time, color: _cyan, size: 18),
                ],
              )),
            ),

            // REPEAT
            _sectionLabel('REPEAT'),
            _buildRepeatSection(),

            // COMMAND
            if (!_alternateMode) ...[
              _sectionLabel('COMMAND'),
              _buildCommandSection(),
            ],

            // ALTERNATE MODE - polished card
            _sectionLabel('ALTERNATE / BLINK MODE'),
            Container(
              decoration: BoxDecoration(
                color: _alternateMode
                    ? _cyan.withValues(alpha: 0.06)
                    : _cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _alternateMode
                      ? _cyan.withValues(alpha: 0.6)
                      : _cyan.withValues(alpha: 0.25),
                  width: _alternateMode ? 1.4 : 1,
                ),
                boxShadow: _alternateMode
                    ? [BoxShadow(color: _cyan.withValues(alpha: 0.15), blurRadius: 16)]
                    : [],
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bolt_rounded,
                              color: _alternateMode ? _cyan : Colors.grey,
                              size: 18),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Enable alternating',
                                  style: GoogleFonts.rajdhani(
                                      color: Colors.white, fontSize: 14)),
                              Text('e.g. ON → OFF → ON → OFF...',
                                  style: GoogleFonts.rajdhani(
                                      color: Colors.grey, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                      Switch(
                        value: _alternateMode,
                        activeThumbColor: _cyan,
                        onChanged: (v) => setState(() => _alternateMode = v),
                      ),
                    ],
                  ),
                  if (_alternateMode) ...[
                    const Divider(color: Color(0xFF223349), height: 22),
                    Text('VALUES',
                        style: GoogleFonts.orbitron(
                            color: _cyan, fontSize: 9, letterSpacing: 2)),
                    const SizedBox(height: 10),
                    _buildCommandSection(),
                    const SizedBox(height: 16),
                    Text('INTERVAL',
                        style: GoogleFonts.orbitron(
                            color: _cyan, fontSize: 9, letterSpacing: 2)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Every $_alternateInterval $_alternateUnit',
                                  style: GoogleFonts.orbitron(
                                      color: Colors.white, fontSize: 12)),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: _cyan,
                                  inactiveTrackColor: _cyan.withValues(alpha: 0.2),
                                  thumbColor: _cyan,
                                ),
                                child: Slider(
                                  value: _alternateInterval.toDouble(),
                                  min: 1,
                                  max: 60,
                                  divisions: 59,
                                  onChanged: (v) => setState(
                                      () => _alternateInterval = v.toInt()),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _alternateUnit,
                            dropdownColor: _cardBg,
                            style: GoogleFonts.orbitron(
                                color: _cyan, fontSize: 10),
                            items: ['seconds', 'minutes']
                                .map((u) => DropdownMenuItem(
                                    value: u, child: Text(u)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _alternateUnit = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('REPEAT COUNT: $_alternateCount times',
                        style: GoogleFonts.orbitron(
                            color: _cyan, fontSize: 9, letterSpacing: 2)),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _cyan,
                        inactiveTrackColor: _cyan.withValues(alpha: 0.2),
                        thumbColor: _cyan,
                      ),
                      child: Slider(
                        value: _alternateCount.toDouble(),
                        min: 1,
                        max: 100,
                        divisions: 99,
                        onChanged: (v) =>
                            setState(() => _alternateCount = v.toInt()),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // SAVE BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cyan,
                  foregroundColor: _baseBg,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('SAVE SCHEDULE',
                        style: GoogleFonts.orbitron(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}