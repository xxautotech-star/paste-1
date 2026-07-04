import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/api_service.dart';

enum CompanionMood { happy, excited, thinking, sleeping, crying, angry, laughing }
enum AppScreen { dashboard, chat, canvas, profile, other }

// ─────────────────────────────────────────────
//  MANAGER
// ─────────────────────────────────────────────
class AiCompanionManager {
  static OverlayEntry? _entry;
  static OverlayEntry? _restoreEntry;
  static final _key = GlobalKey<_AiCompanionWidgetState>();
  static OverlayState? _overlayState;
  static VoidCallback? onDevicesChanged;
  static VoidCallback? onSchedulesChanged;

  static void show(BuildContext context, {AppScreen screen = AppScreen.dashboard}) {
    if (_entry != null) { _key.currentState?.setScreen(screen); return; }
    _overlayState = Overlay.of(context);
    _hideRestoreButton();
    _entry = OverlayEntry(builder: (_) => AiCompanionWidget(key: _key, initialScreen: screen));
    _overlayState!.insert(_entry!);
    Future.delayed(const Duration(seconds: 3), () => _key.currentState?.fetchInsights());
  }

  static void setScreen(AppScreen screen) => _key.currentState?.setScreen(screen);
  static void hide() { _entry?.remove(); _entry = null; }
  static void hideAll() { hide(); _hideRestoreButton(); }
  static void onSignOut(BuildContext context) => _key.currentState?.triggerSignOut();

  static void _showRestoreOnOverlay(OverlayState overlay) {
    _hideRestoreButton();
    _restoreEntry = OverlayEntry(builder: (_) => _RestoreButton(onRestore: () {
      _hideRestoreButton();
      if (_overlayState != null) {
        _entry = OverlayEntry(builder: (_) => AiCompanionWidget(key: _key));
        _overlayState!.insert(_entry!);
        Future.delayed(const Duration(seconds: 3), () => _key.currentState?.fetchInsights());
      }
    }));
    overlay.insert(_restoreEntry!);
  }

  static void _hideRestoreButton() { _restoreEntry?.remove(); _restoreEntry = null; }
}

// ─────────────────────────────────────────────
//  RESTORE BUTTON
// ─────────────────────────────────────────────
class _RestoreButton extends StatefulWidget {
  final VoidCallback onRestore;
  const _RestoreButton({required this.onRestore});
  @override State<_RestoreButton> createState() => _RestoreButtonState();
}

