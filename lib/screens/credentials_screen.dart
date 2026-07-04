import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class CredentialsScreen extends StatefulWidget {
  final Map device;
  final List<Map> placedWidgets;

  const CredentialsScreen({
    super.key,
    required this.device,
    this.placedWidgets = const [],
  });

  @override
  State<CredentialsScreen> createState() => _CredentialsScreenState();
}

class _CredentialsScreenState extends State<CredentialsScreen> {
  String? _savedPin;
  String _enteredPin = '';
  bool _unlocked = false;
  bool _isSettingPin = false;
  bool _isChangingPin = false;
  String _pendingPin = '';
  bool _confirmStep = false;
  bool _verifyOldPinStep = false;
  String _pinError = '';
  bool _loadingPin = true;

  @override
  void initState() {
    super.initState();
    _loadPin();
  }

  Future<void> _loadPin() async {
    final pin = await ApiService.getPin();
    setState(() {
      _savedPin = pin;
      _loadingPin = false;
    });
  }

  // ── Sketch Generator ─────────────────────────────────────
  String _generateSketch() {
    final authToken = widget.device['auth_token'] ?? 'xxSS-xxxx-xxxx';
    final deviceId = widget.device['device_id'] ?? '000000000000';
    final board = widget.device['board_type'] ?? 'ESP32';
    final wifiBoards = ['ESP32', 'ESP8266'];
    final bridgeBoards = ['Arduino Uno', 'Arduino Mega'];
    final isWifiCapable = wifiBoards.contains(board);
    final isBridgeBoard = bridgeBoards.contains(board);
    final isRaspberryPi = board == 'Raspberry Pi';
    final widgets = widget.placedWidgets;

    if (isRaspberryPi) {
      return '''// ── Raspberry Pi Selected ─────────────────────
// Raspberry Pi runs Linux, not Arduino sketches — this code
// generator only produces Arduino-style .ino files.
// Raspberry Pi support (Python-based) is not built yet.
// Please select ESP32, ESP8266, or another Arduino-compatible
// board to generate working code.
''';
    }

    final pinLines = StringBuffer();
    final channelLines = StringBuffer();
    final setupLines = StringBuffer();
    final commandLines = StringBuffer();
    final restoreLines = StringBuffer();
    int pinCounter = 2;
    int channelCounter = 0;
    int globalIdx = 0;

    // Track count per type for indexing
    final Map<String, int> typeCount = {};

    for (final w in widgets) {
      final type = w['type'] as String;
      globalIdx++;
      typeCount[type] = (typeCount[type] ?? 0) + 1;
      final idx = typeCount[type]!;
      final totalOfType = widgets.where((x) => x['type'] == type).length;
      final suffix = totalOfType > 1 ? '_$idx' : '';

      final rawLabel = (w['label'] as String)
          .toUpperCase()
          .replaceAll(' ', '_')
          .replaceAll(RegExp(r'[^A-Z0-9_]'), '');
      final label = '$rawLabel$suffix';

      // ── PIN DEFINITIONS ──
      switch (type) {
        case 'toggle':
          pinLines.writeln('#define ${label}_PIN  $pinCounter   // Digital output');
          pinCounter++;
          break;
        case 'slider':
          pinLines.writeln('#define ${label}_PIN  $pinCounter   // PWM output (0–255)');
          pinCounter++;
          break;
        case 'button':
          pinLines.writeln('#define ${label}_PIN  $pinCounter   // Digital output');
          pinCounter++;
          break;
        case 'gauge':
          pinLines.writeln('#define ${label}_PIN  $pinCounter   // Analog/PWM feedback');
          pinCounter++;
          break;
        case 'volume':
          pinLines.writeln('#define ${label}_PIN  $pinCounter   // PWM audio/motor');
          pinCounter++;
          break;
        case 'horn':
          pinLines.writeln('#define ${label}_PIN  $pinCounter   // Digital output (buzzer/horn)');
          pinCounter++;
          break;
        case 'headlights':
          pinLines.writeln('#define ${label}_PIN  $pinCounter   // Digital output (lights relay)');
          pinCounter++;
          break;
        case 'turbo':
          pinLines.writeln('#define ${label}_PIN  $pinCounter   // Digital output (turbo relay)');
          pinCounter++;
          break;

        case 'rgb':
          pinLines.writeln('#define ${label}_R_PIN  $pinCounter   // PWM output (Red channel)');
          pinCounter++;
          pinLines.writeln('#define ${label}_G_PIN  $pinCounter   // PWM output (Green channel)');
          pinCounter++;
          pinLines.writeln('#define ${label}_B_PIN  $pinCounter   // PWM output (Blue channel)');
          pinCounter++;
          channelLines.writeln('#define ${label}_R_CH  $channelCounter');
          channelCounter++;
          channelLines.writeln('#define ${label}_G_CH  $channelCounter');
          channelCounter++;
          channelLines.writeln('#define ${label}_B_CH  $channelCounter');
          channelCounter++;
          break;
        case 'fanspeed':
          pinLines.writeln('#define ${label}_PIN  $pinCounter   // PWM output (fan speed)');
          pinCounter++;
          channelLines.writeln('#define ${label}_CH  $channelCounter');
          channelCounter++;
          break;
        case 'graph':
          pinLines.writeln('#define ${label}_SENSOR_PIN  $pinCounter   // Analog input pin for sensor');
          pinCounter++;
          break;
        case 'barchart':
          pinLines.writeln('#define ${label}_SENSOR_PIN  $pinCounter   // Analog input pin for sensor');
          pinCounter++;
          break;
        case 'table':
          pinLines.writeln('// $label — Table (fill values manually in loop(), see comment below)');
          break;
        case 'alarm':
          pinLines.writeln('#define ${label}_PIN  $pinCounter   // Digital output (buzzer/siren)');
          pinCounter++;
          break;
        case 'irblast':
          pinLines.writeln('#define ${label}_PIN  $pinCounter   // Digital output (IR LED)');
          pinCounter++;
          break;
        case 'stopwatch':
          pinLines.writeln('// $label — Stopwatch (no pin needed, software only)');
          break;
        case 'brake':
          pinLines.writeln('#define ${label}_PIN  $pinCounter   // Digital output (brake relay)');
          pinCounter++;
          break;
        case 'accelerator':
          pinLines.writeln('#define ${label}_PIN  $pinCounter   // PWM output (motor speed)');
          pinCounter++;
          break;

          case 'clutch':
          pinLines.writeln('#define ${label}_PIN  $pinCounter   // Digital output (clutch relay/solenoid)');
          pinCounter++;
          break;
        case 'pedalset':
          pinLines.writeln('#define ${label}_CLUTCH_PIN  $pinCounter   // Digital output (clutch)');
          pinCounter++;
          pinLines.writeln('#define ${label}_BRAKE_PIN  $pinCounter   // Digital output (brake relay)');
          pinCounter++;
          pinLines.writeln('#define ${label}_ACCEL_PIN  $pinCounter   // PWM output (accelerator motor)');
          pinCounter++;
          break;
        case 'countdown':
          pinLines.writeln('// $label — Countdown Timer (no pin needed, software only)');
          break;
        case 'gearshift':
          pinLines.writeln('#define ${label}_PIN  $pinCounter   // Digital output (gear signal)');
          pinCounter++;
          channelLines.writeln('#define ${label}_CH  $channelCounter');
          channelCounter++;
          break;
        case 'toggle2':
          pinLines.writeln('#define ${label}_PIN  $pinCounter   // Digital output');
          pinCounter++;
          break;
        case 'doorlock':
          pinLines.writeln('#define ${label}_PIN  $pinCounter   // Digital output (lock relay/solenoid)');
          pinCounter++;
          break;
        case 'servo':
          pinLines.writeln('#define ${label}_PIN  $pinCounter   // PWM output (servo signal)');
          pinCounter++;
          channelLines.writeln('#define ${label}_CH  $channelCounter');
          channelCounter++;
          break;
        case 'start':
          pinLines.writeln('#define ${label}_PIN  $pinCounter   // Digital output (start signal)');
          pinCounter++;
          break;
        case 'stop':
          pinLines.writeln('#define ${label}_PIN  $pinCounter   // Digital output (stop signal)');
          pinCounter++;
          break;
        case 'chup':
        case 'chdown':
        case 'volup':
        case 'voldown':
        case 'muteonly':
          pinLines.writeln('// $label — IR/remote command (no pin needed, sent via IR module if wired)');
          break;
        case 'robotarm':
          pinLines.writeln('#define ${label}_SHOULDER_PIN  $pinCounter   // PWM output (servo)');
          pinCounter++;
          pinLines.writeln('#define ${label}_ELBOW_PIN  $pinCounter   // PWM output (servo)');
          pinCounter++;
          pinLines.writeln('#define ${label}_WRIST_PIN  $pinCounter   // PWM output (servo)');
          pinCounter++;
          channelLines.writeln('#define ${label}_SHOULDER_CH  $channelCounter');
          channelCounter++;
          channelLines.writeln('#define ${label}_ELBOW_CH  $channelCounter');
          channelCounter++;
          channelLines.writeln('#define ${label}_WRIST_CH  $channelCounter');
          channelCounter++;
          break;
        case 'joystick':
        case 'dpad':
        case 'steering':
          pinLines.writeln('#define ${label}_A_PIN  $pinCounter   // Motor A / Left');
          pinCounter++;
          pinLines.writeln('#define ${label}_B_PIN  $pinCounter   // Motor B / Right');
          pinCounter++;
          channelLines.writeln('#define ${label}_A_CH  $channelCounter');
          channelCounter++;
          channelLines.writeln('#define ${label}_B_CH  $channelCounter');
          channelCounter++;
          break;
        case 'dpad2':
          pinLines.writeln('#define ${label}_A_PIN  $pinCounter   // Motor A / Left');
          pinCounter++;
          pinLines.writeln('#define ${label}_B_PIN  $pinCounter   // Motor B / Right');
          pinCounter++;
          pinLines.writeln('#define ${label}_CENTER_PIN  $pinCounter   // Digital output (center button action)');
          pinCounter++;
          channelLines.writeln('#define ${label}_A_CH  $channelCounter');
          channelCounter++;
          channelLines.writeln('#define ${label}_B_CH  $channelCounter');
          channelCounter++;
          break;
      }

      // ── SETUP pinMode ──
      switch (type) {
        case 'joystick':
        case 'dpad':
        case 'steering':
          setupLines.writeln('  pinMode(${label}_A_PIN, OUTPUT);');
          setupLines.writeln('  pinMode(${label}_B_PIN, OUTPUT);');
          setupLines.writeln('  PWM_SETUP(${label}_A_PIN, ${label}_A_CH, 5000, 8);');
          setupLines.writeln('  PWM_SETUP(${label}_B_PIN, ${label}_B_CH, 5000, 8);');
          break;
        case 'dpad2':
          setupLines.writeln('  pinMode(${label}_A_PIN, OUTPUT);');
          setupLines.writeln('  pinMode(${label}_B_PIN, OUTPUT);');
          setupLines.writeln('  pinMode(${label}_CENTER_PIN, OUTPUT);');
          setupLines.writeln('  PWM_SETUP(${label}_A_PIN, ${label}_A_CH, 5000, 8);');
          setupLines.writeln('  PWM_SETUP(${label}_B_PIN, ${label}_B_CH, 5000, 8);');
          break;
        case 'rgb':
          setupLines.writeln('  PWM_SETUP(${label}_R_PIN, ${label}_R_CH, 5000, 8);');
          setupLines.writeln('  PWM_SETUP(${label}_G_PIN, ${label}_G_CH, 5000, 8);');
          setupLines.writeln('  PWM_SETUP(${label}_B_PIN, ${label}_B_CH, 5000, 8);');
          break;
        case 'graph':
          setupLines.writeln('  pinMode(${label}_SENSOR_PIN, INPUT);');
          break;
        case 'barchart':
          setupLines.writeln('  pinMode(${label}_SENSOR_PIN, INPUT);');
          break;
        case 'table':
          break;
        case 'stopwatch':
          break;
        case 'pedalset':
          setupLines.writeln('  pinMode(${label}_CLUTCH_PIN, OUTPUT);');
          setupLines.writeln('  pinMode(${label}_BRAKE_PIN, OUTPUT);');
          setupLines.writeln('  pinMode(${label}_ACCEL_PIN, OUTPUT);');
          break;
        case 'countdown':
          break;
        case 'fanspeed':
          setupLines.writeln('  PWM_SETUP(${label}_PIN, ${label}_CH, 5000, 8);');
          break;
        case 'gearshift':
          setupLines.writeln('  pinMode(${label}_PIN, OUTPUT);');
          setupLines.writeln('  PWM_SETUP(${label}_PIN, ${label}_CH, 5000, 8);');
          break;
        case 'servo':
          setupLines.writeln('  PWM_SETUP(${label}_PIN, ${label}_CH, 50, 16);');
          break;
        case 'chup':
        case 'chdown':
        case 'volup':
        case 'voldown':
        case 'muteonly':
          break;
        case 'robotarm':
          setupLines.writeln('  PWM_SETUP(${label}_SHOULDER_PIN, ${label}_SHOULDER_CH, 50, 16);');
          setupLines.writeln('  PWM_SETUP(${label}_ELBOW_PIN, ${label}_ELBOW_CH, 50, 16);');
          setupLines.writeln('  PWM_SETUP(${label}_WRIST_PIN, ${label}_WRIST_CH, 50, 16);');
          break;
        default:
          setupLines.writeln('  pinMode(${label}_PIN, OUTPUT);');
      }

      // ── COMMAND HANDLER ──
      // indexed command prefix e.g. JOY_2: for second joystick
      final cmdSuffix = totalOfType > 1 ? '_$idx' : '';

      switch (type) {
        case 'toggle':
          commandLines.writeln('''
  // ${w['label']}${suffix.isNotEmpty ? ' #$idx' : ''} — Toggle
  if (cmd == "ON$cmdSuffix")  { digitalWrite(${label}_PIN, HIGH); device.saveState("TG$globalIdx", 1); }
  if (cmd == "OFF$cmdSuffix") { digitalWrite(${label}_PIN, LOW);  device.saveState("TG$globalIdx", 0); }
''');
          restoreLines.writeln('  digitalWrite(${label}_PIN, device.getState("TG$globalIdx", 0) ? HIGH : LOW);');
          break;

        case 'slider':
          commandLines.writeln('''
  // ${w['label']}${suffix.isNotEmpty ? ' #$idx' : ''} — Slider (0–100 → PWM)
  if (cmd.startsWith("SLIDER$cmdSuffix:")) {
    int val = cmd.substring(${7 + cmdSuffix.length}).toInt();
    analogWrite(${label}_PIN, map(val, 0, 100, 0, 255));
    device.saveState("SL$globalIdx", val);
  }
''');
          restoreLines.writeln('  analogWrite(${label}_PIN, map(device.getState("SL$globalIdx", 0), 0, 100, 0, 255));');
          break;

        case 'button':
          commandLines.writeln('''
  // ${w['label']}${suffix.isNotEmpty ? ' #$idx' : ''} — Button pulse
  if (cmd == "PRESS$cmdSuffix") {
    digitalWrite(${label}_PIN, HIGH);
    delay(200);
    digitalWrite(${label}_PIN, LOW);
  }
''');
          break;

        case 'horn':
          commandLines.writeln('''
  // ${w['label']}${suffix.isNotEmpty ? ' #$idx' : ''} — Horn
  if (cmd == "HORN$cmdSuffix") {
    digitalWrite(${label}_PIN, HIGH);
    delay(300);
    digitalWrite(${label}_PIN, LOW);
  }
''');
          break;

        case 'headlights':
          commandLines.writeln('''
  // ${w['label']}${suffix.isNotEmpty ? ' #$idx' : ''} — Headlights
  if (cmd == "LIGHTS$cmdSuffix:ON")  { digitalWrite(${label}_PIN, HIGH); device.saveState("HL$globalIdx", 1); }
  if (cmd == "LIGHTS$cmdSuffix:OFF") { digitalWrite(${label}_PIN, LOW);  device.saveState("HL$globalIdx", 0); }
''');
          restoreLines.writeln('  digitalWrite(${label}_PIN, device.getState("HL$globalIdx", 0) ? HIGH : LOW);');
          break;

        case 'turbo':
          commandLines.writeln('''
  // ${w['label']}${suffix.isNotEmpty ? ' #$idx' : ''} — Turbo Boost
  if (cmd == "TURBO$cmdSuffix:ON")  { digitalWrite(${label}_PIN, HIGH); }
  if (cmd == "TURBO$cmdSuffix:OFF") { digitalWrite(${label}_PIN, LOW);  }
''');
          break;

         case 'rgb':
          commandLines.writeln('''
  // ${w['label']}${suffix.isNotEmpty ? ' #$idx' : ''} — RGB Color Picker
  if (cmd.startsWith("RGB$cmdSuffix:")) {
    String vals = cmd.substring(${4 + cmdSuffix.length});
    int r = vals.substring(0, vals.indexOf(",")).toInt();
    int g = vals.substring(vals.indexOf(",")+1, vals.lastIndexOf(",")).toInt();
    int b = vals.substring(vals.lastIndexOf(",")+1).toInt();
    PWM_WRITE(${label}_R_PIN, ${label}_R_CH, r);
    PWM_WRITE(${label}_G_PIN, ${label}_G_CH, g);
    PWM_WRITE(${label}_B_PIN, ${label}_B_CH, b);
    device.saveState("R$globalIdx", r);
    device.saveState("G$globalIdx", g);
    device.saveState("B$globalIdx", b);
  }
''');
          restoreLines.writeln('  PWM_WRITE(${label}_R_PIN, ${label}_R_CH, device.getState("R$globalIdx", 0));');
          restoreLines.writeln('  PWM_WRITE(${label}_G_PIN, ${label}_G_CH, device.getState("G$globalIdx", 0));');
          restoreLines.writeln('  PWM_WRITE(${label}_B_PIN, ${label}_B_CH, device.getState("B$globalIdx", 0));');
          break;

        case 'fanspeed':
          commandLines.writeln('''
  // ${w['label']}${suffix.isNotEmpty ? ' #$idx' : ''} — Fan Speed (0–100 → PWM)
  if (cmd.startsWith("FAN$cmdSuffix:")) {
    int val = cmd.substring(${4 + cmdSuffix.length}).toInt();
    PWM_WRITE(${label}_PIN, ${label}_CH, map(val, 0, 100, 0, 255));
    device.saveState("FN$globalIdx", val);
  }
''');
          restoreLines.writeln('  PWM_WRITE(${label}_PIN, ${label}_CH, map(device.getState("FN$globalIdx", 0), 0, 100, 0, 255));');
          break;

        case 'graph':
          commandLines.writeln('''
  // ${w['label']}${suffix.isNotEmpty ? ' #$idx' : ''} — Graph receives sensor data automatically in loop()
''');
          break;

        case 'barchart':
          commandLines.writeln('''
  // ${w['label']}${suffix.isNotEmpty ? ' #$idx' : ''} — Bar Chart receives sensor data automatically in loop()
''');
          break;

        case 'table':
          commandLines.writeln('''
  // ${w['label']}${suffix.isNotEmpty ? ' #$idx' : ''} — Table receives data automatically in loop()
''');
          break;

        case 'alarm':
          commandLines.writeln('''
  // ${w['label']}${suffix.isNotEmpty ? ' #$idx' : ''} — Alarm Trigger
  if (cmd == "ALARM$cmdSuffix:ON")  { digitalWrite(${label}_PIN, HIGH); device.saveState("AL$globalIdx", 1); }
  if (cmd == "ALARM$cmdSuffix:OFF") { digitalWrite(${label}_PIN, LOW);  device.saveState("AL$globalIdx", 0); }
''');
          restoreLines.writeln('  digitalWrite(${label}_PIN, device.getState("AL$globalIdx", 0) ? HIGH : LOW);');
          break;

        case 'irblast':
          commandLines.writeln('''
  // ${w['label']}${suffix.isNotEmpty ? ' #$idx' : ''} — IR Blaster
  // Requires IRremote library: #include <IRremote.h>
  // IRsend irsend;
  if (cmd.startsWith("IR$cmdSuffix:")) {
    String code = cmd.substring(${3 + cmdSuffix.length});
    // Example NEC codes — replace with your device codes
    if (code == "PWR")  { /* irsend.sendNEC(0xFFA25D, 32); */ }
    if (code == "VOL+") { /* irsend.sendNEC(0xFF629D, 32); */ }
    if (code == "VOL-") { /* irsend.sendNEC(0xFFA857, 32); */ }
    if (code == "CH+")  { /* irsend.sendNEC(0xFF02FD, 32); */ }
    if (code == "CH-")  { /* irsend.sendNEC(0xFFE21D, 32); */ }
    if (code == "MUTE") { /* irsend.sendNEC(0xFF906F, 32); */ }
    if (code == "HOME")     { /* irsend.sendNEC(0x00000000, 32); */ }
    if (code == "UP")       { /* irsend.sendNEC(0x00000000, 32); */ }
    if (code == "DOWN")     { /* irsend.sendNEC(0x00000000, 32); */ }
    if (code == "LEFT")     { /* irsend.sendNEC(0x00000000, 32); */ }
    if (code == "RIGHT")    { /* irsend.sendNEC(0x00000000, 32); */ }
    if (code == "OK")       { /* irsend.sendNEC(0x00000000, 32); */ }
    if (code == "REW")      { /* irsend.sendNEC(0x00000000, 32); */ }
    if (code == "PLAY")     { /* irsend.sendNEC(0x00000000, 32); */ }
    if (code == "PAUSE")    { /* irsend.sendNEC(0x00000000, 32); */ }
    if (code == "FF")       { /* irsend.sendNEC(0x00000000, 32); */ }
    if (code == "KEYBOARD") { /* irsend.sendNEC(0x00000000, 32); */ }
    if (code == "BACK")     { /* irsend.sendNEC(0x00000000, 32); */ }
    Serial.println("IR:" + code);
  }
''');
          break;

        case 'stopwatch':
          commandLines.writeln('''
  // ${w['label']}${suffix.isNotEmpty ? ' #$idx' : ''} — Stopwatch (software only)
  if (cmd == "STOPWATCH$cmdSuffix:START") { /* start your timer */ }
  if (cmd == "STOPWATCH$cmdSuffix:STOP")  { /* stop your timer  */ }
  if (cmd == "STOPWATCH$cmdSuffix:RESET") { /* reset your timer */ }
''');
          break; 

        case 'volume':
          commandLines.writeln('''
  // ${w['label']}${suffix.isNotEmpty ? ' #$idx' : ''} — Volume
  if (cmd == "MUTE$cmdSuffix")   { analogWrite(${label}_PIN, 0); device.saveState("VM$globalIdx", 1); }
  if (cmd == "UNMUTE$cmdSuffix") { analogWrite(${label}_PIN, map(device.getState("VL$globalIdx", 0), 0, 100, 0, 255)); device.saveState("VM$globalIdx", 0); }
  if (cmd.startsWith("VOL$cmdSuffix:")) {
    int vol = cmd.substring(${4 + cmdSuffix.length}).toInt();
    analogWrite(${label}_PIN, map(vol, 0, 100, 0, 255));
    device.saveState("VL$globalIdx", vol);
    device.saveState("VM$globalIdx", 0);
  }
''');
          restoreLines.writeln('  analogWrite(${label}_PIN, device.getState("VM$globalIdx", 0) ? 0 : map(device.getState("VL$globalIdx", 0), 0, 100, 0, 255));');
          break;

        case 'gauge':
          commandLines.writeln('''
  // ${w['label']}${suffix.isNotEmpty ? ' #$idx' : ''} — Gauge
  if (cmd.startsWith("GAUGE$cmdSuffix:")) {
    int val = cmd.substring(${6 + cmdSuffix.length}).toInt();
    analogWrite(${label}_PIN, map(val, 0, 100, 0, 255));
  }
''');
          break;

        case 'brake':
          commandLines.writeln('''
  // ${w['label']}${suffix.isNotEmpty ? ' #$idx' : ''} — Brake
  // ── ACTIVE: L298N / L293D / MX1508 ──────────────────────
  if (cmd == "BRAKE$cmdSuffix:ON")  {
    ledcWrite(0, 0); ledcWrite(1, 0);
    digitalWrite(${label}_PIN, LOW);
  }
  if (cmd == "BRAKE$cmdSuffix:OFF") { digitalWrite(${label}_PIN, HIGH); }
  // ── OPTION 2: BTS7960 ───────────────────────────────────
  // if (cmd == "BRAKE$cmdSuffix:ON") { ledcWrite(0,0); ledcWrite(1,0); ledcWrite(2,0); ledcWrite(3,0); }
  // ── OPTION 3: TB6612FNG ──────────────────────────────────
  // if (cmd == "BRAKE$cmdSuffix:ON")  { digitalWrite(STBY_PIN, LOW); }
  // if (cmd == "BRAKE$cmdSuffix:OFF") { digitalWrite(STBY_PIN, HIGH); }
  // ── OPTION 4: Brake relay ────────────────────────────────
  // if (cmd == "BRAKE$cmdSuffix:ON")  { digitalWrite(${label}_PIN, HIGH); }
  // if (cmd == "BRAKE$cmdSuffix:OFF") { digitalWrite(${label}_PIN, LOW);  }
''');
          break;

        case 'accelerator':
          commandLines.writeln('''
  // ${w['label']}${suffix.isNotEmpty ? ' #$idx' : ''} — Accelerator
  // ── ACTIVE: L298N / L293D / MX1508 ──────────────────────
  if (cmd.startsWith("ACCEL$cmdSuffix:")) {
    int val = cmd.substring(${6 + cmdSuffix.length}).toInt();
    ledcWrite(0, map(val, 0, 100, 0, 255));
    digitalWrite(${label}_PIN, HIGH);
  }
  // ── OPTION 2: BTS7960 ───────────────────────────────────
  // if (cmd.startsWith("ACCEL$cmdSuffix:")) {
  //   int val = cmd.substring(${6 + cmdSuffix.length}).toInt();
  //   ledcWrite(0, map(val, 0, 100, 0, 255)); ledcWrite(1, 0);
  // }
  // ── OPTION 3: TB6612FNG ──────────────────────────────────
  // if (cmd.startsWith("ACCEL$cmdSuffix:")) {
  //   digitalWrite(STBY_PIN, HIGH);
  //   digitalWrite(AIN1, HIGH); digitalWrite(AIN2, LOW);
  //   ledcWrite(0, map(cmd.substring(${6 + cmdSuffix.length}).toInt(), 0, 100, 0, 255));
  // }
  // ── OPTION 4: Single PWM / ESC ───────────────────────────
  // if (cmd.startsWith("ACCEL$cmdSuffix:")) { ledcWrite(0, map(cmd.substring(${6 + cmdSuffix.length}).toInt(), 0, 100, 0, 255)); }
''');
          break;

        case 'gearshift':
          commandLines.writeln('''
  // ${w['label']}${suffix.isNotEmpty ? ' #$idx' : ''} — Gear Shift
  // ── ACTIVE: L298N / L293D / MX1508 ──────────────────────
  if (cmd.startsWith("GEAR$cmdSuffix:")) {
    String gear = cmd.substring(${5 + cmdSuffix.length});
    if (gear == "R")      { digitalWrite(${label}_PIN, LOW);  PWM_WRITE(${label}_PIN, ${label}_CH, 180); device.saveState("GS$globalIdx", 0); }
    else if (gear == "N") { PWM_WRITE(${label}_PIN, ${label}_CH, 0); device.saveState("GS$globalIdx", 1); }
    else if (gear == "1") { digitalWrite(${label}_PIN, HIGH); PWM_WRITE(${label}_PIN, ${label}_CH, 60);  device.saveState("GS$globalIdx", 2); }
    else if (gear == "2") { digitalWrite(${label}_PIN, HIGH); PWM_WRITE(${label}_PIN, ${label}_CH, 120); device.saveState("GS$globalIdx", 3); }
    else if (gear == "3") { digitalWrite(${label}_PIN, HIGH); PWM_WRITE(${label}_PIN, ${label}_CH, 180); device.saveState("GS$globalIdx", 4); }
    else if (gear == "4") { digitalWrite(${label}_PIN, HIGH); PWM_WRITE(${label}_PIN, ${label}_CH, 255); device.saveState("GS$globalIdx", 5); }
  }
  // ── OPTION 2: BTS7960 ───────────────────────────────────
  // if (cmd.startsWith("GEAR$cmdSuffix:")) {
  //   String g = cmd.substring(${5 + cmdSuffix.length});
  //   if (g=="R") { ledcWrite(1,180); ledcWrite(0,0); }
  //   if (g=="N") { ledcWrite(0,0);   ledcWrite(1,0); }
  //   if (g=="1") { ledcWrite(0,60);  ledcWrite(1,0); }
  //   if (g=="2") { ledcWrite(0,120); ledcWrite(1,0); }
  //   if (g=="3") { ledcWrite(0,180); ledcWrite(1,0); }
  //   if (g=="4") { ledcWrite(0,255); ledcWrite(1,0); }
  // }
  // ── OPTION 3: TB6612FNG ──────────────────────────────────
  // digitalWrite(STBY_PIN, HIGH);
  // if (g=="R") { digitalWrite(AIN1,LOW);  digitalWrite(AIN2,HIGH); ledcWrite(0,180); }
  // if (g=="N") { ledcWrite(0,0); }
  // if (g=="1") { digitalWrite(AIN1,HIGH); digitalWrite(AIN2,LOW); ledcWrite(0,60);  }
  // if (g=="4") { digitalWrite(AIN1,HIGH); digitalWrite(AIN2,LOW); ledcWrite(0,255); }
  // ── OPTION 4: Single PWM / ESC ───────────────────────────
  // if (g=="R") { ledcWrite(0,30);  } // reverse
  // if (g=="N") { ledcWrite(0,90);  } // neutral
  // if (g=="1") { ledcWrite(0,110); } if (g=="2") { ledcWrite(0,150); }
  // if (g=="3") { ledcWrite(0,200); } if (g=="4") { ledcWrite(0,255); }
''');
          restoreLines.writeln('''
  { int g = device.getState("GS$globalIdx", 1);
    if (g==0) { digitalWrite(${label}_PIN, LOW); PWM_WRITE(${label}_PIN, ${label}_CH, 180); }
    else if (g==1) { PWM_WRITE(${label}_PIN, ${label}_CH, 0); }
    else if (g==2) { digitalWrite(${label}_PIN, HIGH); PWM_WRITE(${label}_PIN, ${label}_CH, 60); }
    else if (g==3) { digitalWrite(${label}_PIN, HIGH); PWM_WRITE(${label}_PIN, ${label}_CH, 120); }
    else if (g==4) { digitalWrite(${label}_PIN, HIGH); PWM_WRITE(${label}_PIN, ${label}_CH, 180); }
    else if (g==5) { digitalWrite(${label}_PIN, HIGH); PWM_WRITE(${label}_PIN, ${label}_CH, 255); } }
''');
          break;

          case 'clutch':
          commandLines.writeln('''
  // ${w['label']}${suffix.isNotEmpty ? ' #$idx' : ''} — Clutch
  if (cmd == "CLUTCH$cmdSuffix:ON")  { digitalWrite(${label}_PIN, HIGH); }
  if (cmd == "CLUTCH$cmdSuffix:OFF") { digitalWrite(${label}_PIN, LOW);  }
''');
          break;

        case 'pedalset':
          commandLines.writeln('''
  // ${w['label']}${suffix.isNotEmpty ? ' #$idx' : ''} — Pedal Set (Clutch + Brake + Accelerator)
  if (cmd == "CLUTCH$cmdSuffix:ON")  { digitalWrite(${label}_CLUTCH_PIN, HIGH); }
  if (cmd == "CLUTCH$cmdSuffix:OFF") { digitalWrite(${label}_CLUTCH_PIN, LOW);  }
  if (cmd == "BRAKE$cmdSuffix:ON")   { digitalWrite(${label}_BRAKE_PIN, HIGH); }
  if (cmd == "BRAKE$cmdSuffix:OFF")  { digitalWrite(${label}_BRAKE_PIN, LOW);  }
  if (cmd.startsWith("ACCEL$cmdSuffix:")) {
    int val = cmd.substring(${6 + cmdSuffix.length}).toInt();
    analogWrite(${label}_ACCEL_PIN, map(val, 0, 100, 0, 255));
  }
''');
          break;

        case 'countdown':
          commandLines.writeln('''
  // ${w['label']}${suffix.isNotEmpty ? ' #$idx' : ''} — Countdown Timer (software only)
  if (cmd == "COUNTDOWN$cmdSuffix:START") { /* start your countdown */ }
  if (cmd == "COUNTDOWN$cmdSuffix:PAUSE") { /* pause your countdown */ }
  if (cmd == "COUNTDOWN$cmdSuffix:RESET") { /* reset your countdown */ }
  if (cmd == "COUNTDOWN$cmdSuffix:DONE")  { /* countdown finished */ }
''');
          break;

        case 'toggle2':
          commandLines.writeln('''
  // ${w['label']}${suffix.isNotEmpty ? ' #$idx' : ''} — Toggle (Rounded)
  if (cmd == "ON2$cmdSuffix")  { digitalWrite(${label}_PIN, HIGH); device.saveState("T2$globalIdx", 1); }
  if (cmd == "OFF2$cmdSuffix") { digitalWrite(${label}_PIN, LOW);  device.saveState("T2$globalIdx", 0); }
''');
          restoreLines.writeln('  digitalWrite(${label}_PIN, device.getState("T2$globalIdx", 0) ? HIGH : LOW);');
          break;

        case 'doorlock':
          commandLines.writeln('''
  // ${w['label']}${suffix.isNotEmpty ? ' #$idx' : ''} — Door Lock
  if (cmd == "LOCK$cmdSuffix:ON")  { digitalWrite(${label}_PIN, HIGH); device.saveState("DL$globalIdx", 1); }
  if (cmd == "LOCK$cmdSuffix:OFF") { digitalWrite(${label}_PIN, LOW);  device.saveState("DL$globalIdx", 0); }
''');
          restoreLines.writeln('  digitalWrite(${label}_PIN, device.getState("DL$globalIdx", 1) ? HIGH : LOW);');
          break;

        case 'servo':
          commandLines.writeln('''
  // ${w['label']}${suffix.isNotEmpty ? ' #$idx' : ''} — Servo Controller (0–180°)
  if (cmd.startsWith("SERVO$cmdSuffix:")) {
    int angle = cmd.substring(${6 + cmdSuffix.length}).toInt();
    PWM_WRITE(${label}_PIN, ${label}_CH, map(angle, 0, 180, 1638, 8192));
    device.saveState("SV$globalIdx", angle);
  }
''');
          restoreLines.writeln('  PWM_WRITE(${label}_PIN, ${label}_CH, map(device.getState("SV$globalIdx", 90), 0, 180, 1638, 8192));');
          break;

        case 'start':
          commandLines.writeln('''
  // ${w['label']}${suffix.isNotEmpty ? ' #$idx' : ''} — Start
  if (cmd == "START$cmdSuffix") {
    digitalWrite(${label}_PIN, HIGH);
    delay(200);
    digitalWrite(${label}_PIN, LOW);
  }
''');
          break;

        case 'stop':
          commandLines.writeln('''
  // ${w['label']}${suffix.isNotEmpty ? ' #$idx' : ''} — Stop
  if (cmd == "STOP$cmdSuffix") {
    digitalWrite(${label}_PIN, HIGH);
    delay(200);
    digitalWrite(${label}_PIN, LOW);
  }
''');
          break;

        case 'chup':
          commandLines.writeln('''
  // ${w['label']}${suffix.isNotEmpty ? ' #$idx' : ''} — Channel Up (IR)
  if (cmd == "CH+$cmdSuffix") {
    // irsend.sendNEC(0xFF02FD, 32); // replace with your remote's code
    Serial.println("CH+ pressed");
  }
''');
          break;

        case 'chdown':
          commandLines.writeln('''
  // ${w['label']}${suffix.isNotEmpty ? ' #$idx' : ''} — Channel Down (IR)
  if (cmd == "CH-$cmdSuffix") {
    // irsend.sendNEC(0xFFE21D, 32); // replace with your remote's code
    Serial.println("CH- pressed");
  }
''');
          break;

        case 'volup':
          commandLines.writeln('''
  // ${w['label']}${suffix.isNotEmpty ? ' #$idx' : ''} — Volume Up (IR)
  if (cmd == "VOL+$cmdSuffix") {
    // irsend.sendNEC(0xFF629D, 32); // replace with your remote's code
    Serial.println("VOL+ pressed");
  }
''');
          break;

        case 'voldown':
          commandLines.writeln('''
  // ${w['label']}${suffix.isNotEmpty ? ' #$idx' : ''} — Volume Down (IR)
  if (cmd == "VOL-$cmdSuffix") {
    // irsend.sendNEC(0xFFA857, 32); // replace with your remote's code
    Serial.println("VOL- pressed");
  }
''');
          break;

        case 'muteonly':
          commandLines.writeln('''
  // ${w['label']}${suffix.isNotEmpty ? ' #$idx' : ''} — Mute (IR)
  if (cmd == "MUTE$cmdSuffix") {
    // irsend.sendNEC(0xFF906F, 32); // replace with your remote's code
    Serial.println("MUTE pressed");
  }
''');
          break;

        case 'robotarm':
          commandLines.writeln('''
  // ${w['label']}${suffix.isNotEmpty ? ' #$idx' : ''} — Robot Arm (Shoulder / Elbow / Wrist)
  if (cmd.startsWith("SHOULDER$cmdSuffix:")) {
    int angle = cmd.substring(${9 + cmdSuffix.length}).toInt();
    PWM_WRITE(${label}_SHOULDER_PIN, ${label}_SHOULDER_CH, map(angle, 0, 180, 1638, 8192));
    device.saveState("RS$globalIdx", angle);
  }
  if (cmd.startsWith("ELBOW$cmdSuffix:")) {
    int angle = cmd.substring(${6 + cmdSuffix.length}).toInt();
    PWM_WRITE(${label}_ELBOW_PIN, ${label}_ELBOW_CH, map(angle, 0, 180, 1638, 8192));
    device.saveState("RE$globalIdx", angle);
  }
  if (cmd.startsWith("WRIST$cmdSuffix:")) {
    int angle = cmd.substring(${6 + cmdSuffix.length}).toInt();
    PWM_WRITE(${label}_WRIST_PIN, ${label}_WRIST_CH, map(angle, 0, 180, 1638, 8192));
    device.saveState("RW$globalIdx", angle);
  }
''');
          restoreLines.writeln('  PWM_WRITE(${label}_SHOULDER_PIN, ${label}_SHOULDER_CH, map(device.getState("RS$globalIdx", 90), 0, 180, 1638, 8192));');
          restoreLines.writeln('  PWM_WRITE(${label}_ELBOW_PIN, ${label}_ELBOW_CH, map(device.getState("RE$globalIdx", 90), 0, 180, 1638, 8192));');
          restoreLines.writeln('  PWM_WRITE(${label}_WRIST_PIN, ${label}_WRIST_CH, map(device.getState("RW$globalIdx", 90), 0, 180, 1638, 8192));');
          break;

        case 'joystick':
          commandLines.writeln('''
  // ${w['label']}${suffix.isNotEmpty ? ' #$idx' : ''} — Joystick
  // ── ACTIVE: L298N / L293D / MX1508 ──────────────────────
  if (cmd.startsWith("JOY$cmdSuffix:")) {
    int colon = cmd.indexOf(":", ${4 + cmdSuffix.length});
    int x = cmd.substring(${4 + cmdSuffix.length}, colon).toInt();
    int y = cmd.substring(colon + 1).toInt();
    int speedA = map(abs(y + x), 0, 200, 0, 255);
    int speedB = map(abs(y - x), 0, 200, 0, 255);
    PWM_WRITE(${label}_A_PIN, ${label}_A_CH, speedA);
    PWM_WRITE(${label}_B_PIN, ${label}_B_CH, speedB);
    digitalWrite(${label}_A_PIN, y > 0 ? HIGH : LOW);
    digitalWrite(${label}_B_PIN, y > 0 ? HIGH : LOW);
  }
  // ── OPTION 2: BTS7960 ───────────────────────────────────
  // ledcWrite(0, x>0 ? map(x,0,100,0,255):0); // RPWM A
  // ledcWrite(1, x<0 ? map(-x,0,100,0,255):0); // LPWM A
  // ledcWrite(2, y>0 ? map(y,0,100,0,255):0); // RPWM B
  // ledcWrite(3, y<0 ? map(-y,0,100,0,255):0); // LPWM B
  // ── OPTION 3: TB6612FNG ──────────────────────────────────
  // digitalWrite(STBY_PIN, HIGH);
  // ledcWrite(0, map(abs(x), 0, 100, 0, 255));
  // digitalWrite(AIN1, x>0 ? HIGH:LOW); digitalWrite(AIN2, x<0 ? HIGH:LOW);
  // ── OPTION 4: Single PWM / ESC ───────────────────────────
  // ledcWrite(0, map(y, -100, 100, 0, 255));
''');
          break;

        case 'steering':
          commandLines.writeln('''
  // ${w['label']}${suffix.isNotEmpty ? ' #$idx' : ''} — Steering
  // ── ACTIVE: L298N / L293D / MX1508 ──────────────────────
  if (cmd.startsWith("STEER$cmdSuffix:")) {
    int angle = cmd.substring(${6 + cmdSuffix.length}).toInt();
    int pwm = map(abs(angle), 0, 135, 0, 255);
    if (angle < 0)      { PWM_WRITE(${label}_A_PIN, ${label}_A_CH, pwm); PWM_WRITE(${label}_B_PIN, ${label}_B_CH, 255); }
    else if (angle > 0) { PWM_WRITE(${label}_A_PIN, ${label}_A_CH, 255); PWM_WRITE(${label}_B_PIN, ${label}_B_CH, pwm); }
    else                { PWM_WRITE(${label}_A_PIN, ${label}_A_CH, 255); PWM_WRITE(${label}_B_PIN, ${label}_B_CH, 255); }
  }
  // ── OPTION 2: BTS7960 ───────────────────────────────────
  // ledcWrite(0, angle<0 ? pwm:255); ledcWrite(1, angle>0 ? pwm:255);
  // ── OPTION 3: Servo steering ─────────────────────────────
  // #include <ESP32Servo.h>
  // Servo steerServo;
  // steerServo.write(map(angle, -135, 135, 0, 180));
  // ── OPTION 4: Single PWM / ESC ───────────────────────────
  // ledcWrite(0, map(angle, -135, 135, 0, 255));
''');
          break;

        case 'dpad2':
          commandLines.writeln('''
  // ${w['label']}${suffix.isNotEmpty ? ' #$idx' : ''} — D-Pad (Classic)
  // ── ACTIVE: L298N / L293D / MX1508 ──────────────────────
  if (cmd == "FWD$cmdSuffix")   { PWM_WRITE(${label}_A_PIN, ${label}_A_CH, 200); PWM_WRITE(${label}_B_PIN, ${label}_B_CH, 200); digitalWrite(${label}_A_PIN,HIGH); digitalWrite(${label}_B_PIN,HIGH); }
  if (cmd == "BCK$cmdSuffix")   { PWM_WRITE(${label}_A_PIN, ${label}_A_CH, 200); PWM_WRITE(${label}_B_PIN, ${label}_B_CH, 200); digitalWrite(${label}_A_PIN,LOW);  digitalWrite(${label}_B_PIN,LOW);  }
  if (cmd == "LEFT$cmdSuffix")  { PWM_WRITE(${label}_A_PIN, ${label}_A_CH, 0);   PWM_WRITE(${label}_B_PIN, ${label}_B_CH, 200); digitalWrite(${label}_B_PIN,HIGH); }
  if (cmd == "RIGHT$cmdSuffix") { PWM_WRITE(${label}_A_PIN, ${label}_A_CH, 200); PWM_WRITE(${label}_B_PIN, ${label}_B_CH, 0);   digitalWrite(${label}_A_PIN,HIGH); }
  if (cmd == "PRESS$cmdSuffix") {
    digitalWrite(${label}_CENTER_PIN, HIGH);
    delay(200);
    digitalWrite(${label}_CENTER_PIN, LOW);
  }
  // ── OPTION 2: BTS7960 ───────────────────────────────────
  // if (cmd=="FWD$cmdSuffix")  { ledcWrite(0,200); ledcWrite(2,200); }
  // if (cmd=="BCK$cmdSuffix")  { ledcWrite(1,200); ledcWrite(3,200); }
  // if (cmd=="LEFT$cmdSuffix") { ledcWrite(0,0);   ledcWrite(2,200); }
  // if (cmd=="RIGHT$cmdSuffix"){ ledcWrite(0,200); ledcWrite(2,0);   }
  // ── OPTION 3: TB6612FNG ──────────────────────────────────
  // digitalWrite(STBY_PIN, HIGH);
  // if (cmd=="FWD$cmdSuffix")  { digitalWrite(AIN1,HIGH); digitalWrite(BIN1,HIGH); ledcWrite(0,200); ledcWrite(1,200); }
  // if (cmd=="BCK$cmdSuffix")  { digitalWrite(AIN1,LOW);  digitalWrite(BIN1,LOW);  ledcWrite(0,200); ledcWrite(1,200); }
  // ── OPTION 4: Single PWM / ESC ───────────────────────────
  // if (cmd=="FWD$cmdSuffix")  { ledcWrite(0,200); }
  // if (cmd=="BCK$cmdSuffix")  { ledcWrite(0,50);  }
''');
          break;

        case 'dpad':
          commandLines.writeln('''
  // ${w['label']}${suffix.isNotEmpty ? ' #$idx' : ''} — D-Pad
  // ── ACTIVE: L298N / L293D / MX1508 ──────────────────────
  if (cmd == "FWD$cmdSuffix")   { PWM_WRITE(${label}_A_PIN, ${label}_A_CH, 200); PWM_WRITE(${label}_B_PIN, ${label}_B_CH, 200); digitalWrite(${label}_A_PIN,HIGH); digitalWrite(${label}_B_PIN,HIGH); }
  if (cmd == "BCK$cmdSuffix")   { PWM_WRITE(${label}_A_PIN, ${label}_A_CH, 200); PWM_WRITE(${label}_B_PIN, ${label}_B_CH, 200); digitalWrite(${label}_A_PIN,LOW);  digitalWrite(${label}_B_PIN,LOW);  }
  if (cmd == "LEFT$cmdSuffix")  { PWM_WRITE(${label}_A_PIN, ${label}_A_CH, 0);   PWM_WRITE(${label}_B_PIN, ${label}_B_CH, 200); digitalWrite(${label}_B_PIN,HIGH); }
  if (cmd == "RIGHT$cmdSuffix") { PWM_WRITE(${label}_A_PIN, ${label}_A_CH, 200); PWM_WRITE(${label}_B_PIN, ${label}_B_CH, 0);   digitalWrite(${label}_A_PIN,HIGH); }
  // ── OPTION 2: BTS7960 ───────────────────────────────────
  // if (cmd=="FWD$cmdSuffix")  { ledcWrite(0,200); ledcWrite(2,200); }
  // if (cmd=="BCK$cmdSuffix")  { ledcWrite(1,200); ledcWrite(3,200); }
  // if (cmd=="LEFT$cmdSuffix") { ledcWrite(0,0);   ledcWrite(2,200); }
  // if (cmd=="RIGHT$cmdSuffix"){ ledcWrite(0,200); ledcWrite(2,0);   }
  // ── OPTION 3: TB6612FNG ──────────────────────────────────
  // digitalWrite(STBY_PIN, HIGH);
  // if (cmd=="FWD$cmdSuffix")  { digitalWrite(AIN1,HIGH); digitalWrite(BIN1,HIGH); ledcWrite(0,200); ledcWrite(1,200); }
  // if (cmd=="BCK$cmdSuffix")  { digitalWrite(AIN1,LOW);  digitalWrite(BIN1,LOW);  ledcWrite(0,200); ledcWrite(1,200); }
  // ── OPTION 4: Single PWM / ESC ───────────────────────────
  // if (cmd=="FWD$cmdSuffix")  { ledcWrite(0,200); }
  // if (cmd=="BCK$cmdSuffix")  { ledcWrite(0,50);  }
''');
          break;
      }
    }

    final hasWidgets = widgets.isNotEmpty;

    // On non-WiFi boards, the library that provides saveState/getState
    // isn't included, so strip those calls and restore lines entirely.
    String finalCommandLines = commandLines.toString();
    String finalRestoreLines = restoreLines.toString();
    if (!isWifiCapable && !isBridgeBoard) {
      finalCommandLines = finalCommandLines
          .replaceAll(RegExp(r'\s*device\.saveState\([^;]*\);'), '')
          .replaceAll(RegExp(r'device\.getState\([^)]*\)'), '0');
      finalRestoreLines = '';
    }

    String sketch;
    if (isWifiCapable) {
      sketch = '''#include <XxSmartSystems.h>

// ── Universal PWM helper (works on ESP32 core 2.x and 3.x) ──
#if ESP_ARDUINO_VERSION_MAJOR >= 3
  #define PWM_SETUP(pin, channel, freq, res) ledcAttach(pin, freq, res)
  #define PWM_WRITE(pin, channel, value)     ledcWrite(pin, value)
#else
  #define PWM_SETUP(pin, channel, freq, res) do { ledcSetup(channel, freq, res); ledcAttachPin(pin, channel); } while (0)
  #define PWM_WRITE(pin, channel, value)     ledcWrite(channel, value)
#endif

// ── Credentials ──────────────────────────────
#define AUTH_TOKEN  "$authToken"
#define DEVICE_ID   "$deviceId"

// ── Pin Definitions ──────────────────────────
${hasWidgets ? pinLines.toString().trimRight() : '// No widgets added yet — add widgets in the app'}

// ── PWM Channels (do not edit — auto-assigned, must stay unique) ──
${channelLines.toString().trimRight()}

XxSmartSystems device(AUTH_TOKEN, DEVICE_ID);

// ── Command Handler ───────────────────────────
void onCommand(String cmd) {
${hasWidgets ? finalCommandLines.trimRight() : '  // Add widgets in the app to generate handlers'}
}

void setup() {
  Serial.begin(115200);

  // Pin modes
${hasWidgets ? setupLines.toString().trimRight() : '  // Pins will appear here once widgets are added'}

  // ── Restore last saved state (before connecting) ──
${finalRestoreLines.trimRight().isEmpty ? '  // No widgets need state restoring' : finalRestoreLines.trimRight()}

  // Connect — WiFi, MQTT, online status all handled automatically
  device.begin("YOUR_WIFI_SSID", "YOUR_WIFI_PASSWORD");
  device.onCommand(onCommand);
}

void loop() {
  device.run(); // keeps everything alive

${_buildLoopSensors()}
}''';
    } else if (isBridgeBoard) {
      sketch = '''#include <XxSmartSystemsBridge.h>
// NOTE: Pins 2 (RX) and 3 (TX) are reserved for talking to your
// ESP-01/ESP-AT WiFi module — do not reuse them for widgets below.

// ── Universal PWM helper (Arduino has no ledc — uses analogWrite) ──
#define PWM_SETUP(pin, channel, freq, res) analogWrite(pin, 0)
#define PWM_WRITE(pin, channel, value)     analogWrite(pin, value)

// ── Credentials ──────────────────────────────
#define AUTH_TOKEN  "$authToken"
#define DEVICE_ID   "$deviceId"

// ── Pin Definitions ──────────────────────────
${hasWidgets ? pinLines.toString().trimRight() : '// No widgets added yet — add widgets in the app'}

XxSmartSystemsBridge device(AUTH_TOKEN, DEVICE_ID);

// ── Command Handler ───────────────────────────
void onCommand(String cmd) {
${hasWidgets ? finalCommandLines.trimRight() : '  // Add widgets in the app to generate handlers'}
}

void setup() {
  Serial.begin(9600);

  // Pin modes
${hasWidgets ? setupLines.toString().trimRight() : '  // Pins will appear here once widgets are added'}

  // ── Restore last saved state (before connecting) ──
${finalRestoreLines.trimRight().isEmpty ? '  // No widgets need state restoring' : finalRestoreLines.trimRight()}

  // Connect via your ESP-01/ESP-AT WiFi module — handled automatically
  device.begin("YOUR_WIFI_SSID", "YOUR_WIFI_PASSWORD");
  device.onCommand(onCommand);
}

void loop() {
  device.run(); // keeps everything alive

${_buildLoopSensors()}
}''';
    } else {
      sketch = '''// ── $board has no built-in WiFi ────────────────────
// The code below has pins and command logic ready, but you must
// add your own WiFi/MQTT connection (e.g. via an ESP-01 module)
// and call onCommand(cmd) yourself when a command arrives.

// ── Universal PWM helper ──────────────────────────
#define PWM_SETUP(pin, channel, freq, res) analogWrite(pin, 0)
#define PWM_WRITE(pin, channel, value)     analogWrite(pin, value)

// ── Pin Definitions ──────────────────────────
${hasWidgets ? pinLines.toString().trimRight() : '// No widgets added yet — add widgets in the app'}

// ── Command Handler — call this yourself when you receive a command ──
void onCommand(String cmd) {
${hasWidgets ? finalCommandLines.trimRight() : '  // Add widgets in the app to generate handlers'}
}

void setup() {
  Serial.begin(115200);

  // Pin modes
${hasWidgets ? setupLines.toString().trimRight() : '  // Pins will appear here once widgets are added'}

  // TODO: connect your own WiFi module here
}

void loop() {
  // TODO: check your WiFi module for incoming commands,
  // then call onCommand("yourCommand") when one arrives
}''';
    }
    return sketch;
  }

String _buildLoopSensors() {
    final widgets = widget.placedWidgets;
    final graphWidgets = widgets.where((w) =>
        w['type'] == 'graph' || w['type'] == 'barchart' || w['type'] == 'table').toList();

    if (graphWidgets.isEmpty) {
      return '''
  // ── Add sensor readings here ─────────────────────────────
  // static unsigned long lastSend = 0;
  // if (millis() - lastSend > 2000) {
  //   lastSend = millis();
  //   device.sendData("sensor1", analogRead(34));
  // }''';
    }

    final typeCount = <String, int>{};
    final buffer = StringBuffer();
    buffer.writeln('  // ── Sensor readings (runs every 2 seconds) ────────────────');
    buffer.writeln('  static unsigned long _lastSensorSend = 0;');
    buffer.writeln('  if (millis() - _lastSensorSend > 2000) {');
    buffer.writeln('    _lastSensorSend = millis();');

    for (final w in widgets) {
      final type = w['type'] as String;
      if (type != 'graph' && type != 'barchart' && type != 'table') continue;
      typeCount[type] = (typeCount[type] ?? 0) + 1;
      final idx = typeCount[type]!;
      final totalOfType = widgets.where((x) => x['type'] == type).length;
      final suffix = totalOfType > 1 ? '_$idx' : '';
      final rawLabel = (w['label'] as String)
          .toUpperCase()
          .replaceAll(' ', '_')
          .replaceAll(RegExp(r'[^A-Z0-9_]'), '');
      final label = '$rawLabel$suffix';
      if (type == 'graph') {
        buffer.writeln('    device.sendData("GRAPH${suffix.isNotEmpty ? '_$idx' : ''}", analogRead(${label}_SENSOR_PIN));');
      } else if (type == 'barchart') {
        buffer.writeln('    device.sendData("BAR${suffix.isNotEmpty ? '_$idx' : ''}", analogRead(${label}_SENSOR_PIN) / 4095.0);');
      } else if (type == 'table') {
        buffer.writeln('    // device.sendData("TBL${suffix.isNotEmpty ? '_$idx' : ''}", "Temp:23C;Speed:40kmh"); // fill in your own key:value pairs, separated by ;');
      }
    }

    buffer.writeln('  }');
    buffer.writeln();
    buffer.writeln('  // ── Add more sensor readings below ──────────────────────');
    buffer.writeln('  // device.sendData("temperature", analogRead(35));');
    buffer.writeln('  // device.sendData("humidity", analogRead(36));');

    return buffer.toString();
  }

