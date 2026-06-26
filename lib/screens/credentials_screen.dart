import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
// CredentialsScreen
//
// Now accessible anytime from the detail page.
// Protected by a PIN the user sets per-device
// (or reuses from another device).
//
// NO server calls changed — device data comes
// in exactly as before via the `device` Map.
// ─────────────────────────────────────────────
class CredentialsScreen extends StatefulWidget {
  final Map device;
  const CredentialsScreen({super.key, required this.device});

  @override
  State<CredentialsScreen> createState() => _CredentialsScreenState();
}

class _CredentialsScreenState extends State<CredentialsScreen> {
  // ── PIN state ────────────────────────────────
  // In production: persist PIN per device_id using shared_preferences
  // Key: 'pin_<device_id>'
  String? _savedPin; // null = not set yet
  String _enteredPin = '';
  bool _unlocked = false;
  bool _isSettingPin = false; // true when creating a new PIN
  String _pendingPin = ''; // first entry when setting
  bool _confirmStep = false; // true when confirming new PIN
  String _pinError = '';

  // ── Sketch generation (unchanged logic) ─────
  String _generateSketch() {
    return '''#include <XxSmartSystems.h>

#define AUTH_TOKEN "${widget.device['auth_token'] ?? 'xxSS-xxxx-xxxx'}"
#define DEVICE_ID "${widget.device['device_id'] ?? '000000000000'}"

XxSmartSystems device(AUTH_TOKEN, DEVICE_ID);

void onCommand(String command) {
  // Your code here
}

void setup() {
  device.begin("YOUR_WIFI", "YOUR_PASSWORD");
  device.onCommand(onCommand);
}

void loop() {
  device.run();
}''';
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
            const Icon(Icons.check_circle,
                color: Color(0xFF22C55E), size: 16),
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

  // ── PIN pad logic ────────────────────────────
  void _onPinDigit(String digit) {
    setState(() => _pinError = '');

    if (_isSettingPin) {
      if (!_confirmStep) {
        if (_pendingPin.length < 6) {
          _pendingPin += digit;
          if (_pendingPin.length == 6) {
            // move to confirm step
            setState(() => _confirmStep = true);
          } else {
            setState(() {});
          }
        }
      } else {
        // confirming
        if (_enteredPin.length < 6) {
          _enteredPin += digit;
          setState(() {});
          if (_enteredPin.length == 6) {
            if (_enteredPin == _pendingPin) {
              setState(() {
                _savedPin = _enteredPin;
                _unlocked = true;
                _isSettingPin = false;
              });
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
    } else {
      // unlocking
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
  }

  void _onPinDelete() {
    setState(() {
      _pinError = '';
      if (_isSettingPin && _confirmStep) {
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

  String get _currentPinDisplay {
    if (_isSettingPin && !_confirmStep) return _pendingPin;
    return _enteredPin;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        leading: BackButton(color: const Color(0xFF00D4FF)),
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

  // ── PIN gate ─────────────────────────────────
  Widget _buildPinGate() {
    final String title = _isSettingPin
        ? (_confirmStep ? 'CONFIRM YOUR PIN' : 'SET A PIN')
        : 'ENTER PIN';
    final String subtitle = _isSettingPin
        ? (_confirmStep ? 'Re-enter to confirm' : 'Choose a 6-digit PIN')
        : 'Enter your PIN to view credentials';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // lock icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD740).withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFFD740).withOpacity(0.3),
                ),
              ),
              child: const Icon(Icons.lock_outline,
                  color: Color(0xFFFFD740), size: 30),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.orbitron(
                  color: Colors.white, fontSize: 14, letterSpacing: 1),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style:
                  GoogleFonts.rajdhani(color: Colors.grey, fontSize: 12),
            ),
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
                    color: filled
                        ? const Color(0xFF00D4FF)
                        : Colors.transparent,
                    border: Border.all(
                      color: filled
                          ? const Color(0xFF00D4FF)
                          : const Color(0xFF1E2D45),
                      width: 1.5,
                    ),
                    boxShadow: filled
                        ? [
                            BoxShadow(
                              color:
                                  const Color(0xFF00D4FF).withOpacity(0.5),
                              blurRadius: 6,
                            )
                          ]
                        : null,
                  ),
                );
              }),
            ),

            if (_pinError.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _pinError,
                style: GoogleFonts.rajdhani(
                    color: const Color(0xFFFF5252), fontSize: 12),
              ),
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

            // "Use existing password" option
            if (!_isSettingPin && _savedPin == null) ...[
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
          child: Text(
            digit,
            style: GoogleFonts.orbitron(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
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

  // ── Credentials (revealed after PIN) ─────────
  Widget _buildCredentials() {
    final sketch = _generateSketch();
    final authToken = widget.device['auth_token'] ?? 'xxSS-xxxx-xxxx';
    final deviceId = widget.device['device_id'] ?? '000000000000';
    final board = widget.device['board_type'] ?? 'ESP32';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // info banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00D4FF).withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF00D4FF).withOpacity(0.2),
              ),
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
                          color: const Color(0xFF00D4FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF00D4FF).withOpacity(0.3),
                          ),
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
                    color: const Color(0xFF00D4FF).withOpacity(0.8),
                    fontSize: 11,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          // Lock again
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
                  color: const Color(0xFFFF5252).withOpacity(0.3),
                ),
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
        border: Border.all(color: color.withOpacity(0.3)),
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
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Icon(Icons.copy, color: color, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}