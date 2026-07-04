import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'canvas_screen.dart';
import 'create_project_screen.dart';
import 'profile_screen.dart';
import '../services/mqtt_service.dart';
import '../services/device_state.dart';
import 'dart:async';
import 'chat_screen.dart';
import '../widgets/ai_companion.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List devices = [];
  bool loading = true;
  Map? userProfile;
  final MqttService _mqtt = MqttService();
  final Map<String, bool> _liveStatus = {};
  StreamSubscription? _statusSub;

  int _marqueeIndex = 0;
  double _marqueeOpacity = 1.0;
  Timer? _marqueeTimer;
  List<String> _marqueeItems = [];

  Map? _latestAnnouncement;
  bool _hasNewAnnouncement = false;
  int? _lastSeenAnnouncementId;

 @override
void initState() {
  super.initState();
  _loadDevices();
  _loadProfile();
  _initMqtt();
  _loadAnnouncement();
  AiCompanionManager.onDevicesChanged = () => _loadDevices();
  AiCompanionManager.onSchedulesChanged = () => _loadDevices();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    AiCompanionManager.show(context);
  });
}

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    AiCompanionManager.show(context);
  });
}

@override
void dispose() {
  _statusSub?.cancel();
  _marqueeTimer?.cancel();
  AiCompanionManager.hideAll();
  super.dispose();
}

  Future<void> _loadAnnouncement() async {
    final result = await ApiService.getLatestAnnouncement();
    if (result != null) {
      setState(() {
        _latestAnnouncement = result;
        _hasNewAnnouncement = _lastSeenAnnouncementId != result['id'];
      });
    }
  }

  void _startMarquee() {
    final name = userProfile?['name'] ?? userProfile?['email']?.split('@')[0] ?? 'there';
    final community = userProfile?['community_username'] ?? '';

    _marqueeItems = [
      'Welcome back, $name',
      if (community.isNotEmpty) 'Welcome, $community',
      '"The future is smart. You\'re already ahead."',
      '"Xx Smart Systems — where innovation meets control."',
      '"Build something the world has never seen."',
      '"Powered by Xx. Built for the future."',
      '"Your devices. Your rules. Your world."',
      '"Xx Smart Systems — redefining what smart means."',
      '"Dream it. Build it. Control it with Xx."',
      '"The smartest builders choose Xx Smart Systems."',
      '"Smart living starts with a single connection."',
      '"You don\'t just use technology — you command it."',
      '"Xx: where every device obeys."',
      '"Innovation is not a luxury. With Xx, it\'s a lifestyle."',
      '"Control the world around you. That\'s the Xx way."',
    ];

    _marqueeTimer?.cancel();
    _marqueeTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      setState(() => _marqueeOpacity = 0.0);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() {
          _marqueeIndex = (_marqueeIndex + 1) % _marqueeItems.length;
          _marqueeOpacity = 1.0;
        });
      });
    });
  }

  Future<void> _initMqtt() async {
  await _mqtt.connect();
  setState(() {});
    _statusSub = _mqtt.onStatusUpdate.listen((update) {
      setState(() {
        _liveStatus[update['topic']!] = update['status'] == 'online';
      });
    });
  }

  Future<void> _loadDevices() async {
    final result = await ApiService.getDevices();
    setState(() {
      devices = result;
      loading = false;
    });
  }

  Future<void> _loadProfile() async {
    final result = await ApiService.getProfile();
    setState(() => userProfile = result);
    _startMarquee();
  }

  void _openProfile() async {
    final fresh = await ApiService.getProfile();
    setState(() => userProfile = fresh);
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProfileScreen(userProfile: fresh)),
      );
    }
  }

  void _openXxHub() {
    setState(() {
      _hasNewAnnouncement = false;
      _lastSeenAnnouncementId = _latestAnnouncement?['id'];
    });
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2D45),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.campaign, color: Color(0xFF00D4FF), size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Xx Hub',
                    style: GoogleFonts.orbitron(
                      fontSize: 15,
                      color: const Color(0xFF00D4FF),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── ADMIN ANNOUNCEMENT ──
              _hubSection(
                icon: Icons.record_voice_over,
                title: 'From Admin',
                highlighted: true,
                child: Text(
                  _latestAnnouncement?['message'] ?? 'No announcements yet.',
                  style: GoogleFonts.rajdhani(fontSize: 14, color: Colors.white70, height: 1.5),
                ),
              ),
              const SizedBox(height: 16),

              // ── ABOUT THE APP ──
              _hubSection(
                icon: Icons.info_outline,
                title: 'About Xx Smart Systems',
                child: Text(
                  'Xx Smart Systems is a commercial IoT platform designed for developers, makers, and innovators. It allows you to connect, monitor, and control your smart devices from anywhere in the world — in real time. More device types and integrations are coming soon.\n\nThe Community Chat is a built-in space where developers using this platform can connect, share project ideas, ask questions, and inspire each other. You are not alone in what you are building. Your feedback shapes the future of this platform.',
                  style: GoogleFonts.rajdhani(fontSize: 13, color: Colors.white54, height: 1.6),
                ),
              ),
              const SizedBox(height: 16),

              // ── WHY ANONYMOUS ──
              _hubSection(
                icon: Icons.masks_outlined,
                title: 'Why Anonymous?',
                child: Text(
                  'We chose anonymity intentionally. We believe great ideas should stand on their own — not on who you are, where you are from, or what you look like.\n\nIn an anonymous space, developers feel free to ask questions without fear of judgment, share early-stage ideas without criticism, and connect genuinely without social pressure.\n\nYour auto-generated username (e.g. Dev_x7k2) is assigned by the server and is yours alone. You may choose to share your real name or social handles in the chat — but that is always your choice.',
                  style: GoogleFonts.rajdhani(fontSize: 13, color: Colors.white54, height: 1.6),
                ),
              ),
              const SizedBox(height: 16),

              // ── PRIVACY ──
              _hubSection(
                icon: Icons.lock_outline,
                title: 'Your Privacy',
                child: Text(
                  'Your privacy is our first priority.\n\n• We do not collect or sell your personal data.\n• Your real name and email are never visible to other users in the community chat.\n• Only your anonymous username appears publicly.\n• We do not track your behavior, location, or device usage for advertising.\n• You are always in control of what you share.',
                  style: GoogleFonts.rajdhani(fontSize: 13, color: Colors.white54, height: 1.6),
                ),
              ),
              const SizedBox(height: 16),

              // ── DATA SECURITY ──
              _hubSection(
                icon: Icons.shield_outlined,
                title: 'Data Security',
                child: Text(
                  'All messages and account data are stored on our private, self-hosted server — not on third-party cloud platforms.\n\n• Data is stored in a secured, enterprise-grade database on our dedicated infrastructure.\n• All API communication is encrypted via HTTPS (TLS).\n• Authentication uses JWT tokens with expiry — your session is always protected.\n• No message data is stored on your phone. Everything lives on the server and is fetched securely.\n• In the unlikely event of a data incident, affected users will be notified promptly.',
                  style: GoogleFonts.rajdhani(fontSize: 13, color: Colors.white54, height: 1.6),
                ),
              ),
              const SizedBox(height: 16),

              // ── COMMUNITY RULES ──
              _hubSection(
                icon: Icons.gavel_outlined,
                title: 'Community Rules',
                child: Text(
                  'To keep this space safe and productive for all developers:\n\n1. Be respectful. No hate speech, discrimination, or harassment.\n2. Stay on topic. Share ideas, projects, feedback, and tech discussions.\n3. No spam. You are limited to 2 messages per 5 hours.\n4. No illegal content. Any harmful or illegal content will result in a permanent ban.\n5. Sharing social handles (Instagram, GitHub, LinkedIn, TikTok) is allowed and encouraged.\n6. The admin reserves the right to remove any message or user at any time.',
                  style: GoogleFonts.rajdhani(fontSize: 13, color: Colors.white54, height: 1.6),
                ),
              ),
              const SizedBox(height: 16),

              // ── CONTACT DEVELOPER ──
              _hubSection(
                icon: Icons.mail_outline,
                title: 'Contact the Developer',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Have a suggestion, bug report, partnership idea, or just want to say something directly to the team? We read every message.',
                      style: GoogleFonts.rajdhani(fontSize: 13, color: Colors.white54, height: 1.6),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF111827),
                            content: Text(
                              'Email us at: xxautotech@gmail.com',
                              style: GoogleFonts.rajdhani(color: const Color(0xFF00D4FF)),
                            ),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF00D4FF).withValues(alpha: 0.4)),
                          color: const Color(0xFF00D4FF).withValues(alpha: 0.05),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.mail, color: Color(0xFF00D4FF), size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'xxautotech@gmail.com',
                              style: GoogleFonts.rajdhani(
                                fontSize: 13,
                                color: const Color(0xFF00D4FF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── DISMISS ──
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1E2D45)),
                  ),
                  child: Center(
                    child: Text(
                      'Dismiss',
                      style: GoogleFonts.orbitron(fontSize: 12, color: Colors.white38),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hubSection({
    required IconData icon,
    required String title,
    required Widget child,
    bool highlighted = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted
              ? const Color(0xFF00D4FF).withValues(alpha: 0.3)
              : const Color(0xFF1E2D45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF00D4FF), size: 14),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.orbitron(
                  fontSize: 10,
                  color: const Color(0xFF00D4FF),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (name.length >= 2) return name.substring(0, 2).toUpperCase();
    return name.toUpperCase();
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
                      child: CircularProgressIndicator(color: Color(0xFF00D4FF)),
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
    final onlineCount = devices.where((d) {
      final id = d['device_id']?.toString() ?? '';
      return _liveStatus[id] ?? (d['is_online'] == true);
    }).length;
    final initials = _getInitials(userProfile?['name'] ?? userProfile?['email'] ?? 'U');
    final avatarUrl = userProfile?['avatar_url'] ?? '';
    final marqueeText = _marqueeItems.isNotEmpty
        ? _marqueeItems[_marqueeIndex]
        : 'Welcome to Xx Smart Systems';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        border: Border(bottom: BorderSide(color: Color(0xFF1E2D45))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
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
                AnimatedOpacity(
                  opacity: _marqueeOpacity,
                  duration: const Duration(milliseconds: 600),
                  child: Text(
                    marqueeText,
                    style: GoogleFonts.rajdhani(
                      fontSize: 12,
                      color: marqueeText.startsWith('"')
                          ? const Color(0xFF00D4FF).withValues(alpha: 0.7)
                          : Colors.white70,
                      fontStyle: marqueeText.startsWith('"')
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${devices.length} devices · $onlineCount online',
                  style: GoogleFonts.rajdhani(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _XxHubIcon(
            hasNew: _hasNewAnnouncement,
            onTap: _openXxHub,
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _openProfile,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF00D4FF).withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF00D4FF).withValues(alpha: 0.5)),
              ),
              child: ClipOval(
                child: avatarUrl.isNotEmpty
                    ? SvgPicture.network(
                        avatarUrl,
                        width: 38,
                        height: 38,
                        fit: BoxFit.cover,
                      )
                    : Center(
                        child: Text(
                          initials,
                          style: GoogleFonts.orbitron(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF00D4FF),
                          ),
                        ),
                      ),
              ),
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
              color: const Color(0xFF00D4FF).withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF00D4FF).withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.developer_board, color: Color(0xFF00D4FF), size: 40),
          ),
          const SizedBox(height: 20),
          Text('No devices yet', style: GoogleFonts.orbitron(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 8),
          Text('Tap + to create your first device', style: GoogleFonts.rajdhani(color: Colors.grey, fontSize: 14)),
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
          childAspectRatio: 1,
        ),
        itemCount: devices.length,
        itemBuilder: (context, i) => _PowerCard(
          device: devices[i],
          isOnline: _liveStatus[devices[i]['device_id']?.toString() ?? ''] ??
              (devices[i]['is_online'] == true),
          onLongPress: () async {
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => CanvasScreen(device: devices[i])),
  );
  _loadDevices();
},
        ),
      ),
    );
  }

  Widget _buildFab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            if (userProfile == null) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(userProfile: userProfile!),
              ),
            );
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF111827),
              border: Border.all(
                color: const Color(0xFF00D4FF).withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D4FF).withValues(alpha: 0.2),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(Icons.group, color: Color(0xFF00D4FF), size: 26),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
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
                  color: const Color(0xFF00D4FF).withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.black, size: 28),
          ),
        ),
      ],
    );
  }
}