class _RestoreButtonState extends State<_RestoreButton> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _g;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _g = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return Positioned(
      bottom: 120, right: 16,
      child: AnimatedBuilder(
        animation: _g,
        builder: (_, __) => GestureDetector(
          onTap: widget.onRestore,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF00D4FF).withOpacity(_g.value), width: 1.2),
              boxShadow: [BoxShadow(color: const Color(0xFF00D4FF).withOpacity(_g.value * 0.4), blurRadius: 12, spreadRadius: 1)],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('Xx', style: TextStyle(color: Color(0xFF00D4FF), fontSize: 12, fontWeight: FontWeight.bold, decoration: TextDecoration.none, fontFamily: 'Orbitron')),
              const SizedBox(width: 4),
              Text('bot', style: TextStyle(color: const Color(0xFF00D4FF).withOpacity(0.65), fontSize: 11, decoration: TextDecoration.none)),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  COMPANION WIDGET
// ─────────────────────────────────────────────
class AiCompanionWidget extends StatefulWidget {
  final AppScreen initialScreen;
  const AiCompanionWidget({super.key, this.initialScreen = AppScreen.dashboard});
  @override State<AiCompanionWidget> createState() => _AiCompanionWidgetState();
}



class _AiCompanionWidgetState extends State<AiCompanionWidget> with TickerProviderStateMixin, WidgetsBindingObserver {
  double _x = 0, _y = 0;
  bool _positionSet = false, _visible = true, _dismissed = false, _isDragging = false;

  CompanionMood _mood = CompanionMood.happy;
  String _speechText = '';
  bool _showSpeech = false;
  bool _isListening = false;
  bool _showYesNo = false;
  bool _isWavingForAttention = false;
  bool _isStretching = false;
  bool _appInForeground = true;

  List<Map<String, dynamic>> _insights = [];
  int _insightIndex = 0;
  Map<String, dynamic>? _pendingInsight;
  Map<String, dynamic>? _remindLaterInsight;

  // Conversational add device flow
  String _addStep = ''; // 'name', 'board', 'widget', 'confirm'
  String _addName = '';
  String _addBoard = '';
  String _addWidget = '';
  String _addWidgetType = 'toggle';
  String _addIcon = '📡';

  // Conversational delete flow
  String _deleteStep = ''; // 'confirm'
  String _deleteDeviceId = '';
  String _deleteName = '';

  // Survey for schedule
  String _surveyStep = '';
  String _surveyDevice = '';
  String _surveyDeviceId = '';
  String _surveyMqttTopic = '';
  String _surveyCommand = '';
  List<Map<String, dynamic>> _userDevices = [];

  late AnimationController _bobController;
  late AnimationController _handController;
  late AnimationController _pulseController;
  late AnimationController _stretchController;
  late AnimationController _attentionController;
  late Animation<double> _bobAnim;
  late Animation<double> _handAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _stretchAnim;
  late Animation<double> _attentionAnim;

  final FlutterTts _tts = FlutterTts();
  static const _speechChannel = MethodChannel('com.xxsmartsystems.app/speech');

  Timer? _driftTimer, _sleepTimer, _randomMoodTimer, _stretchTimer, _attentionTimer, _remindTimer;
  final _rand = Random();

  static const _cyan = Color(0xFF00D4FF);
  final Map<CompanionMood, Color> _moodColors = {
    CompanionMood.happy: const Color(0xFF00BCD4),
    CompanionMood.excited: const Color(0xFF00E676),
    CompanionMood.thinking: const Color(0xFFAA00FF),
    CompanionMood.sleeping: const Color(0xFF546E7A),
    CompanionMood.crying: const Color(0xFF1565C0),
    CompanionMood.angry: const Color(0xFFF4511E),
    CompanionMood.laughing: const Color(0xFFFFD600),
  };

  @override
  void initState() {
    super.initState();
    _bobController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _handController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _stretchController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _attentionController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400))..repeat(reverse: true);

    _bobAnim = Tween<double>(begin: -6, end: 6).animate(CurvedAnimation(parent: _bobController, curve: Curves.easeInOut));
    _handAnim = Tween<double>(begin: -0.3, end: 0.3).animate(CurvedAnimation(parent: _handController, curve: Curves.easeInOut));
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.1).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _stretchAnim = Tween<double>(begin: 1.0, end: 1.4).animate(CurvedAnimation(parent: _stretchController, curve: Curves.easeInOut));
    _attentionAnim = Tween<double>(begin: -0.4, end: 0.4).animate(CurvedAnimation(parent: _attentionController, curve: Curves.easeInOut));

    _setupTts();
    _startDriftTimer();
    _startSleepTimer();
    _startRandomMoodTimer();
    _startStretchTimer();
    _startAttentionTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_positionSet) {
      final size = MediaQuery.of(context).size;
      _x = size.width - 100;
      _y = size.height * 0.6;
      _positionSet = true;
    }
  }

  void _setupTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.3);
    await _tts.setVolume(1.0);
  }

  void _startDriftTimer() {
    _driftTimer = Timer.periodic(const Duration(seconds: 22), (_) {
      if (!mounted || _dismissed || _isDragging || _isListening) return;
      final size = MediaQuery.of(context).size;
      setState(() {
        _x = 40.0 + _rand.nextDouble() * (size.width - 140);
        _y = 120.0 + _rand.nextDouble() * (size.height - 280);
      });
    });
  }

  void _startSleepTimer() {
    _sleepTimer = Timer(const Duration(minutes: 4), () {
      if (!mounted || _dismissed) return;
      _setMood(CompanionMood.sleeping);
    });
  }

  void _startRandomMoodTimer() {
    _randomMoodTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (!mounted || _dismissed || _mood == CompanionMood.sleeping || _isListening) return;
      final moods = [CompanionMood.happy, CompanionMood.excited, CompanionMood.happy];
      _setMood(moods[_rand.nextInt(moods.length)]);
    });
  }

  void _startStretchTimer() {
    _stretchTimer = Timer.periodic(const Duration(seconds: 50), (_) {
      if (!mounted || _dismissed || _mood == CompanionMood.sleeping || _isListening) return;
      _doStretch();
    });
  }

  void _startAttentionTimer() {
    _attentionTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      if (!mounted || _dismissed || _isListening || _showSpeech) return;
      _waveForAttention();
    });
  }

  void _waveForAttention() async {
    if (_isWavingForAttention) return;
    setState(() => _isWavingForAttention = true);
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) setState(() => _isWavingForAttention = false);
  }

  void _doStretch() async {
    if (_isStretching) return;
    setState(() => _isStretching = true);
    await _stretchController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    await _stretchController.reverse();
    if (mounted) setState(() => _isStretching = false);
  }

  void _resetSleepTimer() {
    _sleepTimer?.cancel();
    _startSleepTimer();
  }

  void setScreen(AppScreen screen) {
    if (!mounted) return;
    final msgs = {
      AppScreen.chat: 'Community chat! See what other Xx developers are up to!',
      AppScreen.canvas: 'Device canvas! All your controls are right here!',
      AppScreen.profile: 'Your profile! Manage your Xx Smart Systems account here!',
    };
    if (msgs.containsKey(screen)) {
      _setMood(CompanionMood.excited);
      _say(msgs[screen]!);
    }
  }

  void triggerSignOut() {
    _setMood(CompanionMood.crying);
    _say("Come back soon! Xx Smart Systems will miss you!");
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) AiCompanionManager.hideAll();
    });
  }

  void _setMood(CompanionMood mood) {
    if (!mounted) return;
    setState(() => _mood = mood);
  }

  Future<void> fetchInsights() async {
    try {
      final data = await ApiService.getAiInsights();
      if (data != null && data['insights'] != null) {
        setState(() {
          _insights = List<Map<String, dynamic>>.from(data['insights']);
          _insightIndex = 0;
        });
        if (_insights.isNotEmpty) {
          await Future.delayed(const Duration(seconds: 2));
          _speakInsight(_insights[0]);
        }
      }
    } catch (_) {}
  }

  // ── Is any automatic voice conversation currently in progress? ──
  // Centralizing this check means every flow (add / delete / survey / a
  // pending yes-no insight like the schedule prompt) behaves identically:
  // once the bot asks a question, the mic re-opens on its own.
  bool get _inVoiceFlow =>
      _addStep.isNotEmpty ||
      _deleteStep.isNotEmpty ||
      _surveyStep.isNotEmpty ||
      _pendingInsight != null;

  void _speakInsight(Map<String, dynamic> insight) {
    final msg = insight['message'] as String? ?? '';
    if (msg.isEmpty) return;
    final type = insight['type'] as String? ?? '';

    if (type == 'joke') { _setMood(CompanionMood.laughing); }
    else if (type == 'device_offline') { _setMood(CompanionMood.angry); }
    else if (type == 'welcome') { _setMood(CompanionMood.excited); }
    else if (type == 'announcement') { _setMood(CompanionMood.thinking); }
    else if (type == 'community_chat') { _setMood(CompanionMood.happy); }
    else { _setMood(_moodFromString(insight['mood'] ?? 'happy')); }

    final isSchedule = type == 'schedule_pattern';
    setState(() {
      _speechText = msg;
      _showSpeech = true;
      _showYesNo = isSchedule;
      if (isSchedule) _pendingInsight = insight;
    });
    _tts.speak(msg);

    if (isSchedule) {
      // Same automatic behavior as every other flow: once the bot finishes
      // asking "should I set this schedule?", the mic opens by itself.
      _tts.setCompletionHandler(() {
        if (mounted && _inVoiceFlow) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) _startListening();
          });
        }
      });
    } else {
      _tts.setCompletionHandler(() {});
      Future.delayed(const Duration(seconds: 9), () {
        if (mounted) setState(() { _showSpeech = false; _showYesNo = false; });
      });
    }
    _resetSleepTimer();
    setState(() => _isWavingForAttention = false);
  }

  // ── VOICE ──
  Future<void> _startListening() async {
    if (_isListening) return;
    await _tts.stop();
    setState(() { _isListening = true; _showYesNo = false; });
    _setMood(CompanionMood.thinking);
    try {
      final result = await _speechChannel.invokeMethod<String>('startSpeech');
      if (result != null && result.isNotEmpty) {
        setState(() { _speechText = result; _showSpeech = true; });
        _processVoiceCommand(result.toLowerCase());
      } else {
        _showTextInput();
      }
    } catch (e) {
      _showTextInput();
    } finally {
      if (mounted) setState(() => _isListening = false);
    }
  }

  void _stopListening() => setState(() => _isListening = false);

  void _processVoiceCommand(String words) {
    _stopListening();

    // ── ADD DEVICE FLOW ──
    if (_addStep == 'name') { _handleAddName(words); return; }
    if (_addStep == 'board') { _handleAddBoard(words); return; }
    if (_addStep == 'widget') { _handleAddWidget(words); return; }
    if (_addStep == 'confirm') { _handleAddConfirm(words); return; }

    // ── DELETE FLOW ──
    if (_deleteStep == 'confirm') { _handleDeleteConfirm(words); return; }

    // ── SCHEDULE SURVEY ──
    if (_surveyStep == 'device') { _handleDeviceAnswer(words); return; }
    if (_surveyStep == 'command') { _handleCommandAnswer(words); return; }
    if (_surveyStep == 'time') { _handleTimeAnswer(words); return; }

    // ── PENDING INSIGHT RESPONSES ──
    if (_pendingInsight != null) {
      if (words.contains('yes') || words.contains('sure') || words.contains('okay') || words.contains('ok') || words.contains('do it')) {
        final type = _pendingInsight!['type'] as String? ?? '';
        if (type == 'schedule_pattern') { _createScheduleFromInsight(_pendingInsight!); return; }
      }
      if (words.contains('no') || words.contains('cancel')) {
        _pendingInsight = null;
        setState(() { _showYesNo = false; _showSpeech = false; });
        _setMood(CompanionMood.happy);
        _say("Okay! No problem. Just tap me anytime!");
        return;
      }
      if (words.contains('later') || words.contains('remind') || words.contains('tomorrow')) {
        _remindLaterInsight = _pendingInsight;
        _pendingInsight = null;
        _setMood(CompanionMood.happy);
        _say("Sure! I will remind you about this tomorrow!");
        setState(() { _showYesNo = false; _showSpeech = false; });
        _remindTimer = Timer(const Duration(hours: 24), () {
          if (mounted && _remindLaterInsight != null) _speakInsight(_remindLaterInsight!);
        });
        return;
      }
    }

    // ── SEND TO GROQ ──
    _setMood(CompanionMood.thinking);
    setState(() { _speechText = "On it..."; _showSpeech = true; });
    ApiService.askXxBot(words).then((result) {
      if (!mounted) return;
      final reply = result['reply'] as String?;
      final action = result['action'] as Map<String, dynamic>?;

      if (action != null) {
        final act = action['action'] as String? ?? '';

        if (act == 'add_device') {
          // start conversational add flow: name -> board -> widget -> confirm
          _addName = action['name'] as String? ?? '';
          _addBoard = action['board_type'] as String? ?? '';
          if (_addName.isEmpty) {
            _addStep = 'name';
            _setMood(CompanionMood.excited);
            _say("Sure! What would you like to name your new device?");
          } else if (_addBoard.isEmpty) {
            _addStep = 'board';
            _setMood(CompanionMood.excited);
            _say("What board type is it? For example, ESP32, Arduino, or ESP8266?");
          } else {
            _addStep = 'widget';
            _setMood(CompanionMood.excited);
            _say("What widget should I add? Say toggle, button, slider, or horn.");
          }

        } else if (act == 'delete_device') {
          _deleteDeviceId = action['device_id'] as String? ?? '';
          _deleteName = action['name'] as String? ?? '';
          _deleteStep = 'confirm';
          _setMood(CompanionMood.angry);
          _say("I will delete $_deleteName. Say yes to confirm or no to cancel.");
          setState(() { _showYesNo = true; });

        } else if (act == 'schedule') {
          _pendingInsight = {
            'type': 'schedule_pattern',
            'widget_label': action['widget'] ?? action['device'] ?? '',
            'device_id': action['device_id'] ?? '',
            'command': action['command'] ?? 'ON',
            'suggested_time': action['time'] ?? '08:00',
            'mqtt_topic': action['mqtt_topic'] ?? '',
          };
          _setMood(CompanionMood.excited);
          _say("Got it! Should I set ${action['device']} to ${action['command']} at ${action['time']} every day?");
          setState(() { _showYesNo = true; });

        } else if (act == 'command') {
          _sendDeviceCommand(action);
        }

      } else if (reply != null && reply.isNotEmpty) {
        // check if Groq is starting an add device flow
        if (reply.toLowerCase().contains('name') && reply.toLowerCase().contains('device')) {
          _addStep = 'name';
          _setMood(CompanionMood.excited);
          _say(reply);
        } else {
          _setMood(CompanionMood.happy);
          _say(reply);
        }
      } else {
        _setMood(CompanionMood.thinking);
        _say("I could not connect right now. Please check your internet!");
      }
    });
  }

  // ── ADD DEVICE CONVERSATION ──
  void _handleAddName(String words) {
    _addName = words.trim();
    _addStep = 'board';
    _setMood(CompanionMood.happy);
    _say("What board type is it? Say ESP32, Arduino, or ESP8266.");
    // mic opens automatically after this question — no tap needed
  }

  void _handleAddBoard(String words) {
    if (words.contains('esp32') || words.contains('esp 32')) { _addBoard = 'ESP32'; }
    else if (words.contains('arduino')) { _addBoard = 'Arduino'; }
    else if (words.contains('esp8266') || words.contains('esp 8266')) { _addBoard = 'ESP8266'; }
    else { _addBoard = 'ESP32'; } // default

    _addStep = 'widget';
    _setMood(CompanionMood.happy);
    _say("What widget should I add? Say toggle, button, slider, or horn.");
    // mic opens automatically after this question — no tap needed
  }

  void _handleAddWidget(String words) {
    if (words.contains('toggle')) { _addWidget = 'Toggle Switch'; _addWidgetType = 'toggle'; }
    else if (words.contains('button')) { _addWidget = 'Button'; _addWidgetType = 'button'; }
    else if (words.contains('slider')) { _addWidget = 'Slider'; _addWidgetType = 'slider'; }
    else if (words.contains('horn')) { _addWidget = 'Horn'; _addWidgetType = 'horn'; }
    else if (words.contains('gear')) { _addWidget = 'Gear Shift'; _addWidgetType = 'gearshift'; }
    else if (words.contains('light')) { _addWidget = 'Headlights'; _addWidgetType = 'headlights'; }
    else if (words.contains('joystick')) { _addWidget = 'Joystick'; _addWidgetType = 'joystick'; }
    else { _addWidget = 'Toggle Switch'; _addWidgetType = 'toggle'; } // default

    _addStep = 'confirm';
    _setMood(CompanionMood.excited);
    _say("I will add $_addName with board $_addBoard and a $_addWidget. Say yes to confirm!");
    setState(() { _showYesNo = true; });
    // mic opens automatically after this question — no tap needed
  }

  void _handleAddConfirm(String words) {
    if (words.contains('yes') || words.contains('sure') || words.contains('ok')) {
      _doAddDevice();
    } else {
      _addStep = '';
      _setMood(CompanionMood.happy);
      _say("Okay! Cancelled. Just tap me anytime!");
      setState(() { _showYesNo = false; _showSpeech = false; });
    }
  }

  // ── DELETE CONFIRMATION ──
  void _handleDeleteConfirm(String words) {
    if (words.contains('yes') || words.contains('sure') || words.contains('ok')) {
      _doDeleteDevice();
    } else {
      _deleteStep = '';
      _setMood(CompanionMood.happy);
      _say("Okay! Device kept safe. Just tap me anytime!");
      setState(() { _showYesNo = false; _showSpeech = false; });
    }
  }

  // ── EXECUTE ADD DEVICE ──
  Future<void> _doAddDevice() async {
    _addStep = '';
    setState(() { _showYesNo = false; });
    _setMood(CompanionMood.thinking);

    // show loading steps
    _say("Step 1... Setting up your device on Xx Smart Systems...");
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    _say("Step 2... Connecting to your platform...");
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    try {
      // NOTE: if ApiService.addDevice already supports a widget/widgetType
      // parameter, pass _addWidgetType through here as well, e.g.:
      //   ApiService.addDevice(_addName, _addBoard, icon: _addIcon,
      //     color: '#00D4FF', widgetType: _addWidgetType);
      final result = await ApiService.addDevice(
        _addName, _addBoard,
        icon: _addIcon,
        color: '#00D4FF',
      );
      if (result['id'] != null || result['device_id'] != null) {
        _setMood(CompanionMood.excited);
        _say("Done! $_addName is now live on your Xx Smart Systems dashboard with a $_addWidget!");
        setState(() { _pendingInsight = null; });
        AiCompanionManager.onDevicesChanged?.call();
      } else {
        _setMood(CompanionMood.angry);
        _say("Something went wrong. Please try adding the device manually!");
      }
    } catch (e) {
      _setMood(CompanionMood.angry);
      _say("Could not add the device right now. Please try again!");
    } finally {
      _addWidget = '';
      _addWidgetType = 'toggle';
    }
  }

  // ── EXECUTE DELETE DEVICE ──
  Future<void> _doDeleteDevice() async {
    _deleteStep = '';
    setState(() { _showYesNo = false; });
    _setMood(CompanionMood.thinking);

    _say("Step 1... Removing $_deleteName...");
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    _say("Step 2... Clearing all data...");
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    try {
      await ApiService.deleteDevice(_deleteDeviceId);
      _setMood(CompanionMood.happy);
      _say("Done! $_deleteName has been removed from your Xx Smart Systems account!");
      setState(() { _pendingInsight = null; });
      AiCompanionManager.onDevicesChanged?.call();
      Future.delayed(const Duration(seconds: 2), () { if (mounted) fetchInsights(); });
    } catch (e) {
      _setMood(CompanionMood.angry);
      _say("Could not remove the device. Please try again!");
    }
  }

  // ── SCHEDULE SURVEY ──
  void _handleDeviceAnswer(String words) {
    Map<String, dynamic>? matched;
    for (final d in _userDevices) {
      final name = (d['name'] as String).toLowerCase();
      if (words.contains(name)) { matched = d; break; }
      for (final w in words.split(' ')) {
        if (w.length > 2 && name.contains(w)) { matched = d; break; }
      }
      if (matched != null) break;
    }
    if (matched == null) {
      final names = _userDevices.map((d) => d['name'] as String).join(', ');
      _say("I did not catch that. Your devices are: $names. Which one?");
      return;
    }
    _surveyDevice = matched['name'] as String;
    _surveyDeviceId = matched['device_id'] as String;
    _surveyMqttTopic = matched['mqtt_topic'] as String? ?? 'devices/$_surveyDeviceId/commands';
    _surveyStep = 'command';
    _setMood(CompanionMood.happy);
    _say("Got it! $_surveyDevice. Should I turn it ON or OFF?");
  }

  void _handleCommandAnswer(String words) {
    if (words.contains('on') || words.contains('start')) { _surveyCommand = 'ON'; }
    else if (words.contains('off') || words.contains('stop')) { _surveyCommand = 'OFF'; }
    else { _say("Please say ON or OFF."); return; }
    _surveyStep = 'time';
    _setMood(CompanionMood.excited);
    _say("$_surveyCommand it is! What time? Say something like 7 AM.");
  }

  void _handleTimeAnswer(String words) {
    final parsed = _parseTimeFromWords(words);
    if (parsed == null) { _say("I did not catch the time. Say something like 7 AM."); return; }
    _surveyStep = '';
    final timeStr = '${parsed['hour'].toString().padLeft(2,'0')}:${parsed['minute'].toString().padLeft(2,'0')}';
    _pendingInsight = {
      'type': 'schedule_pattern', 'widget_label': _surveyDevice,
      'device_id': _surveyDeviceId, 'command': _surveyCommand,
      'suggested_time': timeStr, 'mqtt_topic': _surveyMqttTopic,
    };
    _setMood(CompanionMood.thinking);
    _say("Should I set $_surveyDevice to $_surveyCommand at $timeStr every day?");
    setState(() { _showYesNo = true; });
  }

  Map<String, int>? _parseTimeFromWords(String words) {
    int? hour; int minute = 0;
    bool isPm = words.contains('pm') || words.contains('evening') || words.contains('night');
    bool isAm = words.contains('am') || words.contains('morning');
    final numWords = {'one':1,'two':2,'three':3,'four':4,'five':5,'six':6,'seven':7,'eight':8,'nine':9,'ten':10,'eleven':11,'twelve':12,'thirteen':13,'fourteen':14,'fifteen':15,'sixteen':16,'seventeen':17,'eighteen':18,'nineteen':19,'twenty':20,'thirty':30,'forty':40,'fifty':50,'half':30};
    final colonMatch = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(words);
    if (colonMatch != null) {
      hour = int.tryParse(colonMatch.group(1)!); minute = int.tryParse(colonMatch.group(2)!) ?? 0;
    } else {
      int? wH; int wM = 0;
      for (final e in numWords.entries) {
        if (words.contains(e.key)) {
          if (wH == null && e.value <= 12) { wH = e.value; }
          else if (e.value >= 15) { wM += e.value; }
          else if (wH != null) { wM += e.value; }
        }
      }
      if (wH != null) { hour = wH; minute = wM; }
      if (hour == null) {
        final m = RegExp(r'\b(\d{1,2})\b').firstMatch(words);
        if (m != null) hour = int.tryParse(m.group(1)!);
      }
    }
    if (hour == null) return null;
    if (isPm && hour < 12) hour += 12;
    if (isAm && hour == 12) hour = 0;
    return {'hour': hour % 24, 'minute': minute > 59 ? 0 : minute};
  }

  Future<void> _createScheduleFromInsight(Map<String, dynamic> insight) async {
    _setMood(CompanionMood.thinking);
    setState(() { _showYesNo = false; });

    _say("Step 1... Setting up your schedule...");
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    _say("Step 2... Saving to your Xx Smart Systems account...");
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    try {
      final timeStr = insight['suggested_time'] as String? ?? '08:00';
      final parts = timeStr.split(':');
      final hour = int.tryParse(parts[0]) ?? 8;
      final minute = int.tryParse(parts[1]) ?? 0;
      final now = DateTime.now();
      final scheduledAt = DateTime(now.year, now.month, now.day, hour, minute);
      final result = await ApiService.createScheduleFromBot(
        deviceId: insight['device_id'] ?? '',
        widgetLabel: insight['widget_label'] ?? '',
        mqttTopic: 'devices/${insight['device_id'] ?? ''}/commands',
        command: insight['command'] ?? 'ON',
        scheduledAt: scheduledAt,
      );
      if (result) {
        _setMood(CompanionMood.excited);
        _say("Done! Your schedule is now active on Xx Smart Systems. Check your schedules to see it!");
        setState(() { _pendingInsight = null; _showSpeech = false; });
        AiCompanionManager.onSchedulesChanged?.call();
      } else {
        _setMood(CompanionMood.angry);
        _say("Something went wrong. Please try setting the schedule manually!");
      }
    } catch (e) {
      _setMood(CompanionMood.angry);
      _say("Could not create the schedule. Please try again!");
    }
  }

  Future<void> _sendDeviceCommand(Map<String, dynamic> action) async {
    try {
      final topic = action['mqtt_topic'] as String? ?? '';
      final command = action['command'] as String? ?? 'ON';
      await ApiService.sendCommand(topic, command);
      _setMood(CompanionMood.excited);
      _say("Done! Command sent to your device!");
    } catch (e) {
      _setMood(CompanionMood.angry);
      _say("Could not send the command. Please try manually!");
    }
  }

  CompanionMood _moodFromString(String s) {
    switch (s) {
      case 'excited': return CompanionMood.excited;
      case 'thinking': return CompanionMood.thinking;
      case 'sleeping': return CompanionMood.sleeping;
      case 'crying': return CompanionMood.crying;
      case 'angry': return CompanionMood.angry;
      case 'laughing': return CompanionMood.laughing;
      default: return CompanionMood.happy;
    }
  }

  void _onTap() {
  _resetSleepTimer();
  setState(() => _isWavingForAttention = false);

  // if already listening — stop
  if (_isListening) { _stopListening(); return; }

  // if in the middle of ANY conversation flow — continue it
  // (this only matters if the user taps manually; normally the mic
  // re-opens automatically without needing a tap at all)
  if (_inVoiceFlow) {
    _startListening();
    return;
  }

  // if speaking — stop and listen
  if (_showSpeech && !_isListening) {
    _tts.stop();
    setState(() => _showSpeech = false);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _startListening();
    });
    return;
  }

  // if sleeping — wake and listen
  if (_mood == CompanionMood.sleeping) {
    _setMood(CompanionMood.happy);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _startListening();
    });
    return;
  }

  // normal tap
  _startListening();
}

  void _showTextInput() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0A0E1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Talk to Xx Bot', style: TextStyle(color: Color(0xFF00D4FF), fontSize: 14, fontFamily: 'Orbitron', decoration: TextDecoration.none)),
        content: TextField(
          controller: controller, autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Type your message...',
            hintStyle: const TextStyle(color: Colors.white38),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: const Color(0xFF00D4FF).withOpacity(0.3))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF00D4FF))),
          ),
          onSubmitted: (text) { Navigator.pop(context); if (text.trim().isNotEmpty) _processVoiceCommand(text.trim().toLowerCase()); },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white38))),
          TextButton(
            onPressed: () { final text = controller.text.trim(); Navigator.pop(context); if (text.isNotEmpty) _processVoiceCommand(text.toLowerCase()); },
            child: const Text('Send', style: TextStyle(color: Color(0xFF00D4FF))),
          ),
        ],
      ),
    );
  }

