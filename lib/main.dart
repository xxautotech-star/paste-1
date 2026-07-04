import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Xx Smart Systems',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00D4FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0A0E1A),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _taglineController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _taglineFade;

  final List<String> _taglines = [
    "Your smart world, connected.",
    "The future is in your hands.",
    "Powered by Xx Smart Systems.",
    "One platform. Endless possibilities.",
    "Smart technology, simplified.",
    "Where innovation meets control.",
    "Built for the next generation.",
    "Intelligence, redefined.",
  ];

  int _currentTagline = 0;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );

    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeInOut),
    );

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 800), () {
      _startTaglineRotation();
    });

    _checkLogin();
  }

  void _startTaglineRotation() async {
    while (mounted) {
      await _taglineController.forward();
      await Future.delayed(const Duration(milliseconds: 1500));
      await _taglineController.reverse();
      if (mounted) {
        setState(() {
          _currentTagline = (_currentTagline + 1) % _taglines.length;
        });
      }
    }
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    await Future.delayed(const Duration(seconds: 5));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => token != null
              ? const DashboardScreen()
              : const LoginScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _taglineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Xx Logo — no box, just glowing text
            AnimatedBuilder(
              animation: _logoController,
              builder: (_, _) => Opacity(
                opacity: _logoOpacity.value,
                child: Transform.scale(
                  scale: _logoScale.value,
                  child: Text(
                    'Xx',
                    style: GoogleFonts.orbitron(
                      fontSize: 72,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF00D4FF),
                      shadows: [
                        const Shadow(
                          color: Color(0xFF00D4FF),
                          blurRadius: 30,
                        ),
                        Shadow(
                          color: const Color(0xFF00D4FF).withValues(alpha: 0.5),
                          blurRadius: 60,
                        ),
                        Shadow(
                          color: const Color(0xFF00D4FF).withValues(alpha: 0.3),
                          blurRadius: 100,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // App name
            AnimatedBuilder(
              animation: _logoController,
              builder: (_, _) => Opacity(
                opacity: _logoOpacity.value,
                child: Text(
                  'Xx Smart Systems',
                  style: GoogleFonts.orbitron(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Rotating tagline
            SizedBox(
              height: 24,
              child: FadeTransition(
                opacity: _taglineFade,
                child: Text(
                  _taglines[_currentTagline],
                  style: GoogleFonts.rajdhani(
                    color: const Color(0xFF00D4FF).withValues(alpha: 0.7),
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 48),

            // Loading indicator
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: const Color(0xFF00D4FF).withValues(alpha: 0.6),
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}