// ── POWER CARD ──
class _PowerCard extends StatefulWidget {
  final Map device;
  final VoidCallback onLongPress;
  final bool isOnline;

  const _PowerCard({
    required this.device,
    required this.onLongPress,
    required this.isOnline,
  });

  @override
  State<_PowerCard> createState() => _PowerCardState();
}

class _PowerCardState extends State<_PowerCard> {
  bool _sending = false;

  String get _topic => widget.device['mqtt_topic'] ?? '';
  bool get _isOn => DevicePowerState.get(_topic);

  @override
  void initState() {
    super.initState();
    if (!DevicePowerState.notifier.value.containsKey(_topic)) {
      DevicePowerState.set(_topic, widget.isOnline);
    }
    DevicePowerState.notifier.addListener(_onStateChange);
  }

  @override
  void dispose() {
    DevicePowerState.notifier.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(_PowerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOnline != widget.isOnline) {
      DevicePowerState.set(_topic, widget.isOnline);
    }
  }

  Future<void> _toggle() async {
    if (_sending) return;
    setState(() => _sending = true);
    final newState = !_isOn;
    try {
      await ApiService.sendCommand(_topic, newState ? 'ON' : 'OFF');
      DevicePowerState.set(_topic, newState);
    } catch (_) {}
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = _isOn ? const Color(0xFF00D4FF) : const Color(0xFF1E2D45);
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent,
                    boxShadow: _isOn
                        ? [BoxShadow(color: const Color(0xFF00D4FF).withValues(alpha: 0.8), blurRadius: 8, spreadRadius: 1)]
                        : null,
                  ),
                ),
                const SizedBox(height: 5),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isOnline ? const Color(0xFF22C55E) : const Color(0xFF1E2D45),
                    boxShadow: widget.isOnline
                        ? [BoxShadow(color: const Color(0xFF22C55E).withValues(alpha: 0.8), blurRadius: 6, spreadRadius: 1)]
                        : null,
                  ),
                ),
              ],
            ),
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
                  style: GoogleFonts.rajdhani(fontSize: 9, color: const Color(0xFF1E3A4A)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── XX HUB ICON ──
class _XxHubIcon extends StatefulWidget {
  final bool hasNew;
  final VoidCallback onTap;
  const _XxHubIcon({required this.hasNew, required this.onTap});

  @override
  State<_XxHubIcon> createState() => _XxHubIconState();
}

class _XxHubIconState extends State<_XxHubIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _glow,
        builder: (_, _) => Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00D4FF).withValues(alpha: 0.1),
                border: Border.all(
                  color: const Color(0xFF00D4FF).withValues(alpha: _glow.value),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D4FF).withValues(alpha: _glow.value * 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.campaign, color: Color(0xFF00D4FF), size: 18),
            ),
            if (widget.hasNew)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.redAccent,
                    border: Border.all(color: const Color(0xFF111827), width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}