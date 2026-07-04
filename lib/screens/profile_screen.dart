import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import '../widgets/ai_companion.dart';

class ProfileScreen extends StatefulWidget {
  final Map? userProfile;
  const ProfileScreen({super.key, this.userProfile});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String appVersion = 'v1.0.0';

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (name.length >= 2) return name.substring(0, 2).toUpperCase();
    return name.toUpperCase();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return 'Unknown';
    }
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.logout, color: Color(0xFFFF5252), size: 20),
            const SizedBox(width: 8),
            Text('SIGN OUT',
                style: GoogleFonts.orbitron(color: Colors.white, fontSize: 12, letterSpacing: 1)),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out of Xx Smart Systems?',
          style: GoogleFonts.rajdhani(color: Colors.grey, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: GoogleFonts.orbitron(color: Colors.grey, fontSize: 10)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              AiCompanionManager.onSignOut(context);
              await Future.delayed(const Duration(seconds: 3));
              await ApiService.logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('SIGN OUT', style: GoogleFonts.orbitron(color: Colors.white, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Color _planColor(String plan) {
    switch (plan) {
      case 'starter': return const Color(0xFF22C55E);
      case 'pro': return const Color(0xFF00D4FF);
      case 'business': return const Color(0xFFFFD740);
      default: return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.userProfile?['name'] ?? '';
    final email = widget.userProfile?['email'] ?? '';
    final plan = (widget.userProfile?['plan'] ?? 'free').toString().toLowerCase();
    final joinedDate = _formatDate(widget.userProfile?['created_at']);
    final initials = _getInitials(name.isNotEmpty ? name : email);
    final avatarUrl = widget.userProfile?['avatar_url'] ?? '';
    final communityUsername = widget.userProfile?['community_username'] ?? '';

    final plans = [
      {
        'id': 'free',
        'name': 'Free',
        'price': '\$0',
        'period': 'forever',
        'color': const Color(0xFF6B7280),
        'features': [
          '1 device',
          '5 widgets per device',
          'Basic MQTT control',
          'Community support',
        ],
      },
      {
        'id': 'starter',
        'name': 'Starter',
        'price': '\$3',
        'period': '/month',
        'color': const Color(0xFF22C55E),
        'features': [
          '5 devices',
          '20 widgets per device',
          'MQTT + REST API',
          'Email support',
          'Device analytics',
        ],
      },
      {
        'id': 'pro',
        'name': 'Pro',
        'price': '\$6',
        'period': '/month',
        'color': const Color(0xFF00D4FF),
        'features': [
          '20 devices',
          'Unlimited widgets',
          'MQTT + REST + WebSocket',
          'Priority support',
          'Advanced analytics',
          'Custom device branding',
        ],
      },
      {
        'id': 'business',
        'name': 'Business',
        'price': '\$19',
        'period': '/month',
        'color': const Color(0xFFFFD740),
        'features': [
          'Unlimited devices',
          'Unlimited widgets',
          'All protocols',
          'Dedicated support',
          'Full analytics + reports',
          'White-label platform',
          'Team access',
        ],
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        leading: const BackButton(color: Color(0xFF00D4FF)),
        title: Text('PROFILE',
            style: GoogleFonts.orbitron(fontSize: 13, color: Colors.white, letterSpacing: 1)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF1E2D45)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // ── Avatar ──
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF00D4FF).withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF00D4FF).withValues(alpha: 0.4), width: 2),
              ),
              child: ClipOval(
                child: avatarUrl.isNotEmpty
                    ? SvgPicture.network(
                        avatarUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        placeholderBuilder: (_) => Center(
                          child: Text(initials,
                              style: GoogleFonts.orbitron(
                                  fontSize: 28, fontWeight: FontWeight.bold,
                                  color: const Color(0xFF00D4FF))),
                        ),
                      )
                    : Center(
                        child: Text(initials,
                            style: GoogleFonts.orbitron(
                                fontSize: 28, fontWeight: FontWeight.bold,
                                color: const Color(0xFF00D4FF))),
                      ),
              ),
            ),
            const SizedBox(height: 14),

            // Name
            if (name.isNotEmpty) ...[
              Text(name,
                  style: GoogleFonts.orbitron(
                      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
            ],

            // Email
            Text(email, style: GoogleFonts.rajdhani(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 6),

            // Community username
            if (communityUsername.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.tag, color: Color(0xFF00D4FF), size: 14),
                  const SizedBox(width: 4),
                  Text(communityUsername,
                      style: GoogleFonts.rajdhani(
                          fontSize: 13, color: const Color(0xFF00D4FF), letterSpacing: 1)),
                ],
              ),
            ],
            const SizedBox(height: 10),

            // Plan badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _planColor(plan).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _planColor(plan).withValues(alpha: 0.5)),
              ),
              child: Text(plan.toUpperCase(),
                  style: GoogleFonts.orbitron(
                      fontSize: 10, color: _planColor(plan), letterSpacing: 1.5)),
            ),
            const SizedBox(height: 24),

            // Joined date
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1E2D45)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, color: Color(0xFF00D4FF), size: 16),
                  const SizedBox(width: 10),
                  Text('Joined Xx Smart Systems',
                      style: GoogleFonts.rajdhani(color: Colors.grey, fontSize: 13)),
                  const Spacer(),
                  Text(joinedDate,
                      style: GoogleFonts.rajdhani(
                          color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Plans label
            Align(
              alignment: Alignment.centerLeft,
              child: Text('PLANS',
                  style: GoogleFonts.orbitron(fontSize: 10, color: Colors.grey, letterSpacing: 2)),
            ),
            const SizedBox(height: 12),

            // Plans list
            ...plans.map((p) {
              final isCurrentPlan = plan == p['id'];
              final planColor = p['color'] as Color;
              final features = p['features'] as List<String>;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isCurrentPlan ? planColor.withValues(alpha: 0.08) : const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isCurrentPlan ? planColor : const Color(0xFF1E2D45),
                    width: isCurrentPlan ? 2 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(p['name'] as String,
                              style: GoogleFonts.orbitron(
                                  fontSize: 14, fontWeight: FontWeight.bold, color: planColor)),
                          const SizedBox(width: 8),
                          if (isCurrentPlan)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: planColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('CURRENT',
                                  style: GoogleFonts.orbitron(
                                      fontSize: 8, color: planColor, letterSpacing: 1)),
                            ),
                          const Spacer(),
                          RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                text: p['price'] as String,
                                style: GoogleFonts.orbitron(
                                    fontSize: 18, fontWeight: FontWeight.bold, color: planColor),
                              ),
                              TextSpan(
                                text: p['period'] as String,
                                style: GoogleFonts.rajdhani(fontSize: 12, color: Colors.grey),
                              ),
                            ]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...features.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 14, color: isCurrentPlan ? planColor : Colors.grey),
                            const SizedBox(width: 8),
                            Text(f,
                                style: GoogleFonts.rajdhani(
                                    fontSize: 13,
                                    color: isCurrentPlan ? Colors.white : Colors.grey)),
                          ],
                        ),
                      )),
                      if (!isCurrentPlan) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          height: 36,
                          decoration: BoxDecoration(
                            color: planColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: planColor.withValues(alpha: 0.3)),
                          ),
                          child: Center(
                            child: Text('COMING SOON',
                                style: GoogleFonts.orbitron(
                                    fontSize: 9,
                                    color: planColor.withValues(alpha: 0.6),
                                    letterSpacing: 1.5)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 8),

            Text('Xx Smart Systems $appVersion',
                style: GoogleFonts.rajdhani(fontSize: 12, color: const Color(0xFF1E2D45))),
            const SizedBox(height: 20),

            // Sign out
            GestureDetector(
              onTap: _confirmSignOut,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5252).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFF5252).withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout, color: Color(0xFFFF5252), size: 18),
                    const SizedBox(width: 8),
                    Text('SIGN OUT',
                        style: GoogleFonts.orbitron(
                            color: const Color(0xFFFF5252), fontSize: 12, letterSpacing: 1.5)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}