void _say(String text) {
  setState(() { _speechText = text; _showSpeech = true; _showYesNo = false; });
  _tts.speak(text);

  // If we're in ANY conversation flow (add device, delete device, schedule
  // survey, or a pending yes/no like the schedule confirmation), the mic
  // re-opens automatically after the bot finishes speaking. The user only
  // ever has to tap once, at the very start.
  if (_inVoiceFlow) {
    _tts.setCompletionHandler(() {
      if (mounted && _inVoiceFlow) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _startListening();
        });
      }
    });
  } else {
    _tts.setCompletionHandler(() {});
    Future.delayed(const Duration(seconds: 9), () {
      if (mounted) setState(() => _showSpeech = false);
    });
  }
}

  void _onYes() {
    if (_addStep == 'confirm') { _doAddDevice(); return; }
    if (_deleteStep == 'confirm') { _doDeleteDevice(); return; }
    if (_pendingInsight != null) {
      final type = _pendingInsight!['type'] as String? ?? '';
      if (type == 'schedule_pattern') _createScheduleFromInsight(_pendingInsight!);
    }
  }

  void _onNo() {
    _addStep = ''; _deleteStep = '';
    _pendingInsight = null;
    setState(() { _showYesNo = false; _showSpeech = false; });
    _setMood(CompanionMood.happy);
    _say("Okay! No problem. Just tap me anytime!");
  }

  void _onRemindLater() {
    if (_pendingInsight != null) {
      _remindLaterInsight = _pendingInsight;
      _pendingInsight = null;
      _setMood(CompanionMood.happy);
      _say("Sure! I will remind you tomorrow!");
      setState(() { _showYesNo = false; _showSpeech = false; });
      _remindTimer = Timer(const Duration(hours: 24), () {
        if (mounted && _remindLaterInsight != null) _speakInsight(_remindLaterInsight!);
      });
    }
  }

  void _onDismiss() {
    _setMood(CompanionMood.crying);
    final overlayContext = Overlay.of(context);
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() { _dismissed = true; _visible = false; });
      AiCompanionManager._entry?.remove();
      AiCompanionManager._entry = null;
      AiCompanionManager._showRestoreOnOverlay(overlayContext);
    });
  }

  @override
  void dispose() {
    _bobController.dispose(); _handController.dispose();
    _pulseController.dispose(); _stretchController.dispose();
    _attentionController.dispose();
    _driftTimer?.cancel(); _sleepTimer?.cancel();
    _randomMoodTimer?.cancel(); _stretchTimer?.cancel();
    _attentionTimer?.cancel(); _remindTimer?.cancel();
    _tts.stop();
    super.dispose();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
void didChangeAppLifecycleState(AppLifecycleState state) {
  _appInForeground = state == AppLifecycleState.resumed;
  if (state == AppLifecycleState.paused || 
      state == AppLifecycleState.inactive) {
    _tts.stop();
    _driftTimer?.cancel();
    _attentionTimer?.cancel();
  }
  if (state == AppLifecycleState.resumed) {
    _startDriftTimer();
    _startAttentionTimer();
  }
}

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    final color = _moodColors[_mood] ?? _cyan;
    return Positioned(
      left: _x, top: _y,
      child: AnimatedOpacity(
        opacity: _visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 500),
        child: GestureDetector(
          onPanStart: (_) {
            _isDragging = true;
            _driftTimer?.cancel();
            HapticFeedback.mediumImpact();
          },
          onPanUpdate: (d) {
            final size = MediaQuery.of(context).size;
            setState(() {
              _x = (_x + d.delta.dx).clamp(0, size.width - 90);
              _y = (_y + d.delta.dy).clamp(0, size.height - 130);
            });
            HapticFeedback.selectionClick();
          },
          onPanEnd: (_) { _isDragging = false; _startDriftTimer(); },
          child: AnimatedBuilder(
            animation: Listenable.merge([_bobAnim, _handAnim, _pulseAnim, _stretchAnim, _attentionAnim]),
            builder: (_, __) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (_showSpeech) _buildSpeechBubble(color),
                if (_showSpeech) const SizedBox(height: 4),
                if (_showYesNo) _buildYesNoButtons(color),
                if (_showYesNo) const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _onDismiss,
                    child: Container(
                      width: 18, height: 18,
                      decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.5))),
                      child: Icon(Icons.close, size: 11, color: color),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Transform.translate(
                  offset: Offset(0, _isDragging ? 0 : _bobAnim.value),
                  child: Transform.scale(
                    scaleY: _isStretching ? _stretchAnim.value : 1.0,
                    alignment: Alignment.bottomCenter,
                    child: GestureDetector(
                      onTap: _onTap,
                      child: SizedBox(
                        width: 80, height: 110,
                        child: CustomPaint(
                          painter: _CompanionPainter(
                            mood: _mood, color: color,
                            handAngle: _handAnim.value, pulse: _pulseAnim.value,
                            time: _bobController.value, isWaving: _isWavingForAttention,
                            attentionAngle: _attentionAnim.value, isListening: _isListening,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_isListening)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withOpacity(0.5)),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.mic, color: Colors.red, size: 10),
                      SizedBox(width: 3),
                      Text('Tap to stop', style: TextStyle(color: Colors.red, fontSize: 9, decoration: TextDecoration.none)),
                    ]),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpeechBubble(Color color) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 210),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.6)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 12, spreadRadius: 1)],
      ),
      child: Text(_speechText, style: TextStyle(color: color, fontSize: 11, height: 1.4, decoration: TextDecoration.none, fontStyle: FontStyle.normal)),
    );
  }

  Widget _buildYesNoButtons(Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _actionBtn('Yes', const Color(0xFF00E676), _onYes),
      const SizedBox(width: 6),
      _actionBtn('Later', const Color(0xFFFFD600), _onRemindLater),
      const SizedBox(width: 6),
      _actionBtn('No', const Color(0xFFF4511E), _onNo),
    ]);
  }

  Widget _actionBtn(String label, Color c, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: c.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.withOpacity(0.7)),
        ),
        child: Text(label, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  PAINTER
// ─────────────────────────────────────────────
class _CompanionPainter extends CustomPainter {
  final CompanionMood mood;
  final Color color;
  final double handAngle, pulse, time, attentionAngle;
  final bool isWaving, isListening;

  _CompanionPainter({required this.mood, required this.color, required this.handAngle, required this.pulse, required this.time, required this.isWaving, required this.attentionAngle, required this.isListening});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    canvas.drawCircle(Offset(cx, 42), 42 * pulse, Paint()..shader = RadialGradient(colors: [color.withOpacity(0.25), Colors.transparent]).createShader(Rect.fromCircle(center: Offset(cx, 42), radius: 42)));
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, 102), width: 40, height: 8), Paint()..color = Colors.black38);
    final fill = Paint()..color = color.withOpacity(0.85);
    final stroke = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5..strokeCap = StrokeCap.round;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx-14, 72, 28, 26), const Radius.circular(8)), fill);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx-14, 72, 28, 26), const Radius.circular(8)), stroke);
    final leftAngle = isWaving ? (-1.2 + attentionAngle * 2) : (-0.4 + handAngle);
    _drawArm(canvas, cx-14, 78, leftAngle, fill, stroke);
    _drawArm(canvas, cx+14, 78, 0.4 - handAngle, fill, stroke);
    canvas.drawCircle(Offset(cx, 38), 34, fill);
    canvas.drawCircle(Offset(cx, 38), 34, stroke);
    canvas.drawCircle(Offset(cx-8, 26), 14, Paint()..color = color.withOpacity(0.15));
    _drawEyes(canvas, cx, 34);
    _drawMouth(canvas, cx, 46);
    _drawAntenna(canvas, cx, stroke);
  }

  void _drawArm(Canvas canvas, double px, double py, double angle, Paint fill, Paint stroke) {
    canvas.save();
    canvas.translate(px, py);
    canvas.rotate(angle);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-4,0,8,18), const Radius.circular(4)), fill);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-4,0,8,18), const Radius.circular(4)), stroke);
    canvas.drawCircle(const Offset(0,24), 7, fill);
    canvas.drawCircle(const Offset(0,24), 7, stroke);
    for (int i=-1; i<=1; i++) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(i*4.0-2.5,19,5,8), const Radius.circular(3)), fill);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(i*4.0-2.5,19,5,8), const Radius.circular(3)), stroke);
    }
    canvas.restore();
  }

  void _drawEyes(Canvas canvas, double cx, double ey) {
    if (mood == CompanionMood.sleeping) {
      final p = Paint()..color = Colors.white70..style = PaintingStyle.stroke..strokeWidth = 2..strokeCap = StrokeCap.round;
      canvas.drawPath(Path()..moveTo(cx-22,ey+2)..quadraticBezierTo(cx-16,ey-4,cx-10,ey+2), p);
      canvas.drawPath(Path()..moveTo(cx+10,ey+2)..quadraticBezierTo(cx+16,ey-4,cx+22,ey+2), p);
      return;
    }
    for (final ex in [cx-16.0, cx+16.0]) {
      canvas.drawOval(Rect.fromCenter(center: Offset(ex,ey), width:14, height:16), Paint()..color=const Color(0xFF0A0E1A));
      if (mood == CompanionMood.angry) {
        final b = Paint()..color=color..strokeWidth=2..style=PaintingStyle.stroke..strokeCap=StrokeCap.round;
        final l = ex < cx;
        canvas.drawLine(Offset(ex+(l?-8:8),ey-12), Offset(ex+(l?4:-4),ey-8), b);
      }
      if (mood == CompanionMood.excited) {
        (TextPainter(text: TextSpan(text:'★', style: TextStyle(color:Colors.yellow[600], fontSize:13)), textDirection:TextDirection.ltr)..layout()).paint(canvas, Offset(ex-7,ey-8));
      } else {
        canvas.drawCircle(Offset(ex+4,ey-3), 3, Paint()..color=Colors.white);
      }
    }
  }

  void _drawMouth(Canvas canvas, double cx, double my) {
    final mp = Paint()..color=const Color(0xFF0A0E1A)..style=PaintingStyle.stroke..strokeWidth=2.2..strokeCap=StrokeCap.round;
    switch (mood) {
      case CompanionMood.happy:
      case CompanionMood.excited:
        canvas.drawArc(Rect.fromCenter(center:Offset(cx,my), width:24, height:14), 0.1, pi-0.2, false, mp); break;
      case CompanionMood.laughing:
        canvas.drawOval(Rect.fromCenter(center:Offset(cx,my+4), width:20, height:12+sin(time*pi*2)*4), Paint()..color=const Color(0xFF0A0E1A));
        canvas.drawOval(Rect.fromCenter(center:Offset(cx,my+6), width:12, height:6), Paint()..color=const Color(0xFFE57373)); break;
      case CompanionMood.crying:
        canvas.drawArc(Rect.fromCenter(center:Offset(cx,my+10), width:20, height:14), pi+0.3, pi-0.6, false, mp);
        final tp = Paint()..color=const Color(0xFF42A5F5);
        final to = (time*40)%50;
        canvas.drawOval(Rect.fromCenter(center:Offset(cx-14,my+to), width:5, height:7), tp);
        canvas.drawOval(Rect.fromCenter(center:Offset(cx+14,my+((to+15)%50)), width:5, height:7), tp); break;
      case CompanionMood.sleeping:
        canvas.drawLine(Offset(cx-8,my+4), Offset(cx+8,my+4), mp);
        (TextPainter(text: TextSpan(children:[TextSpan(text:'z', style:TextStyle(color:color, fontSize:10, fontWeight:FontWeight.bold)), TextSpan(text:'Z', style:TextStyle(color:color, fontSize:13, fontWeight:FontWeight.bold))]), textDirection:TextDirection.ltr)..layout()).paint(canvas, Offset(cx+22,my-20)); break;
      case CompanionMood.thinking:
        canvas.drawLine(Offset(cx-8,my+2), Offset(cx+8,my+2), mp);
        for (int i=0; i<3; i++) canvas.drawCircle(Offset(cx+18+i*6.0,my-14), 2, Paint()..color=color); break;
      case CompanionMood.angry:
        canvas.drawArc(Rect.fromCenter(center:Offset(cx,my+8), width:18, height:10), pi+0.4, pi-0.8, false, mp); break;
    }
  }

  void _drawAntenna(Canvas canvas, double cx, Paint stroke) {
    canvas.drawLine(Offset(cx,4), Offset(cx+4,-14), stroke);
    canvas.drawCircle(Offset(cx+4,-18), 4*pulse, Paint()..color=color.withOpacity(0.5));
    canvas.drawCircle(Offset(cx+4,-18), 3, Paint()..color=color);
  }

  @override
  bool shouldRepaint(_CompanionPainter old) =>
    old.mood!=mood || old.handAngle!=handAngle || old.pulse!=pulse ||
    old.time!=time || old.color!=color || old.isWaving!=isWaving ||
    old.attentionAngle!=attentionAngle || old.isListening!=isListening;
}