  void _copyToClipboard(BuildContext ctx, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF111827),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 16),
            const SizedBox(width: 8),
            Text(
              '$label copied!',
              style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── PIN Logic ────────────────────────────────────────────
  void _onPinDigit(String digit) {
    setState(() => _pinError = '');

    // ── Change PIN flow ──
    if (_isChangingPin) {
      if (_verifyOldPinStep) {
        // Step 1: verify old PIN
        if (_enteredPin.length < 6) {
          _enteredPin += digit;
          setState(() {});
          if (_enteredPin.length == 6) {
            if (_enteredPin == _savedPin) {
              setState(() {
                _verifyOldPinStep = false;
                _isSettingPin = true;
                _enteredPin = '';
                _pendingPin = '';
                _confirmStep = false;
              });
            } else {
              setState(() {
                _pinError = 'Incorrect current PIN.';
                _enteredPin = '';
              });
            }
          }
        }
      }
      return;
    }

    // ── Set new PIN flow ──
    if (_isSettingPin) {
      if (!_confirmStep) {
        if (_pendingPin.length < 6) {
          _pendingPin += digit;
          if (_pendingPin.length == 6) {
            setState(() => _confirmStep = true);
          } else {
            setState(() {});
          }
        }
      } else {
        if (_enteredPin.length < 6) {
          _enteredPin += digit;
          setState(() {});
          if (_enteredPin.length == 6) {
            if (_enteredPin == _pendingPin) {
              setState(() {
                _savedPin = _enteredPin;
                _unlocked = true;
                _isSettingPin = false;
                _isChangingPin = false;
              });
              ApiService.savePin(_enteredPin);
            } else {
              setState(() {
                _pinError = 'PINs do not match. Try again.';
                _enteredPin = '';
                _pendingPin = '';
                _confirmStep = false;
              });
            }
          }
        }
      }
      return;
    }

    // ── Normal unlock flow ──
    if (_enteredPin.length < 6) {
      _enteredPin += digit;
      setState(() {});
      if (_enteredPin.length == 6) {
        if (_enteredPin == _savedPin) {
          setState(() => _unlocked = true);
        } else {
          setState(() {
            _pinError = 'Incorrect PIN.';
            _enteredPin = '';
          });
        }
      }
    }
  }

  void _onPinDelete() {
    setState(() {
      _pinError = '';
      if (_isChangingPin && _verifyOldPinStep) {
        if (_enteredPin.isNotEmpty) {
          _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        }
      } else if (_isSettingPin && _confirmStep) {
        if (_enteredPin.isNotEmpty) {
          _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        }
      } else if (_isSettingPin && !_confirmStep) {
        if (_pendingPin.isNotEmpty) {
          _pendingPin = _pendingPin.substring(0, _pendingPin.length - 1);
        }
      } else {
        if (_enteredPin.isNotEmpty) {
          _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        }
      }
    });
  }

  void _startChangingPin() {
    setState(() {
      _isChangingPin = true;
      _verifyOldPinStep = true;
      _isSettingPin = false;
      _enteredPin = '';
      _pendingPin = '';
      _confirmStep = false;
      _pinError = '';
      _unlocked = false;
    });
  }

  String get _currentPinDisplay {
    if (_isChangingPin && _verifyOldPinStep) return _enteredPin;
    if (_isSettingPin && !_confirmStep) return _pendingPin;
    return _enteredPin;
  }

  // ── Build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loadingPin) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0E1A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00D4FF)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        leading: const BackButton(color: Color(0xFF00D4FF)),
        title: Text(
          'CREDENTIALS',
          style: GoogleFonts.orbitron(
              fontSize: 13, color: Colors.white, letterSpacing: 1),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF1E2D45)),
        ),
      ),
      body: _unlocked ? _buildCredentials() : _buildPinGate(),
    );
  }

  // ── PIN Gate ─────────────────────────────────────────────
  Widget _buildPinGate() {
    String title;
    String subtitle;

    if (_isChangingPin && _verifyOldPinStep) {
      title = 'VERIFY CURRENT PIN';
      subtitle = 'Enter your current PIN to continue';
    } else if (_isSettingPin && !_confirmStep) {
      title = _isChangingPin ? 'SET NEW PIN' : 'SET A PIN';
      subtitle = 'Choose a 6-digit PIN';
    } else if (_isSettingPin && _confirmStep) {
      title = 'CONFIRM NEW PIN';
      subtitle = 'Re-enter your new PIN';
    } else {
      title = 'ENTER PIN';
      subtitle = 'Enter your PIN to view credentials';
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD740).withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFFFFD740).withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.lock_outline,
                  color: Color(0xFFFFD740), size: 30),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: GoogleFonts.orbitron(
                    color: Colors.white, fontSize: 14, letterSpacing: 1)),
            const SizedBox(height: 6),
            Text(subtitle,
                style: GoogleFonts.rajdhani(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 28),

            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) {
                final filled = i < _currentPinDisplay.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? const Color(0xFF00D4FF) : Colors.transparent,
                    border: Border.all(
                      color: filled
                          ? const Color(0xFF00D4FF)
                          : const Color(0xFF1E2D45),
                      width: 1.5,
                    ),
                    boxShadow: filled
                        ? [BoxShadow(
                            color: const Color(0xFF00D4FF).withValues(alpha: 0.5),
                            blurRadius: 6)]
                        : null,
                  ),
                );
              }),
            ),

            if (_pinError.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(_pinError,
                  style: GoogleFonts.rajdhani(
                      color: const Color(0xFFFF5252), fontSize: 12)),
            ],

            const SizedBox(height: 28),

            // PIN pad
            SizedBox(
              width: 240,
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  ...'123456789'.split('').map((d) => _pinButton(d)),
                  const SizedBox.shrink(),
                  _pinButton('0'),
                  _deleteButton(),
                ],
              ),
            ),

            if (!_isSettingPin && !_isChangingPin && _savedPin == null) ...[
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isSettingPin = true;
                    _pendingPin = '';
                    _enteredPin = '';
                    _confirmStep = false;
                    _pinError = '';
                  });
                },
                child: Text(
                  'Set a new PIN',
                  style: GoogleFonts.rajdhani(
                    color: const Color(0xFF00D4FF),
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],

            // Cancel button when changing PIN
            if (_isChangingPin || _isSettingPin) ...[
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isChangingPin = false;
                    _isSettingPin = false;
                    _verifyOldPinStep = false;
                    _enteredPin = '';
                    _pendingPin = '';
                    _confirmStep = false;
                    _pinError = '';
                    _unlocked = false;
                  });
                },
                child: Text(
                  'Cancel',
                  style: GoogleFonts.rajdhani(
                    color: const Color(0xFFFF5252),
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _pinButton(String digit) {
    return GestureDetector(
      onTap: () => _onPinDigit(digit),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A2234),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF1E2D45)),
        ),
        child: Center(
          child: Text(digit,
              style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _deleteButton() {
    return GestureDetector(
      onTap: _onPinDelete,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A2234),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF1E2D45)),
        ),
        child: const Center(
          child: Icon(Icons.backspace_outlined,
              color: Color(0xFFFF5252), size: 20),
        ),
      ),
    );
  }

  // ── Credentials View ─────────────────────────────────────
  Widget _buildCredentials() {
    final sketch = _generateSketch();
    final authToken = widget.device['auth_token'] ?? 'xxSS-xxxx-xxxx';
    final deviceId = widget.device['device_id'] ?? '000000000000';
    final board = widget.device['board_type'] ?? 'ESP32';
    final wifiBoards = ['ESP32', 'ESP8266'];
    final isWifiCapable = wifiBoards.contains(board);
    final isRaspberryPi = board == 'Raspberry Pi';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00D4FF).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFF00D4FF).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: Color(0xFF00D4FF), size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'These credentials are always accessible here.',
                    style: GoogleFonts.rajdhani(
                        color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _sectionLabel('AUTH TOKEN'),
          const SizedBox(height: 8),
          _credBox(authToken, 'Auth Token', const Color(0xFF00D4FF)),
          const SizedBox(height: 16),

          _sectionLabel('DEVICE ID'),
          const SizedBox(height: 8),
          _credBox(deviceId, 'Device ID', const Color(0xFF7C3AED)),
          const SizedBox(height: 24),

          _sectionLabel('SKETCH CODE · $board'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1E2D45)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$board Sketch',
                      style: GoogleFonts.orbitron(
                          fontSize: 9, color: Colors.grey, letterSpacing: 1),
                    ),
                    GestureDetector(
                      onTap: () =>
                          _copyToClipboard(context, sketch, 'Sketch'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D4FF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFF00D4FF).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.copy,
                                color: Color(0xFF00D4FF), size: 11),
                            const SizedBox(width: 5),
                            Text(
                              'COPY',
                              style: GoogleFonts.orbitron(
                                fontSize: 8,
                                color: const Color(0xFF00D4FF),
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  sketch,
                  style: GoogleFonts.sourceCodePro(
                    color: const Color(0xFF00D4FF).withValues(alpha: 0.8),
                    fontSize: 11,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Change PIN button
          GestureDetector(
            onTap: _startChangingPin,
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFFFD740).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.key, color: Color(0xFFFFD740), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'CHANGE PIN',
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

          const SizedBox(height: 12),

          // Lock button
          GestureDetector(
            onTap: () => setState(() {
              _unlocked = false;
              _enteredPin = '';
            }),
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFFF5252).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, color: Color(0xFFFF5252), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'LOCK',
                    style: GoogleFonts.orbitron(
                      color: const Color(0xFFFF5252),
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: GoogleFonts.orbitron(
            fontSize: 9, color: Colors.grey, letterSpacing: 1.5),
      );

  Widget _credBox(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.sourceCodePro(
                  color: color, fontSize: 13, letterSpacing: 1),
            ),
          ),
          GestureDetector(
            onTap: () => _copyToClipboard(context, value, label),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.copy, color: color, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}