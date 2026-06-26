import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'canvas_screen.dart';
import 'create_project_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List devices = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    // ── NO CHANGE: same ApiService.getDevices() call ──
    final result = await ApiService.getDevices();
    setState(() {
      devices = result;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00D4FF),
                      ),
                    )
                  : devices.isEmpty
                      ? _buildEmptyState()
                      : _buildDeviceGrid(),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildHeader() {
    final onlineCount =
        devices.where((d) => d['is_online'] == true).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        border: Border(bottom: BorderSide(color: Color(0xFF1E2D45))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Xx Smart Systems',
                style: GoogleFonts.orbitron(
                  fontSize: 16,
                  color: const Color(0xFF00D4FF),
                  letterSpacing: 1,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${devices.length} devices · $onlineCount online',
                style: GoogleFonts.rajdhani(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () async {
              // ── NO CHANGE: same logout logic ──
              await ApiService.logout();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2234),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1E2D45)),
              ),
              child: const Icon(Icons.logout, color: Colors.grey, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF00D4FF).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF00D4FF).withOpacity(0.3),
              ),
            ),
            child: const Icon(
              Icons.developer_board,
              color: Color(0xFF00D4FF),
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No devices yet',
            style: GoogleFonts.orbitron(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first device',
            style: GoogleFonts.rajdhani(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceGrid() {
    return RefreshIndicator(
      color: const Color(0xFF00D4FF),
      onRefresh: _loadDevices,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1, // perfect square
        ),
        itemCount: devices.length,
        itemBuilder: (context, i) => _PowerCard(
          device: devices[i],
          // tap anywhere → toggle power (handled inside _PowerCard via sendCommand)
          onLongPress: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CanvasScreen(device: devices[i]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFab() {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateProjectScreen()),
        );
        _loadDevices();
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF00D4FF),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00D4FF).withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.black, size: 28),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Square power card — tap = toggle, long press = detail
// ─────────────────────────────────────────────
class _PowerCard extends StatefulWidget {
  final Map device;
  final VoidCallback onLongPress;

  const _PowerCard({required this.device, required this.onLongPress});

  @override
  State<_PowerCard> createState() => _PowerCardState();
}

class _PowerCardState extends State<_PowerCard> {
  bool _isOn = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _isOn = widget.device['is_online'] == true;
  }

  Future<void> _toggle() async {
    if (_sending) return;
    setState(() => _sending = true);
    final newState = !_isOn;
    // ── NO CHANGE: same ApiService.sendCommand() call ──
    try {
      await ApiService.sendCommand(
        widget.device['mqtt_topic'] ?? '',
        newState ? 'ON' : 'OFF',
      );
      setState(() => _isOn = newState);
    } catch (_) {}
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final Color accent =
        _isOn ? const Color(0xFF00D4FF) : const Color(0xFF1E2D45);
    final String name = widget.device['name'] ?? 'Device';

    return GestureDetector(
      onTap: _toggle,
      onLongPress: widget.onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: _isOn ? const Color(0xFF0A1A24) : const Color(0xFF111827),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent, width: 1.5),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // dot indicator top-left
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent,
                boxShadow: _isOn
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00D4FF).withOpacity(0.8),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
            ),

            // bottom: name + long-press hint
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toUpperCase(),
                  style: GoogleFonts.orbitron(
                    fontSize: 10,
                    color: _isOn ? const Color(0xFF00D4FF) : Colors.grey,
                    letterSpacing: 1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'hold for controls',
                  style: GoogleFonts.rajdhani(
                    fontSize: 9,
                    color: const Color(0xFF1E3A4A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}